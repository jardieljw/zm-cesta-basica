import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/models/dashboard.dart';
import 'package:zm_cesta_basica_client/models/report.dart';
import 'package:zm_cesta_basica_client/models/form_print_options.dart';
import 'package:zm_cesta_basica_client/utils/form_pdf_builder.dart';

ReportResponse formSample({bool filled = false, int rows = 1}) =>
    ReportResponse(
      metadata: ReportMetadata(
          reportType: '${filled ? 'audit' : 'blank'}-payments',
          title:
              'Tabela de Pagamentos de Cestas (Preenchimento Manual à Caneta)',
          companyName: 'ZM Cesta Básica',
          generatedAt: DateTime.utc(2026, 10, 14, 15),
          filterInfo: FilterInfo(filterType: 'all', label: 'Conferência'),
          totalRows: rows),
      columns: [
        'sale_date',
        'customer',
        'basket_type',
        'qty',
        'total_cents',
        'due_date',
        'payment_date',
        'received_cents',
        'balance_cents',
        'signature',
        'notes'
      ],
      headers: [
        'Data Venda',
        'Cliente / Identificação',
        'Tipo de Cesta',
        'Qtd',
        'Valor Total (R\$)',
        'Data Prevista',
        'Data do pagamento',
        'Total Recebido (R\$)',
        'Saldo Restante (R\$)',
        'Quitação / Visto',
        'Observações'
      ],
      rows: List.generate(
          rows,
          (_) => {
                'customer': 'Cliente de teste',
                'total_cents': 12345,
                'received_cents': 2345,
                'balance_cents': 10000
              }),
      totals: {
        'total_cents': 12345,
        'received_cents': 2345,
        'balance_cents': 10000
      },
    );

void main() {
  test(
      'selection preserves matching headers, values and totals without mutating source',
      () {
    final source = formSample(filled: true);
    final selected =
        const FormPrintOptions(columns: ['balance_cents', 'customer'])
            .select(source);
    expect(selected.columns, ['balance_cents', 'customer']);
    expect(
        selected.headers, ['Saldo Restante (R\$)', 'Cliente / Identificação']);
    expect(selected.rows.single,
        {'balance_cents': 10000, 'customer': 'Cliente de teste'});
    expect(selected.totals, {'balance_cents': 10000});
    expect(source.columns.length, 11);
    expect(() => const FormPrintOptions(columns: []).select(source),
        throwsArgumentError);
  });
  test('default blank form fits one A4 page and manual rows paginate',
      () async {
    final source = formSample();
    final automatic = await FormPdfBuilder.build(
        source, const FormPrintOptions(),
        blank: true);
    expect(automatic.pages, 1);
    final manual = await FormPdfBuilder.build(
        source, const FormPrintOptions(blankRowCount: 40),
        blank: true);
    expect(manual.pages, greaterThan(1));
  });
  test('portrait subset and large margins keep automatic form on one page',
      () async {
    final result = await FormPdfBuilder.build(
        formSample(),
        const FormPrintOptions(
            columns: ['customer', 'total_cents', 'signature'],
            orientation: 'portrait',
            marginTopMm: 40,
            marginBottomMm: 40,
            marginLeftMm: 30,
            marginRightMm: 30,
            rowHeightMm: 15),
        blank: true);
    expect(result.pages, 1);
  });
  test('automatic blank rows validate actual layout for tall custom headers',
      () async {
    final result = await FormPdfBuilder.build(
        formSample(),
        const FormPrintOptions(
          orientation: 'portrait',
          fontSize: 16,
          rowHeightMm: 6,
          marginTopMm: 40,
          marginBottomMm: 40,
        ),
        blank: true);
    expect(result.pages, 1);
    expect(result.rows, greaterThan(0));
  });
  test('empty audit stays empty; filled reports retain handwritten row space',
      () async {
    final empty = await FormPdfBuilder.build(
        formSample(filled: true, rows: 0), const FormPrintOptions(),
        blank: false);
    expect(empty.pages, 1);
    final many = await FormPdfBuilder.build(formSample(filled: true, rows: 40),
        const FormPrintOptions(rowHeightMm: 12),
        blank: false);
    expect(many.pages, greaterThan(1));
  });
  test('settings round trip preserves widths, margins and automatic row mode',
      () {
    const options = FormPrintOptions(
        columns: ['customer', 'qty'],
        orientation: 'landscape',
        marginLeftMm: 22,
        columnWeights: {'customer': 4},
        blankRowCount: 37,
        showSignatures: false);
    expect(
        FormPrintOptions.fromJson(options.toJson()).toJson(), options.toJson());
    expect(options.copyWith(automaticRows: true).blankRowCount, isNull);
    expect(const FormPrintOptions().automaticRows(11), 12);
    expect(
        FormPdfBuilder.formatCell(12345.0, 'total_cents'), contains('123,45'));
    expect(FormPdfBuilder.formatCell('2026-10-14T00:00:00Z', 'due_date'),
        '14/10/2026');
  });
}
