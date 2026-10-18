import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/models/form_print_options.dart';
import 'package:zm_cesta_basica_client/models/report.dart';
import 'package:zm_cesta_basica_client/services/reports_service.dart';
import 'package:zm_cesta_basica_client/views/blank_forms_view.dart';
import 'form_document_test.dart' show formSample;

class _FormsService extends ReportsService {
  final requests = <Completer<ReportResponse>>[];
  bool deferred = false;
  FormPrintOptions? exportedOptions;
  ReportResponse? exportedReport;
  @override
  Future<ReportResponse> getBlankTemplate(String formType,
      {bool filled = false}) {
    if (!deferred) {
      return Future.value(formSample(filled: filled, rows: filled ? 0 : 1));
    }
    final request = Completer<ReportResponse>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<List<int>> exportConfiguredForm(
      String formType, ReportResponse report, FormPrintOptions options) async {
    exportedOptions = options;
    exportedReport = report;
    return [1, 2, 3];
  }
}

Widget _app(Widget view, {double scale = 1}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: view,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 560.0, 1200.0]) {
    testWidgets(
        'column selection and print controls fit at $width with enlarged text',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
          _app(BlankFormsView(service: _FormsService()), scale: 1.3));
      await tester.pumpAndSettle();
      final chip = find.byKey(const ValueKey('column-qty'));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(chip).selected, isFalse);
      await tester.ensureVisible(find.text('Ordem das colunas'));
      await tester.tap(find.text('Ordem das colunas'));
      await tester.pumpAndSettle();
      final firstUp = find.byKey(const ValueKey('column-up-sale_date'));
      await tester.ensureVisible(firstUp);
      expect(tester.widget<IconButton>(firstUp).onPressed, isNull);
      expect(tester.getRect(firstUp).right, lessThanOrEqualTo(width));
      final lastDown = find.byKey(const ValueKey('column-down-notes'));
      await tester.ensureVisible(lastDown);
      expect(tester.widget<IconButton>(lastDown).onPressed, isNull);
      expect(tester.getRect(lastDown).right, lessThanOrEqualTo(width));
      await tester.ensureVisible(find.byKey(const ValueKey('margin-left')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  for (final filled in [false, true]) {
    testWidgets(
        'column order survives selection, export and reopen (filled=$filled)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        'form_print_v1_payments': jsonEncode(const FormPrintOptions(
          columns: ['sale_date', 'customer', 'qty'],
          marginLeftMm: 21,
          columnWeights: {'customer': 4},
        ).toJson())
      });
      final service = _FormsService();
      Future<void> tapKey(String key) async {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> expandOrder() async {
        await tester.ensureVisible(find.text('Ordem das colunas'));
        await tester.tap(find.text('Ordem das colunas'));
        await tester.pumpAndSettle();
      }

      Future<FormPrintOptions> stored() async => FormPrintOptions.fromJson(
          jsonDecode((await SharedPreferences.getInstance())
              .getString('form_print_v1_payments')!));
      await tester.pumpWidget(_app(
          BlankFormsView(service: service, saveFile: (_, __) async => false)));
      await tester.pumpAndSettle();
      if (filled) {
        await tester.tap(find.text('Documento Preenchido (Auditoria Física)'));
        await tester.pumpAndSettle();
      }
      await expandOrder();
      await tapKey('column-up-qty');
      await tapKey('column-down-sale_date');
      expect((await stored()).columns, ['qty', 'sale_date', 'customer']);
      expect(
          tester
              .getTopLeft(find.byKey(const ValueKey('ordered-column-qty')))
              .dy,
          lessThan(tester
              .getTopLeft(
                  find.byKey(const ValueKey('ordered-column-sale_date')))
              .dy));
      await tapKey('column-total_cents');
      await tester.ensureVisible(find.text('Salvar planilha XLSX'));
      await tester.tap(find.text('Salvar planilha XLSX'));
      await tester.pumpAndSettle();
      const expected = ['qty', 'sale_date', 'customer', 'total_cents'];
      expect(service.exportedOptions!.columns, expected);
      expect(service.exportedReport!.metadata.reportType,
          filled ? 'audit-payments' : 'blank-payments');
      await tester.pumpWidget(_app(
          BlankFormsView(key: const ValueKey('reopened'), service: service)));
      await tester.pumpAndSettle();
      expect((await stored()).columns, expected);
      await expandOrder();
      expect(
          tester
              .widget<IconButton>(find.byKey(const ValueKey('column-up-qty')))
              .onPressed,
          isNull);
      await tapKey('restore-column-order');
      final restored = await stored();
      expect(restored.columns, ['sale_date', 'customer', 'qty', 'total_cents']);
      expect(restored.marginLeftMm, 21);
      expect(restored.columnWeights['customer'], 4);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'select all appends missing fields without resetting chosen order',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'form_print_v1_payments': jsonEncode(
          const FormPrintOptions(columns: ['qty', 'customer']).toJson())
    });
    await tester.pumpWidget(_app(BlankFormsView(service: _FormsService())));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Selecionar todas'));
    await tester.tap(find.text('Selecionar todas'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final columns = FormPrintOptions.fromJson(
            jsonDecode(prefs.getString('form_print_v1_payments')!))
        .columns!;
    expect(columns.take(2), ['qty', 'customer']);
    expect(columns.toSet(), formSample().columns.toSet());
    expect(columns.length, formSample().columns.length);
    final sale = find.byKey(const ValueKey('column-sale_date'));
    await tester.ensureVisible(sale);
    await tester.tap(sale);
    await tester.pumpAndSettle();
    final after = FormPrintOptions.fromJson(
            jsonDecode(prefs.getString('form_print_v1_payments')!))
        .columns!;
    expect(after.take(2), ['qty', 'customer']);
    expect(after, isNot(contains('sale_date')));
  });
  testWidgets(
      'XLSX uses selected fields and displayed snapshot; cancelling save has no success',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FormsService();
    var saves = 0;
    await tester.pumpWidget(_app(BlankFormsView(
        service: service,
        saveFile: (bytes, name) async {
          saves++;
          expect(name, endsWith('.xlsx'));
          return false;
        })));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('column-qty')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar planilha XLSX'));
    await tester.tap(find.text('Salvar planilha XLSX'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(service.exportedOptions!.columns, isNot(contains('qty')));
    expect(service.exportedReport!.metadata.totalRows, 1);
    expect(find.text('Arquivo salvo no local escolhido.'), findsNothing);
  });
  testWidgets(
      'out-of-order requests and disposed screen cannot publish stale reports',
      (tester) async {
    final service = _FormsService()..deferred = true;
    await tester.pumpWidget(_app(BlankFormsView(service: service)));
    await tester.pump();
    await tester.tap(find.text('Documento Preenchido (Auditoria Física)'));
    await tester.pump();
    expect(service.requests.length, 2);
    service.requests[1].complete(formSample(filled: true, rows: 0));
    await tester.pumpAndSettle();
    service.requests[0].complete(formSample());
    await tester.pumpAndSettle();
    expect(find.text('Nenhum registro encontrado para este documento.'),
        findsOneWidget);
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    service.requests.last.complete(formSample());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed refresh removes print and export actions',
      (tester) async {
    final service = _FormsService();
    await tester.pumpWidget(_app(BlankFormsView(service: service)));
    await tester.pumpAndSettle();
    service.deferred = true;
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    service.requests.last.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Salvar planilha XLSX'), findsNothing);
    expect(find.text('Visualizar e Imprimir A4'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
