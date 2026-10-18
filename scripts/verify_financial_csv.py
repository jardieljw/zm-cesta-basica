"""Offline API homologation of original CSVs in a disposable SQLite database.

Inputs and private manifest stay outside Git. Reports contain aliases, counts
and boolean checks only. This command has no option to select a company DB.
"""
import argparse
import csv
import datetime
import io
import json
import re
import sqlite3
import sys
import tempfile
import uuid
from collections import Counter
from contextlib import closing
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "backend"))

from alembic import command
from alembic.config import Config
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.api.v1.financial_imports import router
from app.core.backup import create_backup, restore_backup
from app.core.database import create_db_engine, get_db
from app.core.financial_payloads import FinancialPayloadLimitMiddleware
from app.core.security import generate_device_token, hash_token
from app.models import PairedDevice
from app.models.financial import FinancialAccount
from app.schemas.financial_readers import CSVOptions
from app.services.financial_readers import READERS

PREFIX = "/api/v1/financial-imports"
BOOKS = ("financial_accounts", "cash_flow_entries", "accounts_payable", "payable_payments",
         "sales_receivables", "receivable_payments", "inventory_movements")


class CheckFailed(Exception):
    def __init__(self, code):
        self.code = code


def check(condition, code):
    if not condition:
        raise CheckFailed(code)


def source_rows(raw, options):
    """Separate field-by-field oracle; never calls the production CSV parser.

    This still uses Python's CSV tokenizer, so matching it is not independent
    proof of tokenization. Reported PDF controls supply another comparison.
    """
    rows = list(csv.DictReader(io.StringIO(raw.decode(options.encoding), newline=""), delimiter=options.delimiter))
    fields = options.columns
    fmt = {"DD/MM/YYYY": "%d/%m/%Y", "YYYY-MM-DD": "%Y-%m-%d", "MM/DD/YYYY": "%m/%d/%Y"}[options.date_format]
    result = []
    for row in rows:
        value = row[fields.amount].strip()
        if options.amount_sign_spacing == "OPTIONAL_SINGLE_SPACE" and value[:1] in ("-", "+"):
            sign, unsigned = value[0], value[1:]
            if unsigned.startswith(" "):
                unsigned = unsigned[1:]
            check(bool(unsigned) and not unsigned[0].isspace(), "SOURCE_SIGN_SPACING")
            value = sign + unsigned
        if options.thousands_separator:
            value = value.replace(options.thousands_separator, "")
        exact = Decimal(value.replace(options.decimal_separator, ".")) * 100
        check(exact == exact.to_integral_value(), "SOURCE_PRECISION")
        cents = int(exact) * (-1 if options.amount_convention == "CHARGES_NEGATIVE" else 1)
        external_id = (row[fields.external_id].strip() or None) if fields.external_id else None
        normalized = {"transaction_date": datetime.datetime.strptime(row[fields.transaction_date].strip(), fmt).date().isoformat(),
                       "amount_cents": cents, "description": row[fields.description].strip(),
                       "external_id": external_id}
        for field, column in fields.model_dump().items():
            if field in {"transaction_date", "amount", "description", "external_id"} or column is None:
                continue
            value = row[column].strip()
            if not value:
                normalized[field] = None
            elif field in {"purchase_date", "booking_date"}:
                normalized[field] = datetime.datetime.strptime(value, fmt).date().isoformat()
            elif field in {"installment_number", "total_installments"}:
                normalized[field] = int(value)
            else:
                normalized[field] = value
        result.append(normalized)
    return result


def book_snapshot(path):
    with closing(sqlite3.connect(path)) as db:
        return {name: db.execute(f'SELECT * FROM "{name}" ORDER BY id').fetchall() for name in BOOKS}


def migrate(path):
    cfg = Config(str(ROOT / "backend" / "alembic.ini"))
    cfg.set_main_option("script_location", str(ROOT / "backend" / "alembic"))
    cfg.set_main_option("sqlalchemy.url", "sqlite:///" + path.as_posix())
    command.upgrade(cfg, "head")


