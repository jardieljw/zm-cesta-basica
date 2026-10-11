import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/models/purchase.dart';
import 'package:zm_cesta_basica_client/models/inventory_movement.dart';
import 'package:zm_cesta_basica_client/models/stock_summary.dart';
import 'package:zm_cesta_basica_client/models/stock_adjustment.dart';

void main() {
  group('Phase 3 Purchase Model Tests', () {
    test('Purchase and PurchaseItem fromJson and toJson serialization', () {
      final jsonMap = {
        'id': 'purch-001',
        'purchase_number': 12,
        'status': 'CONFIRMED',
        'purchase_date': '2026-10-11T10:00:00Z',
        'supplier_name': 'Atacadista Central Ltda',
        'total_amount_cents': 24000,
        'notes': 'NF-e 45892',
        'created_at': '2026-10-11T10:00:00Z',
        'items': [
          {
            'id': 'item-001',
            'purchase_id': 'purch-001',
            'product_id': 'prod-001',
            'product_name': 'Arroz Agulhinha 5kg',
            'product_base_unit': 'G',
            'packaging_id': 'pack-001',
            'packaging_name': 'Fardo c/ 6 un (30kg)',
            'packages_count': 4.0,
            'quantity_in_base_units': 120000,
            'unit_price_cents': 6000,
            'total_price_cents': 24000,
          }
        ],
      };

      final purchase = Purchase.fromJson(jsonMap);
      expect(purchase.id, equals('purch-001'));
      expect(purchase.purchaseNumber, equals(12));
      expect(purchase.status, equals('CONFIRMED'));
      expect(purchase.totalAmountReais, equals(240.0));
      expect(purchase.items.length, equals(1));

      final item = purchase.items.first;
      expect(item.productName, equals('Arroz Agulhinha 5kg'));
      expect(item.packagesCount, equals(4.0));
      expect(item.quantityInBaseUnits, equals(120000));
      expect(item.unitPriceReais, equals(60.0));
      expect(item.totalPriceReais, equals(240.0));

      final outJson = purchase.toJson();
      expect(outJson['purchase_number'], equals(12));
      expect(outJson['total_amount_cents'], equals(24000));
      expect(outJson['status'], equals('CONFIRMED'));
    });
  });

  group('Phase 3 Inventory Movement & Ledger Tests', () {
    test('InventoryMovement parsing and delta evaluation', () {
      final jsonMap = {
        'id': 'mov-100',
        'item_type': 'PRODUCT',
        'product_id': 'prod-001',
        'product_name': 'Feijao Carioca 1kg',
        'basket_type_id': null,
        'basket_type_name': null,
        'production_batch_id': 'batch-xyz',
        'movement_type': 'PURCHASE',
        'quantity_delta': 50000,
        'source_type': 'PURCHASE',
        'source_id': 'purch-001',
        'reversal_of_id': null,
        'occurred_at': '2026-10-11T12:00:00Z',
        'reason': 'Compra #12',
        'running_balance': 50000,
      };

      final mov = InventoryMovement.fromJson(jsonMap);
      expect(mov.id, equals('mov-100'));
      expect(mov.productionBatchId, equals('batch-xyz'));
      expect(mov.movementType, equals('PURCHASE'));
      expect(mov.quantityDelta, equals(50000));
      expect(mov.runningBalance, equals(50000));

      final out = mov.toJson();
      expect(out['quantity_delta'], equals(50000));
      expect(out['production_batch_id'], equals('batch-xyz'));
      expect(out['source_type'], equals('PURCHASE'));
    });
  });

  group('Phase 3 ProductStockSummary Tests', () {
    test('ProductStockSummary parsing and minimum stock logic', () {
      final jsonMap = {
        'product_id': 'prod-002',
        'product_name': 'Oleo de Soja 900ml',
        'sku': 'OLE-900',
        'barcode': '7891234560001',
        'category': 'ALIMENTACAO',
        'base_unit': 'ML',
        'current_stock': 4500,
        'minimum_stock': 9000,
        'is_below_minimum': true,
        'cost_price_cents': 550,
        'sale_price_cents': 720,
      };

      final summary = ProductStockSummary.fromJson(jsonMap);
      expect(summary.productName, equals('Oleo de Soja 900ml'));
      expect(summary.currentStock, equals(4500));
      expect(summary.minimumStock, equals(9000));
      expect(summary.isBelowMinimum, isTrue);
      expect(summary.costPriceReais, equals(5.50));
      expect(summary.salePriceReais, equals(7.20));
    });
  });

  group('Phase 3 Stock Adjustment Model Tests', () {
    test('StockAdjustmentRequest and Response', () {
      final request = StockAdjustmentRequest(
        itemType: 'PRODUCT',
        productId: 'prod-001',
        adjustmentType: 'OUT',
        quantityDelta: 5,
        reason: 'Avaria em estoque',
      );

      final reqJson = request.toJson();
      expect(reqJson['adjustment_type'], equals('OUT'));
      expect(reqJson['quantity_delta'], equals(5));
      expect(reqJson['reason'], equals('Avaria em estoque'));

      final respJson = {
        'movement_id': 'mov-200',
        'item_type': 'PRODUCT',
        'product_id': 'prod-001',
        'product_name': 'Arroz 5kg',
        'basket_type_id': null,
        'basket_type_name': null,
        'adjustment_type': 'OUT',
        'movement_type': 'ADJUSTMENT_OUT',
        'previous_stock': 30,
        'quantity_delta': -5,
        'new_stock': 25,
        'reason': 'Avaria em estoque',
        'occurred_at': '2026-10-11T13:00:00Z',
      };

      final response = StockAdjustmentResponse.fromJson(respJson);
      expect(response.movementId, equals('mov-200'));
      expect(response.previousStock, equals(30));
      expect(response.quantityDelta, equals(-5));
      expect(response.newStock, equals(25));
    });
  });
}
