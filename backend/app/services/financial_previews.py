"""Versioned import previews; confirmation only creates pending evidence."""
import uuid
import re
import copy

from pydantic import ValidationError
from sqlalchemy import select

from app.core.idempotency import compute_payload_hash
from app.models.financial_imports import FinancialImportPreview, FinancialDocument, FinancialSource
from app.schemas.financial_imports import FinancialStatementCreate, FinancialTransactionData
from app.services import financial_imports as evidence
from app.services.financial_readers import READERS, parse_csv, detect_csv, normalized
from app.services.financial_pdf_runtime import extract_pdf
from app.services.financial_preview_contract import enrich_report


def preview_summary(preview):
    result = evidence.as_dict(preview)
    report = preview.result
    result.update({k: v for k, v in report.items() if k not in {"items", "errors", "pages"}})
    result.update(items_count=len(report["items"]), errors_count=len(report["errors"]), affects_ledger=False)
    if report.get('contract_version') == 1:
        result['bill_cycle_version'] = 1
    return result


def interpretation(data):
    reader = READERS[data.reader_id]
    options = reader.options or data.options
    values = options.model_dump(mode="json") if options else {}
    return reader, options, compute_payload_hash({
        "reader_id": reader.id,
        "reader_version": reader.version,
        "options": values,
        "currency": data.currency,
        "has_password": bool(getattr(data, "password", None)),
        'control_preview_id': data.control_preview_id,
        'cycle_due_on': data.cycle_due_on.isoformat() if data.cycle_due_on else None,
    })


def existing_preview(db, document_id, source_id, request_hash):
    return db.scalar(select(FinancialImportPreview).where(
        FinancialImportPreview.document_id == document_id, FinancialImportPreview.source_id == source_id,
        FinancialImportPreview.request_sha256 == request_hash,
    ))


def prepare_pdf_preview(db, document_id, data):
    """Read immutable bytes, release the read transaction, then run the worker.

    Never perform untrusted PDF parsing while holding SQLite's write lock.
    The mutation subsequently revalidates document identity and selected source.
    """
    if data.reader_id != "pdf_auto":
        return None
    from app.services import financial_import_lifecycle as lifecycle
    current = lifecycle.latest(db, document_id)
    if data.expected_generation is None:
        evidence.fail('FINANCIAL_CLIENT_UPDATE_REQUIRED', 'Atualize o aplicativo para importar com segurança.')
    if current and current.state == 'ACTIVE' and not data.explicit_reprocess:
        db.rollback()
        return None
    document = evidence.require(db, FinancialDocument, document_id)
    source = evidence.require(db, FinancialSource, data.source_id)
    if document.media_type != "application/pdf":
        evidence.fail("FINANCIAL_READER_DOCUMENT_TYPE", "Este leitor exige documento PDF.", 415)
    if source.currency != data.currency or data.currency != "BRL":
        evidence.fail("FINANCIAL_IMPORT_CURRENCY_MISMATCH", "Estes layouts PDF exigem origem em reais.")
    _, _, request_hash = interpretation(data)
    if existing_preview(db, document_id, source.id, request_hash):
        db.rollback()
        return None
    content, digest = document.content, document.sha256
    db.rollback()
    pwd = getattr(data, "password", None)
    report = extract_pdf(content, password=pwd) if pwd else extract_pdf(content)
    if any(e['code'] == 'PDF_PASSWORD_REQUIRED' for e in report['errors']):
        # A wrong password is a retryable attempt, never an immutable parse result.
        evidence.fail('PDF_PASSWORD_REQUIRED', 'Confira a senha e tente novamente.', 422)
    transient = {"PDF_PROCESSING_FAILED", "PDF_PROCESSING_TIMEOUT", "PDF_RUNTIME_UNAVAILABLE", "PDF_PROCESSING_BUSY"}
    if any(e["code"] in transient for e in report["errors"]):
        evidence.fail(report["errors"][0]["code"], "Nao foi possivel processar o PDF agora. Tente novamente.", 503)
    return digest, report


