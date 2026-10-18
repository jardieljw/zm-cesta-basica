import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/models/dispatch.dart';
import 'package:zm_cesta_basica_client/models/sale.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations_pt.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';

void main() {
  group('Phase 6 ResponsiblePerson & Custody Tests', () {
    test('ResponsiblePerson fromJson and toJson parsing', () {
      final json = {
        'id': 'resp-1',
        'name': 'Carlos Motorista',
        'phone': '(11) 98765-4321',
        'is_active': true,
        'notes': 'Responsável rota centro',
        'created_at': '2026-10-11T08:00:00.000Z',
        'updated_at': '2026-10-11T08:00:00.000Z',
      };

      final person = ResponsiblePerson.fromJson(json);
      expect(person.id, 'resp-1');
      expect(person.name, 'Carlos Motorista');
      expect(person.phone, '(11) 98765-4321');
      expect(person.isActive, isTrue);
      expect(person.notes, 'Responsável rota centro');

      final out = person.toJson();
      expect(out['name'], 'Carlos Motorista');
      expect(out['phone'], '(11) 98765-4321');
      expect(out['is_active'], isTrue);
    });

    test('ResponsiblePersonCustody fromJson parsing', () {
      final json = {
        'responsible_person_id': 'resp-1',
        'responsible_person_name': 'Carlos Motorista',
        'total_custody_baskets': 15,
        'baskets': [
          {
            'basket_type_id': 'bt-1',
            'basket_type_name': 'Cesta Básica Econômica',
            'balance': 10,
          },
          {
            'basket_type_id': 'bt-2',
            'basket_type_name': 'Cesta Básica Família',
            'balance': 5,
          },
        ],
      };

      final custody = ResponsiblePersonCustody.fromJson(json);
      expect(custody.responsiblePersonId, 'resp-1');
      expect(custody.responsiblePersonName, 'Carlos Motorista');
      expect(custody.totalCustodyBaskets, 15);
      expect(custody.baskets.length, 2);
      expect(custody.baskets.first.basketTypeName, 'Cesta Básica Econômica');
      expect(custody.baskets.first.balance, 10);
      expect(custody.baskets.last.balance, 5);
    });
  });

  group('Phase 6 StockDispatch & Items Tests', () {
    test('StockDispatchCreate and DispatchItemCreate toJson', () {
      final item = DispatchItemCreate(
        basketTypeId: 'bt-1',
        quantity: 20,
        unitPriceCents: 15000,
        notes: 'Lote padrão',
      );
      final create = StockDispatchCreate(
        responsiblePersonId: 'resp-1',
        notes: 'Saída manhã',
        items: [item],
      );

      final json = create.toJson();
      expect(json['responsible_person_id'], 'resp-1');
      expect(json['notes'], 'Saída manhã');
      expect((json['items'] as List).length, 1);
      final itemJson = (json['items'] as List).first as Map<String, dynamic>;
      expect(itemJson['basket_type_id'], 'bt-1');
      expect(itemJson['quantity'], 20);
      expect(itemJson['unit_price_cents'], 15000);
      expect(itemJson['notes'], 'Lote padrão');
    });

    test('StockDispatch and StockDispatchDetail fromJson parsing', () {
      final json = {
        'id': 'disp-1',
        'dispatch_number': 101,
        'responsible_person_id': 'resp-1',
        'responsible_person_name': 'Carlos Motorista',
        'dispatch_date': '2026-10-11T09:00:00.000Z',
        'status': 'OPEN',
        'total_items_quantity': 25,
        'total_reference_amount_cents': 375000,
        'notes': 'Entrega bairros sul',
        'created_at': '2026-10-11T09:00:00.000Z',
        'updated_at': '2026-10-11T09:00:00.000Z',
        'items': [
          {
            'id': 'ditem-1',
            'dispatch_id': 'disp-1',
            'basket_type_id': 'bt-1',
            'basket_type_name': 'Cesta Básica Família',
            'production_batch_id': null,
            'quantity': 25,
            'unit_price_cents': 15000,
            'total_price_cents': 375000,
            'notes': null,
          }
        ],
        'sales_count': 5,
        'returns_count': 2,
        'losses_count': 1,
        'expenses_count': 1,
        'repayments_count': 2,
        'has_settlement': false,
        'settlement_status': null,
      };

      final detail = StockDispatchDetail.fromJson(json);
      expect(detail.id, 'disp-1');
      expect(detail.dispatchNumber, 101);
      expect(detail.responsiblePersonName, 'Carlos Motorista');
      expect(detail.status, 'OPEN');
      expect(detail.totalItemsQuantity, 25);
      expect(detail.totalReferenceAmountCents, 375000);
      expect(detail.items.length, 1);
      expect(detail.items.first.basketTypeName, 'Cesta Básica Família');
      expect(detail.salesCount, 5);
      expect(detail.returnsCount, 2);
      expect(detail.lossesCount, 1);
      expect(detail.expensesCount, 1);
      expect(detail.repaymentsCount, 2);
      expect(detail.hasSettlement, isFalse);
    });
  });

  group('Phase 6 Returns, Losses, Expenses and Repayments Tests', () {
    test('DispatchReturn and DispatchReturnCreate serialization', () {
      final create = DispatchReturnCreate(
        basketTypeId: 'bt-1',
        quantity: 3,
        notes: 'Cliente ausente',
      );
      expect(create.toJson()['quantity'], 3);
      expect(create.toJson()['basket_type_id'], 'bt-1');

      final res = DispatchReturn.fromJson({
        'id': 'ret-1',
        'dispatch_id': 'disp-1',
        'basket_type_id': 'bt-1',
        'basket_type_name': 'Cesta Padrão',
        'production_batch_id': null,
        'quantity': 3,
        'returned_at': '2026-10-11T16:00:00.000Z',
        'notes': 'Cliente ausente',
        'created_at': '2026-10-11T16:00:00.000Z',
      });
      expect(res.id, 'ret-1');
      expect(res.quantity, 3);
      expect(res.basketTypeName, 'Cesta Padrão');
    });

    test('DispatchLoss and DispatchLossCreate serialization with mandatory reason', () {
      final create = DispatchLossCreate(
        basketTypeId: 'bt-1',
        quantity: 1,
        reason: 'Caixa molhou na chuva forte',
      );
      expect(create.toJson()['reason'], 'Caixa molhou na chuva forte');

      final loss = DispatchLoss.fromJson({
        'id': 'loss-1',
        'dispatch_id': 'disp-1',
        'basket_type_id': 'bt-1',
        'basket_type_name': 'Cesta Padrão',
        'production_batch_id': null,
        'quantity': 1,
        'occurred_at': '2026-10-11T15:00:00.000Z',
        'reason': 'Caixa molhou na chuva forte',
        'created_at': '2026-10-11T15:00:00.000Z',
      });
      expect(loss.id, 'loss-1');
      expect(loss.quantity, 1);
      expect(loss.reason, 'Caixa molhou na chuva forte');
    });

    test('DispatchExpense and DispatchExpenseCreate serialization', () {
      final create = DispatchExpenseCreate(
        amountCents: 4500,
        description: 'Combustível van',
        receiptRef: 'NF-9988',
        authorizedBy: 'Gerente João',
      );
      final json = create.toJson();
      expect(json['amount_cents'], 4500);
      expect(json['description'], 'Combustível van');
      expect(json['receipt_ref'], 'NF-9988');
      expect(json['authorized_by'], 'Gerente João');

      final expense = DispatchExpense.fromJson({
        'id': 'exp-1',
        'dispatch_id': 'disp-1',
        'expense_date': '2026-10-11T11:00:00.000Z',
        'amount_cents': 4500,
        'description': 'Combustível van',
        'receipt_ref': 'NF-9988',
        'authorized_by': 'Gerente João',
        'created_at': '2026-10-11T11:00:00.000Z',
      });
      expect(expense.amountCents, 4500);
      expect(expense.description, 'Combustível van');
    });

    test('DispatchRepayment and DispatchRepaymentCreate serialization', () {
      final create = DispatchRepaymentCreate(
        amountCents: 150000,
        paymentMethod: 'CASH',
        receivedBy: 'Caixa Maria',
        notes: 'Primeiro repasse parcial do dia',
      );
      expect(create.toJson()['amount_cents'], 150000);
      expect(create.toJson()['payment_method'], 'CASH');

      final repayment = DispatchRepayment.fromJson({
        'id': 'rep-1',
        'dispatch_id': 'disp-1',
        'repayment_date': '2026-10-11T14:30:00.000Z',
        'amount_cents': 150000,
        'payment_method': 'CASH',
        'received_by': 'Caixa Maria',
        'notes': 'Primeiro repasse parcial do dia',
        'created_at': '2026-10-11T14:30:00.000Z',
      });
      expect(repayment.amountCents, 150000);
      expect(repayment.receivedBy, 'Caixa Maria');
    });
  });

  group('Phase 6 Canonical 4-Term Equation & Segregated Financial Reconciliation Tests', () {
    test('DispatchReconciliation correctly parses canonical physical and financial equation', () {
      final json = {
        'dispatch_id': 'disp-100',
        'dispatch_number': 50,
        'responsible_person_id': 'resp-1',
        'responsible_person_name': 'Marcos Entregador',
        'dispatch_date': '2026-10-11T08:00:00.000Z',
        'dispatch_status': 'OPEN',

        // 4-term physical equation totals:
        // Dispatched (20) = Sold (15) + Returned (3) + Lost (1) + Remaining Custody (1)
        'total_dispatched_qty': 20,
        'total_sold_qty': 15,
        'total_returned_qty': 3,
        'total_lost_qty': 1,
        'total_remaining_custody_qty': 1,
        'basket_discrepancy_qty': 0,

        // Financial equation:
        // Expected Cash (240000) = Cash Sales (200000) + Debt Collected (50000) - Expenses (10000)
        'cash_sales_cents': 200000,
        'direct_company_received_cents': 80000, // Pix/card direct to company, NOT owed by driver
        'credit_sales_cents': 45000,
        'cash_debt_collected_cents': 50000,
        'expenses_cents': 10000,
        'expected_cash_cents': 240000,
        'actual_repaid_cash_cents': 240000,
        'pending_cash_cents': 0,
        'cash_discrepancy_cents': 0,

        'has_basket_discrepancy': false,
        'has_cash_discrepancy': false,

        'items_reconciliation': [
          {
            'basket_type_id': 'bt-1',
            'basket_type_name': 'Cesta Básica Completa',
            'production_batch_id': null,
            'dispatched_qty': 20,
            'sold_qty': 15,
            'returned_qty': 3,
            'lost_qty': 1,
            'remaining_custody_qty': 1,
            'discrepancy_qty': 0,
          }
        ],
        'returns': [],
        'losses': [],
        'expenses': [],
        'repayments': [],
        'latest_settlement': null,
      };

      final rec = DispatchReconciliation.fromJson(json);

      // Verify 4-term physical equation: Dispatched = Sold + Returned + Lost + Remaining
      expect(
        rec.totalDispatchedQty,
        rec.totalSoldQty + rec.totalReturnedQty + rec.totalLostQty + rec.totalRemainingCustodyQty,
      );
      expect(rec.hasBasketDiscrepancy, isFalse);
      expect(rec.basketDiscrepancyQty, 0);

      // Verify segregated financial logic:
      // Direct company received (Pix direct) is segregated from expected driver cash
      expect(rec.directCompanyReceivedCents, 80000);
      expect(rec.expectedCashCents, rec.cashSalesCents + rec.cashDebtCollectedCents - rec.expensesCents);
      expect(rec.actualRepaidCashCents, 240000);
      expect(rec.pendingCashCents, 0);
      expect(rec.hasCashDiscrepancy, isFalse);
    });

    test('DispatchReconciliation identifies divergence and settlement investigation', () {
      final json = {
        'dispatch_id': 'disp-101',
        'dispatch_number': 51,
        'responsible_person_id': 'resp-2',
        'responsible_person_name': 'João Motorista',
        'dispatch_date': '2026-10-11T08:00:00.000Z',
        'dispatch_status': 'PENDING_INVESTIGATION',

        'total_dispatched_qty': 10,
        'total_sold_qty': 8,
        'total_returned_qty': 0,
        'total_lost_qty': 0,
        'total_remaining_custody_qty': 0,
        'basket_discrepancy_qty': 2, // 2 missing baskets!

        'cash_sales_cents': 120000,
        'direct_company_received_cents': 0,
        'credit_sales_cents': 0,
        'cash_debt_collected_cents': 0,
        'expenses_cents': 0,
        'expected_cash_cents': 120000,
        'actual_repaid_cash_cents': 100000,
        'pending_cash_cents': 20000,
        'cash_discrepancy_cents': -20000, // Shortage of R$ 200,00

        'has_basket_discrepancy': true,
        'has_cash_discrepancy': true,

        'items_reconciliation': [],
        'returns': [],
        'losses': [],
        'expenses': [],
        'repayments': [],
        'latest_settlement': {
          'id': 'st-1',
          'dispatch_id': 'disp-101',
          'audited_by': 'Auditor Carlos',
          'settled_at': '2026-10-11T18:00:00.000Z',
          'total_dispatched_qty': 10,
          'total_sold_qty': 8,
          'total_returned_qty': 0,
          'total_lost_qty': 0,
          'total_remaining_custody_qty': 0,
          'basket_discrepancy_qty': 2,
          'expected_cash_cents': 120000,
          'actual_repaid_cash_cents': 100000,
          'cash_discrepancy_cents': -20000,
          'direct_company_received_cents': 0,
          'status': 'PENDING_INVESTIGATION',
          'notes': 'Divergência física e financeira constatada',
          'investigation_notes': 'Aguardando comprovante de depósito bancário',
          'created_at': '2026-10-11T18:00:00.000Z',
          'updated_at': '2026-10-11T18:00:00.000Z',
        },
      };

      final rec = DispatchReconciliation.fromJson(json);
      expect(rec.hasBasketDiscrepancy, isTrue);
      expect(rec.basketDiscrepancyQty, 2);
      expect(rec.hasCashDiscrepancy, isTrue);
      expect(rec.cashDiscrepancyCents, -20000);
      expect(rec.dispatchStatus, 'PENDING_INVESTIGATION');
      expect(rec.latestSettlement, isNotNull);
      expect(rec.latestSettlement!.status, 'PENDING_INVESTIGATION');
      expect(rec.latestSettlement!.investigationNotes, 'Aguardando comprovante de depósito bancário');
    });

    test('SaleCreate supports COMMERCIAL_ROUTE and dispatch linking', () {
      final saleCreate = SaleCreate(
        saleMode: 'COMMERCIAL_ROUTE',
        dispatchId: 'disp-101',
        responsiblePersonId: 'resp-2',
        paymentMode: 'CASH_IMMEDIATE',
        items: [
          SaleItemCreate(
            basketTypeId: 'bt-1',
            quantity: 2,
            unitPriceCents: 15000,
          ),
        ],
      );

      final json = saleCreate.toJson();
      expect(json['sale_mode'], 'COMMERCIAL_ROUTE');
      expect(json['dispatch_id'], 'disp-101');
      expect(json['responsible_person_id'], 'resp-2');
    });

    test('DispatchReconciliation handles negative expected cash when route expenses exceed cash sales', () {
      final json = {
        'dispatch_id': 'disp-exp-over',
        'dispatch_number': 105,
        'responsible_person_id': 'resp-1',
        'responsible_person_name': 'Carlos Motorista',
        'dispatch_date': '2026-10-11T09:00:00.000Z',
        'dispatch_status': 'OPEN',
        'total_dispatched_qty': 5,
        'total_sold_qty': 1,
        'total_returned_qty': 4,
        'total_lost_qty': 0,
        'total_remaining_custody_qty': 0,
        'basket_discrepancy_qty': 0,
        'cash_sales_cents': 5000,
        'direct_company_received_cents': 0,
        'credit_sales_cents': 0,
        'cash_debt_collected_cents': 0,
        'expenses_cents': 12000,
        'expected_cash_cents': -7000,
        'actual_repaid_cash_cents': 0,
        'pending_cash_cents': -7000,
        'cash_discrepancy_cents': 7000,
        'has_basket_discrepancy': false,
        'has_cash_discrepancy': true,
        'items_reconciliation': [],
        'returns': [],
        'losses': [],
        'expenses': [
          {
            'id': 'exp-1',
            'dispatch_id': 'disp-exp-over',
            'expense_date': '2026-10-11T12:00:00.000Z',
            'amount_cents': 12000,
            'description': 'Combustível emergencial',
            'created_at': '2026-10-11T12:00:00.000Z',
          }
        ],
        'repayments': [],
      };

      final rec = DispatchReconciliation.fromJson(json);
      expect(rec.cashSalesCents, 5000);
      expect(rec.expensesCents, 12000);
      expect(rec.expectedCashCents, -7000);
      expect(rec.pendingCashCents, -7000);
      expect(rec.hasCashDiscrepancy, isTrue);

      // Verify that repayment dialog suggestion logic guards against negative pending cash
      String suggestedAmount = '';
      if (rec.pendingCashCents > 0) {
        suggestedAmount = (rec.pendingCashCents / 100.0).toStringAsFixed(2);
      }
      expect(suggestedAmount, isEmpty, reason: 'Must not suggest a negative amount to repay!');

      // Formatted currency handles negative values without error
      final formatted = AppFormatters.formatCurrency(rec.expectedCashCents);
      expect(formatted, contains('70,00'));
    });

    test('Consolidation of duplicate basket items sums quantities and merges notes', () {
      final rawItems = [
        DispatchItemCreate(
          basketTypeId: 'bt-eco',
          quantity: 6,
          unitPriceCents: 10000,
          notes: 'Lote Manha',
        ),
        DispatchItemCreate(
          basketTypeId: 'bt-eco',
          quantity: 6,
          unitPriceCents: 10000,
          notes: 'Lote Tarde',
        ),
        DispatchItemCreate(
          basketTypeId: 'bt-fam',
          quantity: 3,
          unitPriceCents: 15000,
        ),
      ];

      final consolidatedMap = <String, DispatchItemCreate>{};
      for (final it in rawItems) {
        final bId = it.basketTypeId;
        final notes = (it.notes ?? '').trim();
        if (consolidatedMap.containsKey(bId)) {
          final existing = consolidatedMap[bId]!;
          final mergedNotes = [existing.notes, notes].where((s) => s != null && s.isNotEmpty).join('; ');
          consolidatedMap[bId] = DispatchItemCreate(
            basketTypeId: bId,
            quantity: existing.quantity + it.quantity,
            unitPriceCents: it.unitPriceCents > 0 ? it.unitPriceCents : existing.unitPriceCents,
            notes: mergedNotes.isNotEmpty ? mergedNotes : null,
          );
        } else {
          consolidatedMap[bId] = DispatchItemCreate(
            basketTypeId: bId,
            quantity: it.quantity,
            unitPriceCents: it.unitPriceCents,
            notes: notes.isNotEmpty ? notes : null,
          );
        }
      }

      final consolidatedList = consolidatedMap.values.toList();
      expect(consolidatedList.length, 2);

      final eco = consolidatedList.firstWhere((it) => it.basketTypeId == 'bt-eco');
      expect(eco.quantity, 12);
      expect(eco.notes, 'Lote Manha; Lote Tarde');

      final fam = consolidatedList.firstWhere((it) => it.basketTypeId == 'bt-fam');
      expect(fam.quantity, 3);
      expect(fam.notes, isNull);
    });
  });

  group('Phase 6 Localization & AppFormatters Tests', () {
    final l10n = AppLocalizationsPt();

    test('Phase 6 headers and module titles are non-empty Portuguese strings', () {
      expect(l10n.homePhase6Header, 'Fase 6: Expedição, Conferência e Custódia');
      expect(l10n.moduleDispatches, 'Saídas e Conferências');
      expect(l10n.moduleResponsiblePersons, 'Pessoas Responsáveis');
      expect(l10n.dispatchesTitle, 'Saídas Físicas e Conferência');
      expect(l10n.responsiblePersonsTitle, 'Pessoas Responsáveis');
    });

    test('Phase 6 canonical conference equations and notices are localized', () {
      expect(l10n.conferencePhysicalEquationTitle, 'Equação Física de Custódia (4 Termos)');
      expect(l10n.conferencePhysicalEquationBalanced, contains('Sem divergências'));
      expect(l10n.conferencePhysicalEquationDivergent, contains('Divergência Física'));
      expect(l10n.conferenceFinancialBalanced, contains('Repasse integral'));
      expect(l10n.conferenceFinancialDivergent, contains('Divergência Financeira'));
      expect(l10n.conferenceDirectNotice, contains('NÃO são devidos pelo motorista'));
      expect(l10n.conferenceExpenseExceedsNotice, contains('despesas autorizadas superaram as vendas em dinheiro'));
      expect(l10n.dispatchDuplicateBasketConsolidatedNotice, contains('consolidada automaticamente'));
      expect(l10n.dispatchStatusResolved, 'Resolvido');
    });

    test('Phase 6 parameterized labels format correctly', () {
      expect(l10n.dispatchNumber(42), 'Saída #42');
      expect(l10n.conferenceDispatchedLabel(10), '1. Retiradas: 10');
      expect(l10n.conferenceSoldLabel(7), '2. Vendidas: 7');
      expect(l10n.conferenceReturnedLabel(2), '3. Devolvidas Intactas: 2');
      expect(l10n.conferenceLostLabel(1), '4. Avariadas / Perdidas: 1');
      expect(
        l10n.conferenceExpectedCashLabel(AppFormatters.formatCurrency(150000)),
        contains(AppFormatters.formatCurrency(150000)),
      );
    });

    testWidgets('MaterialApp with pt_BR renders Phase 6 localized text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('pt'),
          ],
          locale: const Locale('pt', 'BR'),
          home: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context)!;
              return Scaffold(
                appBar: AppBar(title: Text(loc.dispatchesTitle)),
                body: Column(
                  children: [
                    Text(loc.conferencePhysicalEquationTitle),
                    Text(loc.responsiblePersonCustodyTitle),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saídas Físicas e Conferência'), findsOneWidget);
      expect(find.text('Equação Física de Custódia (4 Termos)'), findsOneWidget);
      expect(find.text('Custódia Atual de Cestas'), findsOneWidget);
    });
  });
}
