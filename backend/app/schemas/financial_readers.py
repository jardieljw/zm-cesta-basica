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
    source_id: EntityId
    currency: str = Field(pattern=r"^[A-Z]{3}$")
    reader_id: str = Field(min_length=1, max_length=50)
    options: CSVOptions | None = None
    password: str | None = Field(None, min_length=1, max_length=100)

    @model_validator(mode="after")
    def options_shape(self):
        from app.services.financial_readers import READERS
        if self.reader_id not in READERS:
            raise ValueError(f"Leitor desconhecido: {self.reader_id}")
        if (self.reader_id == "generic_csv") != (self.options is not None):
            raise ValueError("CSV generico exige mapeamento; leitor conhecido usa seu proprio contrato.")
        return self


class FinancialPreviewConfirm(FinancialInput):
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