def create_preview(db, document_id, data, actor_id, prepared=None):
    from app.services import financial_import_lifecycle as lifecycle
    current = lifecycle.latest(db, document_id)
    if data.expected_generation is None:
        evidence.fail('FINANCIAL_CLIENT_UPDATE_REQUIRED', 'Atualize o aplicativo para importar com segurança.')
    if data.expected_generation != (current.generation if current else 0):
        evidence.fail('FINANCIAL_IMPORT_GENERATION_CONFLICT', 'Esta importação mudou. Atualize a lista antes de continuar.')
    document = evidence.require(db, FinancialDocument, document_id)
    source = evidence.require(db, FinancialSource, data.source_id)
    reader, options, request_hash = interpretation(data)
    if document.media_type != reader.media_type:
        evidence.fail("FINANCIAL_READER_DOCUMENT_TYPE", "O documento nao corresponde ao leitor selecionado.", 415)
    if source.currency != data.currency or (reader.options is not None and reader.id != "generic_csv" and data.currency != "BRL"):
        evidence.fail("FINANCIAL_IMPORT_CURRENCY_MISMATCH", "A moeda confirmada deve corresponder a origem e ao leitor.")
    if options and (source.source_type == "BANK_ACCOUNT") != (options.amount_convention == "CREDITS_POSITIVE"):
        evidence.fail("FINANCIAL_IMPORT_SIGN_MISMATCH", "Confirme a convencao dos valores para conta bancaria ou cartao.")
    old = existing_preview(db, document_id, source.id, request_hash)
    if old:
        entry, created = lifecycle.activate_root(db, document_id, old, actor_id,
            data.expected_generation, explicit_reprocess=data.explicit_reprocess,
            expected_root_preview_id=data.expected_root_preview_id)
        return {"preview": lifecycle.preview_summary(db, entry, old),
                "import_id": entry.id, "generation": entry.generation,
                "duplicate": not created}
    if current and current.state == 'ACTIVE' and not data.explicit_reprocess:
        evidence.fail('FINANCIAL_IMPORT_ACTIVE',
            'Este arquivo já está em conferência. Abra o cadastro existente para continuar.')
    if reader.id == "pdf_auto":
        from app.models.auth import PairedDevice
        device = db.get(PairedDevice, actor_id)
        if device is None or not device.is_active:
            evidence.fail("FINANCIAL_AUTH_REQUIRED", "Autenticacao valida de dispositivo necessaria.", 401)
        if prepared is None or prepared[0] != document.sha256:
            evidence.fail("FINANCIAL_PREVIEW_CHANGED", "Gere outra previa do documento original.")
        report = prepared[1]
        if data.currency != "BRL":
            evidence.fail("FINANCIAL_IMPORT_CURRENCY_MISMATCH", "Estes layouts PDF exigem origem em reais.")
        if report.get("detected_source_type") and report["detected_source_type"] != source.source_type:
            report["errors"].append({"code": "PDF_SOURCE_TYPE_MISMATCH", "fields": []})
    elif reader.id == 'csv_auto':
        report = detect_csv(document.content, source.source_type,
                            institution=source.institution, holder_type=source.holder_type)
    else:
        report = parse_csv(document.content, options, exact_headers=reader.id == "nubank_account_csv")
    detected = report.get('detected_institution')
    known = {'NUBANK', 'ITAU', 'SANTANDER', 'INTER', 'PICPAY', 'MERCADO PAGO', 'MERCADOPAGO'}
    selected_text = normalized(source.institution)
    selected = next((name for name in known if re.search(r'\b' + re.escape(name) + r'\b', selected_text)), None)
    selected = 'MERCADOPAGO' if selected == 'MERCADO PAGO' else selected
    detected = 'MERCADOPAGO' if detected == 'MERCADO PAGO' else detected
    if detected in known and selected in known and detected != selected:
        report['errors'].append({'code': 'FINANCIAL_INSTITUTION_MISMATCH', 'fields': ['source_id']})
    if data.control_preview_id:
        attach_control_preview(db, report, source, data)
    report = enrich_report(report, document_id=document.id, reader_id=reader.id,
                           reader_version=reader.version, source_type=source.source_type)
    preview = FinancialImportPreview(
        id=str(uuid.uuid4()), document_id=document.id, source_id=source.id,
        reader_id=reader.id, reader_version=reader.version, options=options.model_dump(mode="json") if options else {},
        request_sha256=request_hash, result_sha256=compute_payload_hash(report),
        status="INVALID" if report["errors"] else "READY", result=report, created_by=actor_id,
    )
    db.add(preview)
    db.flush()
    evidence.audit(db, actor_id, "IMPORT_PREVIEW_CREATED", preview, {
        "reader_id": reader.id, "reader_version": reader.version, "status": preview.status,
        "items_count": len(report["items"]), "errors_count": len(report["errors"]),
    })
    entry, _ = lifecycle.activate_root(db, document_id, preview, actor_id,
        data.expected_generation, explicit_reprocess=data.explicit_reprocess,
        expected_root_preview_id=data.expected_root_preview_id)
    return {"preview": lifecycle.preview_summary(db, entry, preview),
            "import_id": entry.id, "generation": entry.generation,
            "duplicate": False}


