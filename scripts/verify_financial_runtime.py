"""Validate the actual HTTPS/PDF subprocess runtime using a disposable database.

The source database is read-only input for authorized PDF test samples. No
production target is accepted. Reports contain counts and error codes only.
"""
import argparse
from contextlib import closing
import hashlib
import json
import os
from pathlib import Path
import socket
import sqlite3
import ssl
import subprocess
import sys
import tempfile
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "backend"))


def serve(directory, port):
    # Set every persistence path before importing database/app/startup.
    from app.core.config import settings
    settings.DATA_DIR = directory
    settings.DATABASE_PATH = directory / "isolated.db"
    settings.DATABASE_URL = "sqlite:///" + settings.DATABASE_PATH.as_posix()
    settings.BACKUP_DIR = directory / "backups"
    settings.PORT = port
    import uvicorn
    uvicorn.run("app.main:app", host="127.0.0.1", port=port,
                ssl_keyfile=str(settings.CERTS_DIR / "server.key"),
                ssl_certfile=str(settings.CERTS_DIR / "server.crt"),
                access_log=False, log_level="warning")


def run(source, report_path):
    import httpx
    from verify_financial_csv import migrate, book_snapshot
    from app.core.security import hash_token
    from app.models.auth import PairedDevice
    from app.models.financial import FinancialAccount, CashFlowEntry
    from sqlalchemy import create_engine
    from sqlalchemy.orm import Session

    if not source.is_file() or report_path.resolve() == source.resolve():
        raise ValueError("INPUT_PATH")
    with closing(sqlite3.connect(source.resolve().as_uri() + "?mode=ro", uri=True)) as original:
        # Only PDF bytes/type are copied; never copy business data or credentials.
        samples = original.execute("""SELECT d.content,
            (SELECT s.source_type FROM financial_import_previews p
             JOIN financial_sources s ON s.id=p.source_id
             WHERE p.document_id=d.id ORDER BY p.created_at LIMIT 1)
            FROM financial_documents d WHERE d.media_type='application/pdf'
            ORDER BY d.created_at,d.id""").fetchall()
    if not 0 < len(samples) <= 20:
        raise ValueError("SAMPLE_COUNT")
    original_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    result = {"status": "PASS", "transport": "HTTPS, trusted local certificate",
              "runtime": "Python with separate PDF worker (not frozen)", "samples": []}
    with tempfile.TemporaryDirectory(prefix="zm-runtime-") as temporary:
        directory = Path(temporary)
        database = directory / "isolated.db"
        migrate(database)
        token, actor, account = uuid.uuid4().hex, str(uuid.uuid4()), str(uuid.uuid4())
        engine = create_engine("sqlite:///" + database.as_posix())
        entries = {kind: str(uuid.uuid4()) for kind in ("CREDIT", "DEBIT")}
        try:
            with Session(engine) as db:
                db.add(PairedDevice(id=actor, device_name="Runtime validation", device_public_id=uuid.uuid4().hex,
                                    token_hash=hash_token(token)))
                db.add(FinancialAccount(id=account, name="Isolated runtime account", account_type="BANK",
                                        initial_balance_cents=0, current_balance_cents=0))
                db.flush()
                for kind, entry_id in entries.items():
                    db.add(CashFlowEntry(id=entry_id, account_id=account, entry_type=kind, amount_cents=1,
                        category="OUTROS", nature="BUSINESS", description="Synthetic runtime fixture",
                        source_type="MANUAL", payment_method="OTHER"))
                db.commit()
        finally:
            engine.dispose()
        before = book_snapshot(database)
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            port = listener.getsockname()[1]
        env = os.environ.copy()
        env.pop("PDF_WORKER_PASSWORD", None)
        with (directory / "server.log").open("wb") as log:
            process = subprocess.Popen([sys.executable, str(Path(__file__).resolve()),
                "--serve", str(directory), "--port", str(port)], cwd=ROOT, env=env,
                stdout=log, stderr=log,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
            try:
                context = ssl.create_default_context(cafile=str(ROOT / "backend/certs/server.crt"))
                # Trust the exact local certificate; its hostname varies by installation.
                context.check_hostname = False
                with httpx.Client(base_url=f"https://127.0.0.1:{port}", verify=context,
                                  trust_env=False, timeout=35) as client:
                    for attempt in range(100):
                        if process.poll() is not None:
                            raise ValueError("SERVER_EXIT")
                        try:
                            if client.get("/api/v1/health").status_code == 200:
                                break
                        except httpx.TransportError:
                            pass
                        time.sleep(.1)
                    else:
                        raise ValueError("SERVER_START_TIMEOUT")

                    def request(method, route, payload=None, raw=None, expected=(200, 201), key=None,
                                media_type="application/pdf"):
                        headers = {"Authorization": "Bearer " + token,
                                   "X-Idempotency-Key": key or str(uuid.uuid4())}
                        if raw is not None:
                            headers["Content-Type"] = media_type
                        response = client.request(method, "/api/v1/financial-imports" + route,
                            json=payload, content=raw, headers=headers,
                            params={"filename": "sample.pdf" if media_type == "application/pdf" else "synthetic.csv"} if raw is not None else None)
                        if response.status_code not in expected:
                            detail = response.json().get("detail", {})
                            code = detail.get("error_code", "UNKNOWN") if isinstance(detail, dict) else "UNKNOWN"
                            raise ValueError("HTTP_" + str(response.status_code) + "_" + code)
                        return response

                    readers = request("GET", "/readers").json()
                    assert next(r for r in readers if r["id"] == "pdf_auto")["version"] == "2"
                    bank_source_id = None
                    for index, (raw, source_type) in enumerate(samples, 1):
                        source_type = source_type or "CREDIT_CARD"
                        source_data = {"source_type": source_type, "holder_type": "PJ", "currency": "BRL",
                            "name": "Isolated source", "institution": "Test sample"}
                        if source_type == "BANK_ACCOUNT":
                            source_data["financial_account_id"] = account
                        if source_type == "BANK_ACCOUNT" and bank_source_id:
                            source_id = bank_source_id
                        else:
                            source_id = request("POST", "/sources", payload=source_data).json()["id"]
                            if source_type == "BANK_ACCOUNT":
                                bank_source_id = source_id
                        doc = request("POST", "/documents", raw=raw).json()["document"]
                        assert request("GET", f'/documents/{doc["id"]}/content').content == raw
                        payload = {"source_id": source_id, "currency": "BRL", "reader_id": "pdf_auto",
                                   "expected_reader_version": "2"}
                        route = f'/documents/{doc["id"]}/previews'
                        preview = request("POST", route, payload=payload).json()["preview"]
                        assert request("POST", route, payload=payload).json()["preview"]["id"] == preview["id"]
                        errors = request("GET", f'/previews/{preview["id"]}/errors').json()
                        codes = sorted({error["code"] for error in errors})
                        assert not any(code.startswith("PDF_PROCESSING_") or code == "PDF_RUNTIME_UNAVAILABLE" for code in codes)
                        confirm = {"expected_source_id": source_id,
                            "expected_result_sha256": preview["result_sha256"],
                            "statement_type": "BANK_STATEMENT" if source_type == "BANK_ACCOUNT" else "CARD_BILL"}
                        confirmation = "BLOCKED"
                        if preview["status"] == "READY":
                            statement = request("POST", f'/previews/{preview["id"]}/confirm', payload=confirm).json()["statement"]
                            assert statement["pending_count"] == preview["items_count"]
                            occurrences = request("GET", f'/statements/{statement["id"]}/items?limit=500').json()
                            first = occurrences[0]
                            # Exercise the same explicit decision endpoint used by Flutter.
                            review = {"action": "NEW", "reason": "Isolated runtime verification"}
                            key = str(uuid.uuid4())
                            reviewed = request("POST", f'/items/{first["id"]}/review', payload=review, key=key).json()
                            assert request("POST", f'/items/{first["id"]}/review', payload=review, key=key).json() == reviewed
                            transaction = reviewed["transaction"]
                            direction = "CREDIT" if transaction["amount_cents"] > 0 else "DEBIT"
                            allocation = {"transaction_id": transaction["id"],
                                "cash_flow_entry_id": entries[direction], "amount_cents": 1,
                                "reason": "Isolated explicit partial reconciliation"}
                            key = str(uuid.uuid4())
                            reconciliation = request("POST", "/reconciliations", payload=allocation, key=key).json()
                            assert request("POST", "/reconciliations", payload=allocation, key=key).json() == reconciliation
                            request("POST", "/reconciliations", payload=allocation, expected=(409,))
                            wrong = "DEBIT" if direction == "CREDIT" else "CREDIT"
                            request("POST", "/reconciliations", payload={**allocation,
                                "cash_flow_entry_id": entries[wrong]}, expected=(409,))
                            request("POST", f'/reconciliations/{reconciliation["reconciliation"]["id"]}/void',
                                payload={"reason": "Isolated correspondence correction"})
                            request("POST", f'/statements/{statement["id"]}/post-to-treasury', payload={}, expected=(409,))
                            confirmation = "EVIDENCE_REVIEW_PARTIAL_RECONCILIATION_VOID_NO_CASH"
                        else:
                            request("POST", f'/previews/{preview["id"]}/confirm', payload=confirm, expected=(409,))
                        result["samples"].append({"alias": f"pdf_{index}", "items": preview["items_count"],
                            "adapter": preview.get("detected_reader"), "errors": codes,
                            "confirmation": confirmation, "original_and_preview_replay": True})
                    # Inspect unresolved allocations through the actual HTTPS route,
                    # using a separate, explicitly synthetic statement.
                    card = request("POST", "/sources", payload={"source_type": "CREDIT_CARD",
                        "holder_type": "PJ", "currency": "BRL", "name": "Synthetic allocation test",
                        "institution": "Synthetic fixture"}).json()
                    doc = request("POST", "/documents", raw=b"date,amount\n2026-10-01,100.00\n2026-10-02,-25.00",
                                  media_type="text/csv").json()["document"]
                    statement = request("POST", "/statements", payload={"source_id": card["id"],
                        "document_id": doc["id"], "statement_type": "CARD_BILL", "due_on": "2026-10-20",
                        "total_amount_cents": 7500, "items": [{"position": number, "data": {
                            "transaction_date": "2026-10-01", "amount_cents": amount,
                            "description": "Synthetic allocation fixture"}} for number, amount in enumerate([10000, -2500], 1)]}).json()["statement"]
                    rows = request("GET", f'/statements/{statement["id"]}/items').json()
                    review = request("POST", f'/statements/{statement["id"]}/semantic-reviews', payload={
                        "expected_revision": 0, "items": [{"item_id": row["id"], "semantic_category": category}
                            for row, category in zip(rows, ["PURCHASE_BUSINESS", "REFUND_CREDIT"])]}).json()
                    allocation = request("GET", f'/statements/{statement["id"]}/allocation-requirements?expected_review_id={review["id"]}').json()
                    assert not allocation["authorizes_generation"]
                    assert allocation["requirements"][0]["code"] == "CREDIT_TARGET_REQUIRED"
                    request("POST", f'/statements/{statement["id"]}/generate-obligations', payload={}, expected=(409,))
                    assert book_snapshot(database) == before
                    result["checks"] = {"books_unchanged": True, "explicit_review_replay": True,
                        "partial_reconciliation_replay": True, "excess_and_wrong_direction_blocked": True,
                        "reconciliation_void_without_cash_reversal": True, "invalid_confirmation_blocked": True,
                        "allocation_requirements_https": True, "unallocated_credit_generation_blocked": True,
                        "reader_version": "2", "startup_isolated": True}
            finally:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=5)
        with closing(sqlite3.connect(database)) as db:
            try:
                assert db.execute("PRAGMA integrity_check").fetchone() == ("ok",)
                assert not db.execute("PRAGMA foreign_key_check").fetchall()
            except sqlite3.OperationalError as exc:
                raise ValueError("ISOLATED_INTEGRITY_" + str(exc)) from None
    assert hashlib.sha256(source.read_bytes()).hexdigest() == original_hash
    result["checks"]["source_file_unchanged"] = True
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-db", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--serve", type=Path, help=argparse.SUPPRESS)
    parser.add_argument("--port", type=int, help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.serve:
        serve(args.serve.resolve(), args.port)
        return 0
    if not args.source_db or not args.report:
        parser.error("--source-db and --report are required")
    try:
        result = run(args.source_db, args.report)
    except Exception as exc:
        # Never print HTTP bodies, transaction text, paths or tokens.
        import traceback
        frames = traceback.extract_tb(exc.__traceback__)
        print(json.dumps({"status": "FAIL", "code": str(exc) if isinstance(exc, ValueError) else type(exc).__name__,
                          "location": [{"module": Path(f.filename).name, "line": f.lineno} for f in frames]}))
        return 1
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
