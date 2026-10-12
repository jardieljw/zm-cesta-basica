import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/models/dashboard.dart';
import 'package:zm_cesta_basica_client/models/report.dart';

void main() {
  group('Phase 8 Dashboard Models Unit Tests', () {
    test('FilterInfo fromJson parses standard fields and defaults', () {
      final json = {
        'filter_type': 'today',
        'start_date': '2026-10-12T00:00:00.000Z',
        'end_date': '2026-10-12T23:59:59.999Z',
        'label': 'Hoje (12/10/2026)',
      };

      final filter = FilterInfo.fromJson(json);
      expect(filter.filterType, 'today');
      expect(filter.startDate, isNotNull);
      expect(filter.endDate, isNotNull);
      expect(filter.label, 'Hoje (12/10/2026)');

      final emptyFilter = FilterInfo.fromJson({});
      expect(emptyFilter.filterType, 'today');
      expect(emptyFilter.startDate, isNull);
      expect(emptyFilter.endDate, isNull);
      expect(emptyFilter.label, '');
    });

    test('BasketTypeCount fromJson parses correctly', () {
      final json = {
        'basket_type_id': 'bt-01',
        'basket_type_name': 'Cesta Econômica 15kg',
        'count': 42,
        'total_cents': 420000,
      };

      final btc = BasketTypeCount.fromJson(json);
      expect(btc.basketTypeId, 'bt-01');
      expect(btc.basketTypeName, 'Cesta Econômica 15kg');
      expect(btc.count, 42);
      expect(btc.totalCents, 420000);
    });

    test('LowStockItem fromJson parses correctly', () {
      final json = {
        'id': 'prod-01',
        'name': 'Arroz Tipo 1 5kg',
        'sku': 'ARR-005',
        'base_unit': 'un',
        'current_stock': 12,
        'min_stock': 50,
        'difference': 38,
      };

      final item = LowStockItem.fromJson(json);
      expect(item.id, 'prod-01');
      expect(item.name, 'Arroz Tipo 1 5kg');
      expect(item.sku, 'ARR-005');
      expect(item.baseUnit, 'un');
      expect(item.currentStock, 12);
      expect(item.minStock, 50);
      expect(item.difference, 38);
    });

    test('BasketStockItem fromJson parses correctly', () {
      final json = {
        'basket_type_id': 'bt-02',
        'name': 'Cesta Família 22kg',
        'code': 'CF-22',
        'stock_store': 35,
        'stock_transit': 15,
        'total_stock': 50,
      };

      final stock = BasketStockItem.fromJson(json);
      expect(stock.basketTypeId, 'bt-02');
      expect(stock.name, 'Cesta Família 22kg');
      expect(stock.code, 'CF-22');
      expect(stock.stockStore, 35);
      expect(stock.stockTransit, 15);
      expect(stock.totalStock, 50);
    });

    test('PendingDivergenceItem fromJson parses correctly', () {
      final json = {
        'dispatch_id': 'disp-01',
        'dispatch_number': 105,
        'responsible_person_name': 'Carlos Motorista',
        'settled_at': '2026-10-12T18:30:00.000Z',
        'basket_discrepancy_qty': 2,
        'cash_discrepancy_cents': 18000,
        'direct_company_received_cents': 0,
        'status': 'PENDING_INVESTIGATION',
        'notes': '2 cestas não prestadas contas',
        'investigation_notes': 'Aguardando comprovante PIX',
      };

      final div = PendingDivergenceItem.fromJson(json);
      expect(div.dispatchId, 'disp-01');
      expect(div.dispatchNumber, 105);
      expect(div.responsiblePersonName, 'Carlos Motorista');
      expect(div.basketDiscrepancyQty, 2);
      expect(div.cashDiscrepancyCents, 18000);
      expect(div.status, 'PENDING_INVESTIGATION');
      expect(div.notes, '2 cestas não prestadas contas');
      expect(div.investigationNotes, 'Aguardando comprovante PIX');
    });

    test('DashboardBatchRecord fromJson parses correctly', () {
      final json = {
        'id': 'batch-01',
        'batch_number': 42,
        'basket_type_name': 'Cesta Econômica',
        'quantity_produced': 20,
        'unit_cost_cents': 6500,
        'total_cost_cents': 130000,
        'is_custom': false,
        'status': 'COMPLETED',
        'occurred_at': '2026-10-12T09:15:00.000Z',
      };

      final batch = DashboardBatchRecord.fromJson(json);
      expect(batch.id, 'batch-01');
      expect(batch.batchNumber, 42);
      expect(batch.basketTypeName, 'Cesta Econômica');
      expect(batch.quantityProduced, 20);
      expect(batch.unitCostCents, 6500);
      expect(batch.totalCostCents, 130000);
      expect(batch.isCustom, isFalse);
      expect(batch.status, 'COMPLETED');
    });

    test('DashboardSaleRecord fromJson parses correctly', () {
      final json = {
        'id': 'sale-01',
        'sale_number': 88,
        'customer_name': 'Padaria Sol',
        'sale_mode': 'DIRECT_STORE',
        'payment_mode': 'CASH_IMMEDIATE',
        'payment_status': 'PAID',
        'total_amount_cents': 25000,
        'sale_date': '2026-10-12T11:00:00.000Z',
        'status': 'COMPLETED',
      };

      final sale = DashboardSaleRecord.fromJson(json);
      expect(sale.id, 'sale-01');
      expect(sale.saleNumber, 88);
      expect(sale.customerName, 'Padaria Sol');
      expect(sale.saleMode, 'DIRECT_STORE');
      expect(sale.paymentMode, 'CASH_IMMEDIATE');
      expect(sale.paymentStatus, 'PAID');
      expect(sale.totalAmountCents, 25000);
      expect(sale.status, 'COMPLETED');
    });

    test('DashboardDispatchRecord fromJson parses correctly', () {
      final json = {
        'id': 'disp-01',
        'dispatch_number': 12,
        'responsible_person_name': 'João Entregador',
        'dispatch_date': '2026-10-12T07:30:00.000Z',
        'total_baskets': 15,
        'status': 'DELIVERED',
      };

      final disp = DashboardDispatchRecord.fromJson(json);
      expect(disp.id, 'disp-01');
      expect(disp.dispatchNumber, 12);
      expect(disp.responsiblePersonName, 'João Entregador');
      expect(disp.totalBaskets, 15);
      expect(disp.status, 'DELIVERED');
    });

    test('DashboardReceivableRecord fromJson parses correctly', () {
      final json = {
        'id': 'rec-01',
        'sale_number': 54,
        'customer_name': 'Mercadinho São José',
        'due_date': '2026-10-10T00:00:00.000Z',
        'original_amount_cents': 150000,
        'paid_amount_cents': 50000,
        'balance_cents': 100000,
        'status': 'PARTIAL',
        'is_overdue': true,
      };

      final rec = DashboardReceivableRecord.fromJson(json);
      expect(rec.id, 'rec-01');
      expect(rec.saleNumber, 54);
      expect(rec.customerName, 'Mercadinho São José');
      expect(rec.originalAmountCents, 150000);
      expect(rec.paidAmountCents, 50000);
      expect(rec.balanceCents, 100000);
      expect(rec.status, 'PARTIAL');
      expect(rec.isOverdue, isTrue);
    });

    test('DashboardPayableRecord fromJson parses correctly', () {
      final json = {
        'id': 'pay-01',
        'payable_number': 22,
        'beneficiary': 'Distribuidora Grãos Ltda',
        'category': 'INSUMOS_ALIMENTICIOS',
        'nature': 'OPERATIONAL',
        'due_date': '2026-10-08T00:00:00.000Z',
        'original_amount_cents': 300000,
        'paid_amount_cents': 0,
        'balance_cents': 300000,
        'status': 'OPEN',
        'is_overdue': true,
      };

      final pay = DashboardPayableRecord.fromJson(json);
      expect(pay.id, 'pay-01');
      expect(pay.payableNumber, 22);
      expect(pay.beneficiary, 'Distribuidora Grãos Ltda');
      expect(pay.category, 'INSUMOS_ALIMENTICIOS');
      expect(pay.balanceCents, 300000);
      expect(pay.isOverdue, isTrue);
    });

    test('DashboardCashRecord fromJson parses correctly', () {
      final json = {
        'id': 'cash-01',
        'entry_type': 'CREDIT',
        'amount_cents': 85000,
        'category': 'VENDAS',
        'nature': 'OPERATIONAL',
        'description': 'Recebimento Venda #88',
        'occurred_at': '2026-10-12T11:05:00.000Z',
        'source_type': 'SALE',
      };

      final cash = DashboardCashRecord.fromJson(json);
      expect(cash.id, 'cash-01');
      expect(cash.entryType, 'CREDIT');
      expect(cash.amountCents, 85000);
      expect(cash.category, 'VENDAS');
      expect(cash.description, 'Recebimento Venda #88');
    });

    test('Full DashboardSummary parses complex payload', () {
      final json = {
        'filter_info': {
          'filter_type': 'today',
          'label': 'Hoje (12/10/2026)',
        },
        'production': {
          'assembled_count': 30,
          'by_basket_type': [
            {'basket_type_id': 'bt-1', 'basket_type_name': 'Econômica', 'count': 30, 'total_cents': 0}
          ],
          'batches': [],
        },
        'sales': {
          'sold_count': 15,
          'total_sold_cents': 150000,
          'by_basket_type': [],
          'sales': [],
        },
        'dispatches': {
          'dispatched_count': 25,
          'by_basket_type': [],
          'responsible_unremitted_cents': 50000,
          'pending_divergences_count': 1,
          'pending_divergences': [],
          'dispatches': [],
        },
        'inventory': {
          'total_products_count': 18,
          'low_stock_products_count': 2,
          'low_stock_items': [],
          'basket_stock': [],
        },
        'financial': {
          'receivables_open_cents': 40000,
          'receivables_overdue_cents': 10000,
          'effective_received_cents': 100000,
          'payables_open_cents': 60000,
          'payables_overdue_cents': 20000,
          'effective_paid_cents': 50000,
          'cash_inflow_cents': 120000,
          'cash_outflow_cents': 70000,
          'net_cash_flow_cents': 50000,
          'current_treasury_balance_cents': 250000,
          'projected_inflow_cents': 140000,
          'projected_outflow_cents': 80000,
          'projected_treasury_balance_cents': 310000,
          'receivables_records': [],
          'payables_records': [],
          'cash_records': [],
        },
      };

      final summary = DashboardSummary.fromJson(json);
      expect(summary.filterInfo.label, 'Hoje (12/10/2026)');
      expect(summary.production.assembledCount, 30);
      expect(summary.sales.soldCount, 15);
      expect(summary.sales.totalSoldCents, 150000);
      expect(summary.dispatches.dispatchedCount, 25);
      expect(summary.dispatches.pendingDivergencesCount, 1);
      expect(summary.inventory.lowStockProductsCount, 2);
      expect(summary.financial.effectiveReceivedCents, 100000);
      expect(summary.financial.currentTreasuryBalanceCents, 250000);
      expect(summary.financial.projectedTreasuryBalanceCents, 310000);
    });
  });

  group('Phase 8 Report Models Unit Tests', () {
    test('ReportResponse and ReportMetadata parses correctly', () {
      final json = {
        'metadata': {
          'report_type': 'sales-dispatches',
          'title': 'Relatório de Vendas e Saídas de Cestas',
          'company_name': 'ZM Cesta Básica',
          'generated_at': '2026-10-12T12:00:00.000Z',
          'filter_info': {
            'filter_type': 'today',
            'label': 'Hoje',
          },
          'total_rows': 2,
        },
        'headers': ['Venda #', 'Cliente', 'Valor Total'],
        'columns': ['sale_number', 'customer_name', 'total_amount_cents'],
        'rows': [
          {'sale_number': 101, 'customer_name': 'Cliente A', 'total_amount_cents': 15000},
          {'sale_number': 102, 'customer_name': 'Cliente B', 'total_amount_cents': 25000},
        ],
        'totals': {
          'total_amount_cents': 40000,
        },
      };

      final report = ReportResponse.fromJson(json);
      expect(report.metadata.reportType, 'sales-dispatches');
      expect(report.metadata.title, 'Relatório de Vendas e Saídas de Cestas');
      expect(report.metadata.companyName, 'ZM Cesta Básica');
      expect(report.metadata.totalRows, 2);
      expect(report.headers.length, 3);
      expect(report.columns.length, 3);
      expect(report.rows.length, 2);
      expect(report.totals['total_amount_cents'], 40000);
    });
  });
}