def attach_control_preview(db, report, source, data):
    """Only an immutable, compatible single bill can complement missing controls.

    This binds evidence; it does not certify CSV detail coverage or post a title.
    A CSV without a cycle needs an explicit operator declaration of that cycle.
    """
    control = evidence.require(db, FinancialImportPreview, data.control_preview_id)
    from app.services.financial_import_lifecycle import entry_for_preview
    if entry_for_preview(db, control.id) is None:
        evidence.fail('FINANCIAL_IMPORT_HISTORICAL_READ_ONLY',
            'O documento complementar não está ativo. Confira sua importação atual.')
    other = control.result
    header = other.get('extracted_header', {})
    due = header.get('due_on')
    target = report.setdefault('extracted_header', {})
    cycle = target.get('due_on') or (data.cycle_due_on.isoformat() if data.cycle_due_on else None)
    if (control.source_id != source.id or source.source_type != 'CREDIT_CARD' or
            other.get('content_type') != 'DETAILED_CARD_BILL' or
            not other.get('readiness', {}).get('can_prepare_bill') or
            due is None or cycle != due or header.get('total_amount_cents') is None):
        evidence.fail('FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE', 'Confira origem, ciclo e controles do documento complementar.')
    if report.get('observed_dates') and report['observed_dates']['last'] > due:
        evidence.fail('FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE', 'As datas das linhas ultrapassam o ciclo complementar.')
    if report.get('content_type') in {'SUMMARY_INDEX', 'MULTI_CYCLE_COMPILATION'}:
        evidence.fail('FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE', 'Uma compilacao nao comprova uma fatura unica.')
    if data.cycle_due_on and target.get('due_on') is None:
        report.setdefault('controls', []).append({'field': 'cycle_due_on', 'value': cycle,
            'kind': 'HEADER', 'origin': 'OPERATOR_DECLARATION', 'raw_text': cycle})
    for field in ('due_on', 'total_amount_cents', 'minimum_payment_cents', 'closing_on'):
        if field not in header:
            continue
        if target.get(field) not in (None, header[field]):
            evidence.fail('FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE', 'Os controles dos documentos divergem.')
        if len({c['value'] for c in report.get('header_candidates', {}).get(field, [])}) > 1:
            evidence.fail('FINANCIAL_CONTROL_COMPLEMENT_INCOMPATIBLE', 'Resolva o controle conflitante antes de complementar.')
        target[field] = header[field]
        report.setdefault('controls', []).extend(c for c in other.get('controls', []) if c['field'] == field)
    report['control_complement'] = {'preview_id': control.id, 'result_sha256': control.result_sha256,
                                    'document_id': control.document_id, 'cycle_due_on': cycle}


