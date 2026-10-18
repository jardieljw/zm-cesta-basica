"""The PDF command owns its temporary DB and publishes sanitized results only."""
import hashlib
import importlib.util
import json
from pathlib import Path

import pytest
from sqlalchemy import Engine, event

from test_financial_pdf import card_pdf


def tool(monkeypatch):
    directory = Path(__file__).resolve().parents[2] / 'scripts'
    monkeypatch.syspath_prepend(str(directory))
    spec = importlib.util.spec_from_file_location('financial_pdf_tool', directory / 'verify_financial_pdf.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def manifest(tmp_path):
    samples = []
    for label, mismatch in [('sample_a', False), ('sample_b', True)]:
        content = card_pdf(mismatch=mismatch)
        path = tmp_path / (label + '-CONFIDENTIAL.pdf')
        path.write_bytes(content)
        samples.append({'label': label, 'path': str(path), 'sha256': hashlib.sha256(content).hexdigest(),
            'source_type': 'CREDIT_CARD', 'holder_type': 'PF', 'expected_reader': 'nubank_card_pdf_v1',
            'expected_status': 'INVALID' if mismatch else 'READY', 'pages_count': 1, 'items_count': 2,
            'signed_values_cents': [1001 if mismatch else 1000, -500],
            'header': {'due_on': '2025-08-10', 'total_amount_cents': 500},
            'errors': ['PDF_SUMMARY_DETAIL_MISMATCH'] if mismatch else []})
    return {'samples': samples}


def test_pdf_tool_only_uses_disposable_db_and_preserves_failure_original_backup(tmp_path, monkeypatch):
    module = tool(monkeypatch)
    connections = []
    def guard(connection, *args):
        path = Path(connection.engine.url.database).resolve()
        assert path.name == 'isolated.db' and path.parent.name.startswith('zm-pdf-check-')
        connections.append(path)
    event.listen(Engine, 'before_cursor_execute', guard)
    try:
        report = module.run(manifest(tmp_path))
    finally:
        event.remove(Engine, 'before_cursor_execute', guard)
    assert report['status'] == 'PASS'
    assert report['samples'][0]['confirmation'] == 'PENDING_EVIDENCE_ONLY'
    assert report['samples'][1]['confirmation'] == 'BLOCKED'
    assert all(report['checks'].values())
    serialized = json.dumps(report)
    assert all(s not in serialized for s in ('CONFIDENTIAL', str(tmp_path), 'amount_cents', 'sha256', 'Loja exemplo'))
    assert connections and all(not p.parent.exists() for p in connections)


def test_pdf_tool_rejects_changed_original_without_exposing_values(tmp_path, monkeypatch):
    module = tool(monkeypatch)
    data = manifest(tmp_path)
    Path(data['samples'][0]['path']).write_bytes(b'%PDF-private-change')
    with pytest.raises(module.CheckFailed) as exc:
        module.run(data)
    assert exc.value.code == 'SOURCE_CHECKSUM'


def test_pdf_report_cannot_overwrite_any_source(tmp_path, monkeypatch, capsys):
    module = tool(monkeypatch)
    data = manifest(tmp_path)
    path = Path(data['samples'][0]['path'])
    raw = path.read_bytes()
    private = tmp_path / 'manifest.json'
    private.write_text(json.dumps(data), encoding='utf-8')
    monkeypatch.setattr('sys.argv', ['verify_financial_pdf.py', '--manifest', str(private), '--report', str(path)])
    assert module.main() == 1
    assert path.read_bytes() == raw
    assert 'REPORT_OVERWRITES_INPUT' in capsys.readouterr().out
