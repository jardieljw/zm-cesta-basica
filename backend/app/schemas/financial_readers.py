"""Explicit CSV interpretation: no guessing currency, dates, signs or account."""
from typing import Literal

from pydantic import Field, model_validator

from app.schemas.financial_imports import (
    FinancialInput, EntityId, CalendarDate, Money, NonnegativeMoney,
)


class CSVColumns(FinancialInput):
    transaction_date: str = Field(min_length=1, max_length=100)
    amount: str = Field(min_length=1, max_length=100)
    description: str = Field(min_length=1, max_length=100)
    external_id: str | None = Field(None, min_length=1, max_length=100)
    transaction_time: str | None = Field(None, min_length=1, max_length=100)
    purchase_date: str | None = Field(None, min_length=1, max_length=100)
    booking_date: str | None = Field(None, min_length=1, max_length=100)
    counterparty_name: str | None = Field(None, min_length=1, max_length=100)
    counterparty_document: str | None = Field(None, min_length=1, max_length=100)
    card_last_four: str | None = Field(None, min_length=1, max_length=100)
    installment_number: str | None = Field(None, min_length=1, max_length=100)
    total_installments: str | None = Field(None, min_length=1, max_length=100)

    @model_validator(mode="after")
    def distinct_columns(self):
        names = [v for v in self.model_dump().values() if v is not None]
        if len(set(names)) != len(names):
            raise ValueError("Cada campo exige uma coluna distinta.")
        return self


class CSVOptions(FinancialInput):
    columns: CSVColumns
    delimiter: Literal[",", ";", "\t"] = ","
    encoding: Literal["utf-8-sig", "cp1252"] = "utf-8-sig"
    date_format: Literal["DD/MM/YYYY", "YYYY-MM-DD", "MM/DD/YYYY"]
    decimal_separator: Literal[".", ","]
    thousands_separator: Literal[".", ",", " "] | None = None
    amount_convention: Literal["CREDITS_POSITIVE", "CHARGES_POSITIVE", "CHARGES_NEGATIVE"]
    amount_sign_spacing: Literal["ADJACENT", "OPTIONAL_SINGLE_SPACE"] = "ADJACENT"
    date_kind: Literal["AS_REPORTED", "PURCHASE", "BOOKING"] = "AS_REPORTED"
    external_id_namespace: str | None = Field(None, min_length=1, max_length=50)

    @model_validator(mode="after")
    def explicit_format(self):
        if self.thousands_separator == self.decimal_separator:
            raise ValueError("Separadores decimal e de milhar devem ser diferentes.")
        if bool(self.columns.external_id) != bool(self.external_id_namespace):
            raise ValueError("Coluna de identificador exige namespace estavel da origem.")
        return self


class FinancialPreviewCreate(FinancialInput):
    expected_generation: int | None = Field(None, strict=True, ge=0)
    explicit_reprocess: bool = False
    expected_root_preview_id: EntityId | None = None
    source_id: EntityId
    currency: str = Field(pattern=r"^[A-Z]{3}$")
    reader_id: str = Field(min_length=1, max_length=50)
    options: CSVOptions | None = None
    password: str | None = Field(None, min_length=1, max_length=100)
    expected_reader_version: str | None = Field(None, min_length=1, max_length=30)
    control_preview_id: EntityId | None = None
    # A cycle declaration is necessary when the detail CSV has no cycle header.
    cycle_due_on: CalendarDate | None = None

    @model_validator(mode="after")
    def options_shape(self):
        from app.services.financial_readers import READERS
        if self.reader_id not in READERS:
            raise ValueError(f"Leitor desconhecido: {self.reader_id}")
        if self.expected_reader_version is not None and self.expected_reader_version != READERS[self.reader_id].version:
            raise ValueError("O leitor foi atualizado. Consulte sua versao antes de importar.")
        if (self.reader_id == "generic_csv") != (self.options is not None):
            raise ValueError("CSV generico exige mapeamento; leitor conhecido usa seu proprio contrato.")
        if self.cycle_due_on is not None and self.control_preview_id is None:
            raise ValueError('A declaracao de ciclo exige uma previa complementar.')
        return self


class FinancialSegmentSelect(FinancialInput):
    import_id: EntityId | None = None
    expected_generation: int | None = Field(None, strict=True, ge=1)
    expected_result_sha256: str = Field(pattern=r'^[a-f0-9]{64}$')
    segment_key: str = Field(min_length=1, max_length=20)
    source_id: EntityId


class PreviewControl(FinancialInput):
    field: str
    value: str | int
    kind: Literal['HEADER', 'TOTAL', 'MINIMUM', 'SUMMARY_COMPONENT', 'SUBTOTAL', 'OFFER']
    origin: Literal['DOCUMENT', 'OPERATOR_DECLARATION'] = 'DOCUMENT'
    page_number: int | None = None
    line_start: int | None = None
    raw_text: str
    document_id: str | None = None
    reader_id: str | None = None
    reader_version: str | None = None


class PreviewPending(FinancialInput):
    code: str
    fields: list[str] = Field(default_factory=list)
    blocks_header: bool = False
    blocks_details: bool = False


class PreviewItemMeaning(FinancialInput):
    role: Literal['PURCHASE', 'CHARGE', 'PAYMENT', 'CREDIT', 'PREVIOUS_BALANCE', 'UNKNOWN']
    purpose: Literal['UNSPECIFIED'] = 'UNSPECIFIED'


class PreviewReadiness(FinancialInput):
    version: Literal[1] = 1
    header_status: Literal['MISSING', 'CONFLICTING', 'DOCUMENT_VALIDATED', 'OPERATOR_DECLARED']
    details_status: Literal['SUMMARY_ONLY', 'AVAILABLE_UNRECONCILED', 'RECONCILED']
    financial_status: Literal['PENDING'] = 'PENDING'
    total_basis: Literal['DOCUMENT', 'CALCULATED_ONLY', 'MISSING']
    difference_cents: int | None = None
    can_prepare_bill: bool = False
    can_prepare_complete_details: bool = False
    can_generate_obligations: Literal[False] = False
    pending: list[PreviewPending] = Field(default_factory=list)


class FinancialPreviewConfirm(FinancialInput):
    import_id: EntityId | None = None
    expected_generation: int | None = Field(None, strict=True, ge=1)
    assessment_id: EntityId | None = None
    expected_source_id: EntityId
    expected_result_sha256: str = Field(pattern=r"^[a-f0-9]{64}$")
    statement_type: Literal["BANK_STATEMENT", "CARD_BILL"]
    period_start: CalendarDate | None = None
    period_end: CalendarDate | None = None
    issued_on: CalendarDate | None = None
    closing_on: CalendarDate | None = None
    due_on: CalendarDate | None = None
    opening_balance_cents: Money | None = None
    closing_balance_cents: Money | None = None
    total_inflows_cents: NonnegativeMoney | None = None
    total_outflows_cents: NonnegativeMoney | None = None
    total_amount_cents: Money | None = None
    minimum_payment_cents: NonnegativeMoney | None = None