def preview_items(db, preview, offset, limit):
    return [{**item, "candidates": evidence.data_candidates(
        db, preview.source_id, FinancialTransactionData.model_validate(item["data"]),
    )} for item in preview.result["items"][offset:offset + limit]]


def select_segment(db, preview_id, data, actor):
    from app.services import financial_import_lifecycle as lifecycle
    entry, parent = lifecycle.require_preview(db, preview_id, data.import_id, data.expected_generation)
    if parent.result_sha256 != data.expected_result_sha256:
        evidence.fail('FINANCIAL_PREVIEW_CHANGED', 'A leitura mudou; atualize a conferencia.')
    segment = next((s for s in parent.result.get('segments', []) if s['key'] == data.segment_key), None)
    if segment is None:
        evidence.fail('FINANCIAL_SEGMENT_NOT_FOUND', 'Selecione um ciclo disponivel.')
    source = evidence.require(db, FinancialSource, data.source_id)
    bank = normalized(segment.get('institution', '')).replace('NU EMPRESAS', 'NUBANK').replace('NU PAGAMENTOS', 'NUBANK').replace('MERCADOPAGO', 'MERCADO PAGO')
    selected = normalized(source.institution).replace('NU EMPRESAS', 'NUBANK').replace('NU PAGAMENTOS', 'NUBANK').replace('MERCADOPAGO', 'MERCADO PAGO')
    banks = ('NUBANK', 'ITAU', 'SANTANDER', 'INTER', 'PICPAY', 'MERCADO PAGO')
    expected = next((b for b in banks if b in bank), bank)
    if expected and expected not in selected:
        evidence.fail('FINANCIAL_INSTITUTION_MISMATCH', 'Confira a instituicao do segmento e da origem.')
    if any(f'({holder})' in bank and source.holder_type != holder for holder in ('PF','PJ')) or ('NU EMPRESAS' in normalized(segment.get('institution','')) and source.holder_type != 'PJ'):
        evidence.fail('FINANCIAL_IMPORT_SOURCE_MISMATCH', 'Confira o titular da conta ou cartao.')
    kind = segment['document_kind']
    if (kind == 'BANK_STATEMENT_INDEX') != (source.source_type == 'BANK_ACCOUNT'):
        evidence.fail('FINANCIAL_STATEMENT_SOURCE_MISMATCH', 'Confira conta ou cartao para este documento.')
    if source.currency != 'BRL':
        evidence.fail('FINANCIAL_IMPORT_CURRENCY_MISMATCH', 'Estes documentos exigem reais.')
    request_hash = compute_payload_hash({'parent': parent.id, 'expected_result_sha256':data.expected_result_sha256,
        'segment_key':data.segment_key, 'source_id':data.source_id})
    old = existing_preview(db, parent.document_id, source.id, request_hash)
    if old:
        lifecycle.attach_segment(db, entry, parent, old, data.segment_key, actor)
        return {'preview': lifecycle.preview_summary(db, entry, old), 'duplicate': True}
    report = copy.deepcopy(segment)
    report['segment_provenance'] = dict(parent_preview_id=parent.id, result_sha256=parent.result_sha256, segment_key=segment['key'])
    if kind in {'BANK_STATEMENT_INDEX', 'RENEGOTIATION', 'UNKNOWN_INDEX'}:
        report['content_type'] = kind
    report = enrich_report(report, document_id=parent.document_id, reader_id=parent.reader_id,
        reader_version=parent.reader_version, source_type=source.source_type)
    child = FinancialImportPreview(id=str(uuid.uuid4()), document_id=parent.document_id, source_id=source.id,
        reader_id=parent.reader_id, reader_version=parent.reader_version, options={'segment':report['segment_provenance']},
        request_sha256=request_hash, result_sha256=compute_payload_hash(report),
        result=report, status='INVALID' if report['errors'] else 'READY', created_by=actor)
    db.add(child)
    db.flush()
    evidence.audit(db, actor, 'IMPORT_SEGMENT_SELECTED', child, report['segment_provenance'])
    lifecycle.attach_segment(db, entry, parent, child, data.segment_key, actor)
    return {'preview': lifecycle.preview_summary(db, entry, child), 'duplicate': False}