def run(manifest):
    samples = manifest["samples"]
    check(isinstance(samples, list) and 0 < len(samples) <= 20, "SAMPLE_COUNT")
    labels = [sample["label"] for sample in samples]
    check(all(isinstance(label, str) and re.fullmatch(r"[a-z][a-z0-9_]{0,39}", label) for label in labels)
          and len(set(labels)) == len(labels), "SAMPLE_ALIASES")
    # The script creates this exact directory and removes only its own temporary
    # child. It never accepts a database path, nor discovers real banking files.
    with tempfile.TemporaryDirectory(prefix="zm-financial-check-") as temporary:
        directory = Path(temporary).resolve()
        check(directory.parent == Path(tempfile.gettempdir()).resolve()
              and directory.name.startswith("zm-financial-check-"), "TEMP_DIRECTORY")
        path = directory / "isolated.db"
        migrate(path)
        engine = create_db_engine("sqlite:///" + path.as_posix())
        app = FastAPI()
        app.include_router(router, prefix="/api/v1")
        app.add_middleware(FinancialPayloadLimitMiddleware, prefix=PREFIX)

        def isolated_session():
            with Session(engine) as session:
                yield session

        app.dependency_overrides[get_db] = isolated_session
        token = generate_device_token()
        device_id = str(uuid.uuid4())
        groups = {}
        report = {"status": "PASS", "samples": [], "checks": {}}
        try:
            with Session(engine) as db:
                db.add(PairedDevice(id=device_id, device_name="Homologacao isolada", device_public_id=str(uuid.uuid4()), token_hash=hash_token(token)))
                for sample in samples:
                    group = sample["source_group"]
                    identity = (sample["source_type"], sample["holder_type"], sample["currency"])
                    if group in groups:
                        check(groups[group]["identity"] == identity, "SOURCE_GROUP_MISMATCH")
                        continue
                    account_id = str(uuid.uuid4()) if identity[0] == "BANK_ACCOUNT" else None
                    if account_id:
                        db.add(FinancialAccount(id=account_id, name="Banco sintetico " + str(len(groups)), account_type="BANK",
                            initial_balance_cents=0, current_balance_cents=0))
                    groups[group] = {"identity": identity, "account_id": account_id}
                db.commit()
            before = book_snapshot(path)
            with TestClient(app) as client:
                headers = {"Authorization": "Bearer " + token}

                def request(method, route, *, payload=None, raw=None, key=None, filename=None):
                    request_headers = {**headers, "X-Idempotency-Key": key or str(uuid.uuid4())}
                    if raw is not None:
                        request_headers["Content-Type"] = "text/csv"
                    response = client.request(method, PREFIX + route, json=payload, content=raw,
                        params={"filename": filename} if filename else None, headers=request_headers)
                    check(response.status_code in (200, 201), "API_" + str(response.status_code))
                    return response.content if route.endswith("/content") else response.json()

                def pages(route):
                    rows, offset = [], 0
                    while True:
                        page = request("GET", route + f"?limit=500&offset={offset}")
                        rows.extend(page)
                        if len(page) < 500:
                            return rows
                        offset += 500

                for group in groups.values():
                    kind, holder, currency = group["identity"]
                    source = request("POST", "/sources", payload={"source_type": kind, "holder_type": holder,
                        "currency": currency, "financial_account_id": group["account_id"], "name": "Origem de homologacao",
                        "institution": "Instituicao de homologacao"})
                    group["source_id"], group["seen"] = source["id"], set()
                expected_transactions = 0
                processed_statements = set()
                for sample in samples:
                    label, group = sample["label"], groups[sample["source_group"]]
                    sample_path = Path(sample["path"])
                    check(sample_path.stat().st_size <= 10 * 1024 * 1024, "SOURCE_SIZE")
                    with sample_path.open("rb") as stream:
                        raw = stream.read(10 * 1024 * 1024 + 1)
                    check(0 < len(raw) <= 10 * 1024 * 1024, "SOURCE_SIZE")
                    reader = READERS[sample["reader_id"]]
                    options = reader.options or CSVOptions.model_validate(sample["options"])
                    oracle = source_rows(raw, options)
                    check(oracle, "NO_SOURCE_ROWS")
                    document = request("POST", "/documents", raw=raw, filename="sample.csv")["document"]
                    reused = request("POST", "/documents", raw=raw, filename="same-original.csv")
                    check(reused["duplicate"] and reused["document"]["id"] == document["id"], "DOCUMENT_REPLAY")
                    check(request("GET", "/documents/" + document["id"] + "/content") == raw, "ORIGINAL_BYTES")
                    preview_request = {"source_id": group["source_id"], "currency": sample["currency"], "reader_id": reader.id}
                    if reader.options is None:
                        preview_request["options"] = sample["options"]
                    route = "/documents/" + document["id"] + "/previews"
                    preview = request("POST", route, payload=preview_request)["preview"]
                    check(preview["status"] == "READY" and preview["complete"], "PREVIEW_INVALID")
                    check(request("POST", route, payload=preview_request)["preview"]["id"] == preview["id"], "PREVIEW_REPLAY")
                    parsed = pages("/previews/" + preview["id"] + "/items")
                    check(len(parsed) == len(oracle), "ROW_COUNT")
                    for actual, expected in zip(parsed, oracle):
                        check(all(actual["data"][field] == value for field, value in expected.items()), "SOURCE_FIELDS")
                        if not options.columns.transaction_time:
                            check(actual["data"]["transaction_time"] is None and actual["data"]["utc_offset_minutes"] is None, "UNKNOWN_TIME")
                    header = sample.get("statement", {"statement_type": "BANK_STATEMENT"})
                    confirmation = {"expected_source_id": group["source_id"], "expected_result_sha256": preview["result_sha256"], **header}
                    staged = request("POST", "/previews/" + preview["id"] + "/confirm", payload=confirmation)["statement"]
                    check(all(c["matches"] for c in staged["checks"]), "REPORTED_CONTROLS")
                    check(request("POST", "/previews/" + preview["id"] + "/confirm", payload=confirmation)["statement"]["id"] == staged["id"], "CONFIRM_REPLAY")
                    occurrences = pages("/statements/" + staged["id"] + "/items")
                    linked, new, reused_occurrences = 0, 0, 0
                    for occurrence, expected in zip(occurrences, oracle):
                        if staged["id"] in processed_statements:
                            check(occurrence["review_status"] in {"NEW", "LINKED"}, "REPLAYED_REVIEW")
                            reused_occurrences += 1
                            continue
                        identity = (options.external_id_namespace, expected["external_id"]) if expected["external_id"] else None
                        known = identity is not None and identity in group["seen"]
                        reviewed = request("POST", "/items/" + occurrence["id"] + "/review", payload={
                            "action": "NEW", "reason": "Homologacao isolada autorizada, sem efeito financeiro"})
                        check(reviewed["item"]["review_status"] == ("LINKED" if known else "NEW"), "IDENTITY_REIMPORT")
                        check(not reviewed["affects_ledger"], "LEDGER_FLAG")
                        linked += int(known)
                        new += int(not known)
                        if identity is not None:
                            group["seen"].add(identity)
                    expected_transactions += new
                    processed_statements.add(staged["id"])
                    signatures = Counter((r["transaction_date"], r["amount_cents"], r["description"]) for r in oracle)
                    declared_controls = sum(c["code"] in {"IMPORTED_INFLOWS_TOTAL", "IMPORTED_OUTFLOWS_TOTAL", "REPORTED_BALANCE_EQUATION"} for c in staged["checks"])
                    report["samples"].append({"alias": label, "rows": len(oracle), "new_events": new,
                        "linked_events": linked, "similar_operation_groups": sum(v > 1 for v in signatures.values()),
                        "reused_occurrences": reused_occurrences, "reported_control_checks": declared_controls,
                        "source_fields_match": True, "original_bytes_match": True})
                transactions = pages("/transactions")
                check(len(transactions) == expected_transactions, "EVENT_COUNT")
                check(book_snapshot(path) == before, "BOOKS_CHANGED")
                report["checks"].update(events_count=len(transactions), source_groups=len(groups), books_unchanged=True,
                    original_replays=True, preview_replays=True, confirmation_replays=True)
            backup, restored = directory / "backup.db", directory / "restored.db"
            check(create_backup(source_path=path, destination_path=backup)["integrity_ok"], "BACKUP")
            restore_backup(backup, target_path=restored)
            with closing(sqlite3.connect(path)) as original, closing(sqlite3.connect(restored)) as copy:
                for table in ("financial_documents", "financial_import_previews", "financial_statements", "financial_statement_items",
                              "financial_transactions", "financial_transaction_identities", "financial_import_audit"):
                    check(original.execute(f'SELECT * FROM "{table}" ORDER BY id').fetchall() ==
                          copy.execute(f'SELECT * FROM "{table}" ORDER BY id').fetchall(), "RESTORED_EVIDENCE")
                check(copy.execute("PRAGMA integrity_check").fetchone() == ("ok",), "INTEGRITY")
                check(copy.execute("PRAGMA foreign_key_check").fetchall() == [], "FOREIGN_KEYS")
                report["schema_revision"] = original.execute("SELECT version_num FROM alembic_version").fetchone()[0]
            report["checks"].update(backup_restored=True, evidence_preserved=True, integrity_ok=True, foreign_keys_ok=True)
            report["timestamp_utc"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
            return report
        finally:
            app.dependency_overrides.clear()
            engine.dispose()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    report_path = args.report.resolve()
    try:
        manifest = json.loads(args.manifest.read_text(encoding="utf-8-sig"))
        inputs = {Path(s["path"]).resolve() for s in manifest["samples"]} | {args.manifest.resolve()}
        check(report_path not in inputs and report_path.suffix == ".json", "REPORT_TARGET")
        report = run(manifest)
    except CheckFailed as error:
        if error.code == "REPORT_TARGET":
            print("FAIL: REPORT_TARGET")
            return 1
        report = {"status": "FAIL", "error_code": error.code}
    except Exception:
        # No traceback, HTTP body, manifest, filenames or bank values in logs.
        report = {"status": "FAIL", "error_code": "HOMOLOGATION_INPUT_OR_EXECUTION_ERROR"}
    if report_path == args.manifest.resolve() or report_path.suffix != ".json":
        print("FAIL: REPORT_TARGET")
        return 1
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(report["status"] + (": " + report["error_code"] if "error_code" in report else ": isolated financial checks completed"))
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
