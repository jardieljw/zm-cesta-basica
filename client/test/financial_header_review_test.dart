import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/views/financial_header_review_view.dart';
import 'financial_pdf_import_test.dart' as harness;

void main() {
  setUpAll(harness.loadImportFonts);
  testWidgets(
    'T04 reliable extracted controls prefill without calculated sums',
    (tester) async {
      await harness.mount(
        tester,
        const FinancialHeaderReviewView(
          isCard: true,
          extractedHeader: {
            'due_on': '2026-10-24',
            'total_amount_cents': 10001,
          },
        ),
      );
      expect(find.textContaining('24/10/2026'), findsOneWidget);
      final field = tester.widget<TextFormField>(
        find.byKey(const ValueKey('import-header-total_amount_cents')),
      );
      expect(field.controller!.text, '100,01');
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('import-header-minimum_payment_cents')),
            )
            .controller!
            .text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final card in [true, false]) {
    testWidgets(
      'CSV controls remain usable at narrow width and enlarged text card=$card',
      (tester) async {
        await harness.mount(
          tester,
          FinancialHeaderReviewView(isCard: card),
          size: const Size(320, 780),
          dark: true,
          scale: 1.7,
        );
        await harness.click(tester, find.byType(CheckboxListTile));
        await harness.click(tester, find.text('Usar dados conferidos'));
        expect(
          find.text('Selecione a data declarada no documento.'),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
        await harness.capture(
          tester,
          card ? 'csv-card-narrow-enlarged' : 'csv-bank-narrow-enlarged',
        );
      },
    );
    testWidgets(
      'CSV header starts with no invented dates or balances card=$card',
      (tester) async {
        await harness.mount(tester, FinancialHeaderReviewView(isCard: card));
        for (final field in tester.widgetList<TextFormField>(
          find.byType(TextFormField),
        )) {
          expect(field.controller!.text, isEmpty);
        }
        final action = find.text('Usar dados conferidos');
        expect(
          tester
              .widget<FilledButton>(
                find.ancestor(of: action, matching: find.byType(FilledButton)),
              )
              .onPressed,
          isNull,
        );
        await harness.click(tester, find.byType(CheckboxListTile));
        await harness.click(tester, action);
        expect(
          find.text('Selecione a data declarada no documento.'),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
        await harness.capture(
          tester,
          card ? 'csv-card-header-safe' : 'csv-bank-header-safe',
        );
      },
    );
  }
  testWidgets(
    'operator date and amount are returned exactly without transaction sums',
    (tester) async {
      Map<String, dynamic>? result;
      await harness.mount(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context)
                      .push<Map<String, dynamic>>(
                        MaterialPageRoute(
                          builder: (_) =>
                              const FinancialHeaderReviewView(isCard: true),
                        ),
                      );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await harness.click(tester, find.text('Abrir'));
      await harness.click(
        tester,
        find.byKey(const ValueKey('import-header-due_on')),
      );
      await harness.click(tester, find.text('20').last);
      await harness.click(tester, find.text('OK'));
      await tester.enterText(
        find.byKey(const ValueKey('import-header-total_amount_cents')),
        '123,45',
      );
      await harness.click(tester, find.byType(CheckboxListTile));
      await harness.click(tester, find.text('Usar dados conferidos'));
      expect(result!['total_amount_cents'], 12345);
      expect(result!['due_on'].toString().endsWith('-20'), isTrue);
      expect(result!.containsKey('minimum_payment_cents'), isFalse);
      expect(result!.containsKey('opening_balance_cents'), isFalse);
    },
  );
}