def confirm_preview(db, preview_id, data, actor_id):
    from app.services import financial_import_lifecycle as lifecycle
    entry, preview = lifecycle.require_preview(db, preview_id, data.import_id, data.expected_generation)
    if data.expected_source_id != preview.source_id:
        evidence.fail("FINANCIAL_IMPORT_SOURCE_MISMATCH", "Confirme a conta ou o cartao selecionado na previa.")
    if data.expected_result_sha256 != preview.result_sha256:
        evidence.fail("FINANCIAL_PREVIEW_CHANGED", "Confira o resultado da previa antes de confirmar.")
    if preview.status != "READY":
        evidence.fail("FINANCIAL_PREVIEW_INVALID", "A previa possui erros. Corrija o mapeamento e gere outra previa.")
    header = data.model_dump(mode="json", exclude={"import_id", "expected_generation", "expected_source_id", "expected_result_sha256", "assessment_id"})
    extracted = preview.result.get('extracted_header', {})
    if preview.reader_id == "pdf_auto" or extracted:
        for field, value in extracted.items():
            if header.get(field) is not None and header[field] != value:
                evidence.fail("FINANCIAL_PDF_HEADER_CONFLICT", "Os dados confirmados divergem dos dados extraidos do PDF.")
            header[field] = value
    if preview.reader_id != 'pdf_auto':
        totals = preview.result.get('totals', {})
        if header.get('statement_type') == 'BANK_STATEMENT':
            for field, key in (('total_inflows_cents', 'positive_cents'), ('total_outflows_cents', 'negative_cents')):
                if header.get(field) is not None and header[field] != totals.get(key):
                    evidence.fail('FINANCIAL_IMPORT_CONTROL_MISMATCH', 'O controle declarado diverge dos lancamentos extraidos.')
            opening, closing = header.get('opening_balance_cents'), header.get('closing_balance_cents')
            if opening is not None and closing is not None and opening + totals['net_cents'] != closing:
                evidence.fail('FINANCIAL_IMPORT_CONTROL_MISMATCH', 'Os saldos declarados nao correspondem aos movimentos.')
    assessment = None
    if data.assessment_id:
        from app.services import financial_bill_assessments as bills
        effective = type(data).model_validate({**data.model_dump(mode="json"), **header})
        assessment = bills.validate_confirmation(db, preview, effective)
    try:
        statement = FinancialStatementCreate(
            document_id=preview.document_id, source_id=preview.source_id, **header,
            items=[{k: v for k, v in item.items() if k in {"position", "page_number", "raw_text", "data"}}
                   for item in preview.result["items"]],
        )
    except ValidationError:
        evidence.fail("FINANCIAL_IMPORT_HEADER_INVALID", "Confira periodo, tipo e totais informados no documento.", 422)
    result = evidence.create_statement(db, statement, actor_id, preview_id=preview.id)
    lifecycle.attach_statement(db, entry, preview, db.get(evidence.FinancialStatement, result['statement']['id']), actor_id)
    result['statement'].update(import_id=entry.id, generation=entry.generation)
    if assessment:
        bills.link_confirmation(db, result["statement"]["id"], assessment, actor_id)
        result["assessment_id"] = assessment.id
    if not result["duplicate"]:
        if preview.reader_id != 'pdf_auto':
            evidence.audit(db, actor_id, 'IMPORT_HEADER_DECLARED', preview, {
                'statement_id': result['statement']['id'],
                'fields': {key: value for key, value in header.items() if value is not None and key not in extracted},
                'document_fields': sorted(extracted),
                'origin': 'OPERATOR_DECLARATION',
            })
        evidence.audit(db, actor_id, "IMPORT_PREVIEW_CONFIRMED", preview, {"statement_id": result["statement"]["id"]})
    return result
