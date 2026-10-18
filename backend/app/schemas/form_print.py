from typing import Dict, List, Literal, Optional
from pydantic import BaseModel, Field, model_validator
from app.schemas.reports import ReportResponse


class FormPrintOptions(BaseModel):
    """Presentation only; never changes business records."""
    columns: Optional[List[str]] = None
    orientation: Literal['auto', 'portrait', 'landscape'] = 'auto'
    margin_top_mm: float = Field(15, ge=5, le=40)
    margin_bottom_mm: float = Field(15, ge=5, le=40)
    margin_left_mm: float = Field(15, ge=5, le=40)
    margin_right_mm: float = Field(15, ge=5, le=40)
    row_height_mm: float = Field(9, ge=6, le=30)
    font_size: float = Field(9, ge=8, le=16)
    blank_row_count: Optional[int] = Field(None, ge=1, le=500)
    column_weights: Dict[str, float] = Field(default_factory=dict)
    show_signatures: bool = True

    @model_validator(mode='after')
    def validate_columns(self):
        if self.columns is not None and (not self.columns or len(set(self.columns)) != len(self.columns)):
            raise ValueError('Selecione ao menos uma coluna, sem repetir campos.')
        if any(not 0.5 <= v <= 8 for v in self.column_weights.values()):
            raise ValueError('Larguras relativas devem estar entre 0,5 e 8.')
        return self

    def landscape(self, count: int) -> bool:
        return self.orientation == 'landscape' or (self.orientation == 'auto' and count > 5)

    def blank_rows(self, count: int) -> int:
        height = 210 if self.landscape(count) else 297
        # Same conservative reservation as the PDF: metadata, table header and footer.
        available = height - self.margin_top_mm - self.margin_bottom_mm - 28 - 18 - (18 if self.show_signatures else 9)
        return self.blank_row_count or max(1, int(available // self.row_height_mm))


class FormExportRequest(BaseModel):
    options: FormPrintOptions = Field(default_factory=FormPrintOptions)
    report: ReportResponse


def column_weight(column: str) -> float:
    if column in {'qty', 'unit'}:
        return 0.7
    if column in {'customer', 'description', 'beneficiary', 'item_name', 'notes'}:
        return 2.5
    if column == 'basket_type':
        return 1.8
    return 1.4


def select_form_columns(report: ReportResponse, options: FormPrintOptions) -> ReportResponse:
    columns = options.columns if options.columns is not None else report.columns
    if not columns or any(c not in report.columns for c in columns):
        raise ValueError('Uma ou mais colunas não pertencem a este formulário.')
    return report.model_copy(update={
        'columns': columns,
        'headers': [report.headers[report.columns.index(c)] for c in columns],
        'rows': [{c: row.get(c, '') for c in columns} for row in report.rows],
        'totals': {c: report.totals[c] for c in columns if c in report.totals},
    })
