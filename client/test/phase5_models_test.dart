import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/models/customer.dart';
import 'package:zm_cesta_basica_client/models/sale.dart';
import 'package:zm_cesta_basica_client/models/sales_receivable.dart';
import 'package:zm_cesta_basica_client/utils/api_error_mapper.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations_pt.dart';

void main() {
  group('Phase 5 Customer Model Tests', () {
    test('Customer fromJson and toJson serialization', () {
      final json = {
        'id': 'cust-123',
        'name': 'Mercadinho da Esquina',
        'document_cpf_cnpj': '11.222.333/0001-44',
        'phone': '(11) 98888-7777',
        'address': 'Rua Flores, 100',
        'credit_limit_cents': 50000,
        'is_active': true,
        'notes': 'Cliente bom pagador',
        'current_debt_cents': 20000,
        'created_at': '2026-10-11T12:00:00.000Z',
        'updated_at': '2026-10-11T12:00:00.000Z',
      };

      final customer = Customer.fromJson(json);
      expect(customer.id, 'cust-123');
      expect(customer.name, 'Mercadinho da Esquina');
      expect(customer.creditLimitCents, 50000);
      expect(customer.currentDebtCents, 20000);
      expect(customer.availableCreditCents, 30000);

      final outJson = customer.toJson();
      expect(outJson['name'], 'Mercadinho da Esquina');
      expect(outJson['credit_limit_cents'], 50000);
    });

    test('CustomerStatementResponse fromJson parsing', () {
      final json = {
        'customer': {
          'id': 'cust-123',
          'name': 'Mercadinho',
          'credit_limit_cents': 0,
          'is_active': true,
          'current_debt_cents': 15000,
          'created_at': '2026-10-11T10:00:00.000Z',
          'updated_at': '2026-10-11T10:00:00.000Z',
        },
        'credit_limit_cents': 0,
        'current_debt_cents': 15000,
        'available_credit_cents': null,
        'entries': [
          {
            'id': 'entry-1',
            'occurred_at': '2026-10-11T10:30:00.000Z',
            'entry_type': 'SALE_CREDIT',
            'description': 'Venda #101 (CREDIT_TERM)',
            'amount_cents': 20000,
            'reference_id': 'sale-101',
          },
          {
            'id': 'entry-2',
            'occurred_at': '2026-10-11T11:00:00.000Z',
            'entry_type': 'RECEIVABLE_PAYMENT',
            'description': 'Pagamento via PIX',
            'amount_cents': 5000,
            'reference_id': 'rec-101',
          },
        ],
      };

      final statement = CustomerStatementResponse.fromJson(json);
      expect(statement.customer.name, 'Mercadinho');
      expect(statement.currentDebtCents, 15000);
      expect(statement.availableCreditCents, isNull);
      expect(statement.entries.length, 2);
      expect(statement.entries.first.amountCents, 20000);
    });
  });

  group('Phase 5 Sale & SaleItem Model Tests', () {
    test('Sale fromJson and toJson parsing', () {
      final json = {
        'id': 'sale-uuid-1',
        'sale_number': 105,
        'customer_id': 'cust-123',
        'customer_name': 'Mercadinho da Esquina',
        'status': 'CONFIRMED',
        'sale_mode': 'DIRECT_STORE',
        'payment_mode': 'CREDIT_TERM',
        'payment_status': 'PENDING',
        'sale_date': '2026-10-11T14:00:00.000Z',
        'total_amount_cents': 24000,
        'total_cost_cents': 18000,
        'gross_margin_cents': 6000,
        'receivable_id': 'rec-uuid-1',
        'receivable_due_date': '2026-11-10T14:00:00.000Z',
        'receivable_balance_cents': 24000,
        'receivable_status': 'OPEN',
        'items': [
          {
            'id': 'item-1',
            'basket_type_id': 'bt-1',
            'basket_type_name': 'Cesta Básica Completa',
            'production_batch_id': 'batch-99',
            'quantity': 2,
            'unit_price_cents': 12000,
            'discount_cents': 0,
            'total_cents': 24000,
            'unit_cost_cents': 9000,
            'total_cost_cents': 18000,
          }
        ],
      };

      final sale = Sale.fromJson(json);
      expect(sale.saleNumber, 105);
      expect(sale.paymentMode, 'CREDIT_TERM');
      expect(sale.paymentStatus, 'PENDING');
      expect(sale.totalAmountCents, 24000);
      expect(sale.grossMarginCents, 6000);
      expect(sale.receivableId, 'rec-uuid-1');
      expect(sale.items.length, 1);
      expect(sale.items.first.unitCostCents, 9000);
    });

    test('SaleCreate DTO serialization', () {
      final create = SaleCreate(
        customerId: 'cust-1',
        paymentMode: 'CREDIT_TERM',
        allowCreditOverride: true,
        items: [
          SaleItemCreate(
            basketTypeId: 'bt-1',
            quantity: 3,
            unitPriceCents: 11000,
            discountCents: 500,
            assembleOnDemand: true,
          ),
        ],
      );

      final json = create.toJson();
      expect(json['customer_id'], 'cust-1');
      expect(json['payment_mode'], 'CREDIT_TERM');
      expect(json['allow_credit_override'], isTrue);
      final items = json['items'] as List<dynamic>;
      expect(items.first['assemble_on_demand'], isTrue);
      expect(items.first['discount_cents'], 500);
    });
  });

  group('Phase 5 SalesReceivable & Payment Model Tests', () {
    test('SalesReceivable fromJson parsing', () {
      final json = {
        'id': 'rec-1',
        'sale_id': 'sale-1',
        'sale_number': 42,
        'customer_id': 'cust-1',
        'customer_name': 'Cliente Teste',
        'due_date': '2026-11-15T00:00:00.000Z',
        'original_amount_cents': 30000,
        'paid_amount_cents': 10000,
        'balance_cents': 20000,
        'status': 'PARTIAL',
        'is_overdue': false,
        'created_at': '2026-10-11T00:00:00.000Z',
        'updated_at': '2026-10-11T00:00:00.000Z',
        'payments_count': 1,
        'payments': [
          {
            'id': 'pay-1',
            'receivable_id': 'rec-1',
            'payment_date': '2026-10-11T12:00:00.000Z',
            'amount_cents': 10000,
            'payment_method': 'PIX',
            'status': 'CONFIRMED',
            'notes': 'Parcial via chave CNPJ',
            'created_at': '2026-10-11T12:00:00.000Z',
          }
        ],
      };

      final rec = SalesReceivable.fromJson(json);
      expect(rec.saleNumber, 42);
      expect(rec.customerName, 'Cliente Teste');
      expect(rec.originalAmountCents, 30000);
      expect(rec.paidAmountCents, 10000);
      expect(rec.balanceCents, 20000);
      expect(rec.status, 'PARTIAL');
      expect(rec.payments.length, 1);
      expect(rec.payments.first.amountCents, 10000);
    });
  });

  group('Phase 5 ApiErrorMapper Localization Tests', () {
    test('maps stable error_code CUSTOMER_DOCUMENT_CONFLICT and CREDIT_LIMIT_EXCEEDED', () {
      final l10n = AppLocalizationsPt();

      final conflictEx = ApiException(
        statusCode: 409,
        errorCode: 'CUSTOMER_DOCUMENT_CONFLICT',
        message: 'Document already registered',
      );
      expect(
        ApiErrorMapper.toLocalizedMessage(conflictEx, l10n),
        l10n.errorCustomerDocumentConflict,
      );

      final creditEx = ApiException(
        statusCode: 409,
        errorCode: 'CREDIT_LIMIT_EXCEEDED',
        message: 'Credit limit exceeded',
      );
      expect(
        ApiErrorMapper.toLocalizedMessage(creditEx, l10n),
        l10n.errorCreditLimitExceeded,
      );
    });
  });
}
