import 'package:flutter_test/flutter_test.dart';
import '../_archive/models/production_batch.dart';

void main() {
  group('Phase 4 ProductionBatch Model Tests', () {
    test('ProductionBatch fromJson parses quantityDisassembled and isDirectSale', () {
      final jsonMap = {
        'id': 'batch-001',
        'batch_number': 101,
        'basket_type_id': 'bt-001',
        'basket_type_name': 'Cesta Tradicional',
        'recipe_version_id': 'recipe-001',
        'recipe_version_number': 2,
        'quantity_produced': 10,
        'quantity_disassembled': 3,
        'current_batch_stock': 7,
        'status': 'CONFIRMED',
        'is_custom': false,
        'is_direct_sale': true,
        'custom_description': null,
        'occurred_at': '2026-10-11T12:00:00Z',
        'unit_cost_cents': 4500,
        'total_cost_cents': 45000,
        'canceled_at': null,
        'cancellation_reason': null,
        'notes': 'Lote piloto',
        'items': [
          {
            'id': 'item-001',
            'product_id': 'prod-001',
            'product_name': 'Arroz Agulhinha',
            'product_base_unit': 'G',
            'section': 'ALIMENTACAO',
            'quantity_consumed_base_units': 50000,
            'unit_cost_microcents': 60000000,
            'total_cost_cents': 30000,
          }
        ],
      };

      final batch = ProductionBatch.fromJson(jsonMap);
      expect(batch.id, equals('batch-001'));
      expect(batch.batchNumber, equals(101));
      expect(batch.quantityProduced, equals(10));
      expect(batch.quantityDisassembled, equals(3));
      expect(batch.currentBatchStock, equals(7));
      expect(batch.status, equals('CONFIRMED'));
      expect(batch.isCustom, isFalse);
      expect(batch.isDirectSale, isTrue);
      expect(batch.items.length, equals(1));

      final item = batch.items.first;
      expect(item.productName, equals('Arroz Agulhinha'));
      expect(item.quantityConsumedBaseUnits, equals(50000));
      expect(item.unitCostMicrocents, equals(60000000));
      expect(item.totalCostCents, equals(30000));
    });

    test('ProductionBatch fromJson defaults quantityDisassembled and isDirectSale when missing', () {
      final jsonMap = {
        'id': 'batch-002',
        'batch_number': 102,
        'basket_type_id': 'bt-002',
        'basket_type_name': 'Cesta Econômica',
        'quantity_produced': 5,
        'current_batch_stock': 5,
        'status': 'CONFIRMED',
        'occurred_at': '2026-10-11T12:00:00Z',
        'unit_cost_cents': 3000,
        'total_cost_cents': 15000,
      };

      final batch = ProductionBatch.fromJson(jsonMap);
      expect(batch.quantityDisassembled, equals(0));
      expect(batch.isDirectSale, isFalse);
      expect(batch.isCustom, isFalse);
    });

    test('ProductionPreview fromJson parses preview response', () {
      final jsonMap = {
        'can_produce': true,
        'basket_type_id': 'bt-001',
        'basket_type_name': 'Cesta Família',
        'recipe_version_number': 1,
        'quantity_produced': 4,
        'estimated_unit_cost_cents': 5000,
        'estimated_total_cost_cents': 20000,
        'items': [
          {
            'product_id': 'prod-001',
            'product_name': 'Feijão Carioca',
            'product_base_unit': 'G',
            'section': 'ALIMENTACAO',
            'quantity_per_basket': 2000,
            'quantity_required': 8000,
            'current_stock': 20000,
            'is_sufficient': true,
            'missing_quantity': 0,
            'unit_cost_microcents': 75000000,
            'total_cost_cents': 6000,
          }
        ],
        'missing_items': [],
      };

      final preview = ProductionPreview.fromJson(jsonMap);
      expect(preview.canProduce, isTrue);
      expect(preview.quantityProduced, equals(4));
      expect(preview.estimatedTotalCostCents, equals(20000));
      expect(preview.items.length, equals(1));
      expect(preview.missingItems, isEmpty);
    });
  });
}
