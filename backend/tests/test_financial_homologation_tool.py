"""The manual verification tool must be isolated and must not leak source data."""
import importlib.util
import json
from pathlib import Path

import pytest
from sqlalchemy import event, Engine


def tool():
    path = Path(__file__).resolve().parents[2] / "scripts" / "verify_financial_csv.py"
    spec = importlib.util.spec_from_file_location("financial_homologation_tool", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def manifest(tmp_path):
    first = tmp_path / "private-first.csv"
    second = tmp_path / "private-second.csv"
    first.write_text("Data;Valor;Descricao;Id\n10/07/2025;-12,34;CONFIDENTIAL_NAME;secret-reference\n", encoding="utf-8")
    second.write_text(first.read_text(encoding="utf-8") + "11/07/2025;20,00;CONFIDENTIAL_NAME;another-reference\n", encoding="utf-8")
    common = {"source_group": "bank_a", "source_type": "BANK_ACCOUNT", "holder_type": "PJ", "currency": "BRL",
        "reader_id": "generic_csv", "options": {"columns": {"transaction_date": "Data", "amount": "Valor", "description": "Descricao", "external_id": "Id"},
        "delimiter": ";", "date_format": "DD/MM/YYYY", "decimal_separator": ",", "amount_convention": "CREDITS_POSITIVE", "external_id_namespace": "bank:csv"}}
    return {"samples": [{**common, "label": "sample_a", "path": str(first), "statement": {"statement_type": "BANK_STATEMENT",
        "opening_balance_cents": 1234, "closing_balance_cents": 0, "total_inflows_cents": 0, "total_outflows_cents": 1234}},
        {**common, "label": "sample_b", "path": str(second)}]}


def test_real_file_tool_exercises_overlap_replays_backup_and_only_connects_to_owned_temp_db(tmp_path):
    module = tool()
    connections = []
    def guard(connection, cursor, statement, parameters, context, executemany):
        database = Path(connection.engine.url.database).resolve()
        assert database.name == "isolated.db" and database.parent.name.startswith("zm-financial-check-")
        connections.append(database)
    event.listen(Engine, "before_cursor_execute", guard)
    try:
        report = module.run(manifest(tmp_path))
    finally:
        event.remove(Engine, "before_cursor_execute", guard)
    assert report["status"] == "PASS" and report["checks"]["events_count"] == 2
    assert report["samples"][1]["linked_events"] == 1
    assert report["samples"][0]["reported_control_checks"] == 3
    assert report["checks"]["books_unchanged"] and report["checks"]["backup_restored"]
    serialized = json.dumps(report)
    assert "CONFIDENTIAL_NAME" not in serialized and "secret-reference" not in serialized and str(tmp_path) not in serialized
    assert "_cents" not in serialized and "20,00" not in serialized
    assert connections and all(not p.parent.exists() for p in connections)


def test_tool_reports_blocked_import_without_echoing_private_rows(tmp_path):
    module = tool()
    data = manifest(tmp_path)
    path = Path(data["samples"][0]["path"])
    path.write_text("Data;Valor;Descricao;Id\n10/07/2025;0,00;CONFIDENTIAL_NAME;secret-reference\n", encoding="utf-8")
    with pytest.raises(module.CheckFailed) as error:
        module.run(data)
    assert error.value.code == "PREVIEW_INVALID"


def test_same_original_in_two_manifest_entries_reuses_completed_occurrences(tmp_path):
    module = tool()
    data = manifest(tmp_path)
    data["samples"] = [data["samples"][0], {**data["samples"][0], "label": "same_document_again"}]
    report = module.run(data)
    assert report["checks"]["events_count"] == 1
    assert report["samples"][1]["new_events"] == 0
    assert report["samples"][1]["reused_occurrences"] == 1


def test_report_cannot_overwrite_an_input_even_if_its_extension_is_json(tmp_path, monkeypatch, capsys):
    module = tool()
    data = manifest(tmp_path)
    source = tmp_path / "source.json"
    original = b"financial original must stay intact"
    source.write_bytes(original)
    data["samples"][0]["path"] = str(source)
    private = tmp_path / "manifest.json"
    private.write_text(json.dumps(data), encoding="utf-8")
    monkeypatch.setattr("sys.argv", ["verify_financial_csv.py", "--manifest", str(private), "--report", str(source)])
    assert module.main() == 1
    assert source.read_bytes() == original
    assert "REPORT_TARGET" in capsys.readouterr().out


def test_tool_checks_synthetic_card_sign_spacing_without_creating_commercial_debts(tmp_path):
    module = tool()
    path = tmp_path / "synthetic-card.csv"
    path.write_text('Data;Valor;Descricao\n10/07/2025;100,00;Compra\n11/07/2025;- 20,00;Credito\n', encoding="utf-8")
    data = {"samples": [{"label": "synthetic_card", "path": str(path), "source_group": "card_a",
        "source_type": "CREDIT_CARD", "holder_type": "PF", "currency": "BRL", "reader_id": "generic_csv",
        "options": {"columns": {"transaction_date": "Data", "amount": "Valor", "description": "Descricao"},
            "delimiter": ";", "date_format": "DD/MM/YYYY", "decimal_separator": ",",
            "amount_convention": "CHARGES_POSITIVE", "amount_sign_spacing": "OPTIONAL_SINGLE_SPACE"},
        "statement": {"statement_type": "CARD_BILL", "due_on": "2025-08-10", "total_amount_cents": 9000}}]}
    report = module.run(data)
    assert report["status"] == "PASS" and report["checks"]["events_count"] == 2
    assert report["checks"]["books_unchanged"] and report["checks"]["backup_restored"]
    assert module.source_rows(path.read_bytes(), module.CSVOptions.model_validate(data["samples"][0]["options"]))[1]["amount_cents"] == -2000
