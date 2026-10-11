import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/models/product.dart';
import 'package:zm_cesta_basica_client/models/basket_type.dart';

void main() {
  group('Phase 2 Product & Packaging Model Tests', () {
    test('Product fromJson and toJson serialization', () {
      final jsonMap = {
        'id': 'prod-001',
        'name': 'Arroz Branco 5kg',
        'sku': 'ARR-01',
        'barcode': '7891234567890',
        'category': 'ALIMENTACAO',
        'base_unit': 'G',
        'minimum_stock': 50000,
        'cost_price_cents': 2450,
        'sale_price_cents': 2990,
        'notes': 'Marca Premium',
        'is_active': true,
        'created_at': '2026-10-11T00:00:00Z',
        'updated_at': '2026-10-11T00:00:00Z',
        'packagings': [
          {
            'id': 'pack-01',
            'product_id': 'prod-001',
            'name': 'Fardo c/ 6 un (30kg)',
            'quantity_in_base_units': 30000,
            'is_default': true,
            'is_active': true,
          }
        ],
      };

      final prod = Product.fromJson(jsonMap);
      expect(prod.id, equals('prod-001'));
      expect(prod.name, equals('Arroz Branco 5kg'));
      expect(prod.costPriceReais, equals(24.50));
      expect(prod.salePriceReais, equals(29.90));
      expect(prod.packagings.length, equals(1));
      expect(prod.packagings.first.name, equals('Fardo c/ 6 un (30kg)'));
      expect(prod.packagings.first.quantityInBaseUnits, equals(30000));
      expect(prod.packagings.first.isDefault, isTrue);

      final outJson = prod.toJson();
      expect(outJson['name'], equals('Arroz Branco 5kg'));
      expect(outJson['cost_price_cents'], equals(2450));
      expect(outJson['sale_price_cents'], equals(2990));
    });

    test('ProductPackaging fromJson and toJson serialization', () {
      final jsonMap = {
        'id': 'pack-99',
        'product_id': 'prod-002',
        'name': 'Caixa c/ 12',
        'quantity_in_base_units': 12,
        'is_default': false,
        'is_active': true,
      };

      final p = ProductPackaging.fromJson(jsonMap);
      expect(p.id, equals('pack-99'));
      expect(p.productId, equals('prod-002'));
      expect(p.quantityInBaseUnits, equals(12));
      expect(p.isDefault, isFalse);

      final out = p.toJson();
      expect(out['name'], equals('Caixa c/ 12'));
      expect(out['quantity_in_base_units'], equals(12));
    });
  });

  group('Phase 2 BasketType & Recipe Version Model Tests', () {
    test('BasketType with active RecipeVersion parsing', () {
      final jsonMap = {
        'id': 'basket-001',
        'code': 'BASICA_COMPLETA',
        'name': 'Cesta Basica Completa',
        'description': 'Alimentacao e Limpeza',
        'category': 'PADRAO',
        'default_price_cents': 18990,
        'allows_customization': false,
        'tracks_finished_stock': true,
        'is_active': true,
        'active_recipe': {
          'id': 'rec-v1',
          'basket_type_id': 'basket-001',
          'version_number': 1,
          'status': 'ACTIVE',
          'created_at': '2026-10-11T01:00:00Z',
          'notes': 'Versao inicial 2026',
          'items': [
            {
              'id': 'item-01',
              'recipe_version_id': 'rec-v1',
              'product_id': 'prod-001',
              'product_name': 'Arroz 5kg',
              'product_category': 'ALIMENTACAO',
              'product_base_unit': 'G',
              'quantity_in_base_units': 5000,
              'section': 'ALIMENTACAO',
              'is_required': true,
            },
            {
              'id': 'item-02',
              'recipe_version_id': 'rec-v1',
              'product_id': 'prod-003',
              'product_name': 'Sabao em Po 1kg',
              'product_category': 'LIMPEZA',
              'product_base_unit': 'G',
              'quantity_in_base_units': 1000,
              'section': 'LIMPEZA',
              'is_required': true,
            },
          ],
        },
      };

      final bt = BasketType.fromJson(jsonMap);
      expect(bt.id, equals('basket-001'));
      expect(bt.code, equals('BASICA_COMPLETA'));
      expect(bt.defaultPriceReais, equals(189.90));
      expect(bt.activeRecipe, isNotNull);

      final recipe = bt.activeRecipe!;
      expect(recipe.versionNumber, equals(1));
      expect(recipe.status, equals('ACTIVE'));
      expect(recipe.items.length, equals(2));

      final alimentacao = recipe.items.where((it) => it.section == 'ALIMENTACAO').toList();
      final limpeza = recipe.items.where((it) => it.section == 'LIMPEZA').toList();
      expect(alimentacao.length, equals(1));
      expect(alimentacao.first.productName, equals('Arroz 5kg'));
      expect(limpeza.length, equals(1));
      expect(limpeza.first.productName, equals('Sabao em Po 1kg'));
    });
  });
}
