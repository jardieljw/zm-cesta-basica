import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/models/account_payable.dart';
import 'package:zm_cesta_basica_client/models/cash_flow_entry.dart';
import 'package:zm_cesta_basica_client/models/financial_account.dart';
import 'package:zm_cesta_basica_client/models/sales_receivable.dart';
import 'package:zm_cesta_basica_client/services/payable_service.dart';
import 'package:zm_cesta_basica_client/services/receivable_service.dart';

void main() {
  group('Phase 7 FinancialAccount Model Tests', () {
    test('FinancialAccount fromJson and toJson serialization', () {
      final json = {
        'id': 'acc-001',
        'name': 'Banco do Brasil - CC',
        'account_type': 'BANK',
        'bank_name': 'Banco do Brasil',
        'account_number': '12345-6',
        'initial_balance_cents': 100000,
        'current_balance_cents': 250000,
        'is_active': true,
        'is_default': false,
        'notes': 'Conta corrente operacional',
        'created_at': '2026-10-11T10:00:00.000Z',
        'updated_at': '2026-10-11T12:00:00.000Z',
      };

      final account = FinancialAccount.fromJson(json);
      expect(account.id, 'acc-001');
      expect(account.name, 'Banco do Brasil - CC');
      expect(account.accountType, 'BANK');
      expect(account.bankName, 'Banco do Brasil');
      expect(account.accountNumber, '12345-6');
      expect(account.initialBalanceCents, 100000);
      expect(account.currentBalanceCents, 250000);
      expect(account.isActive, isTrue);
      expect(account.isDefault, isFalse);
      expect(account.notes, 'Conta corrente operacional');

      final outJson = account.toJson();
      expect(outJson['id'], 'acc-001');
      expect(outJson['current_balance_cents'], 250000);
      expect(outJson['account_type'], 'BANK');
      expect(outJson['bank_name'], 'Banco do Brasil');
    });

    test('FinancialAccount fromJson defaults when optional fields are omitted', () {
      final json = {
        'id': 'acc-default',
        'name': 'Caixa Físico',
        'created_at': '2026-10-11T10:00:00.000Z',
        'updated_at': '2026-10-11T10:00:00.000Z',
      };

      final account = FinancialAccount.fromJson(json);
      expect(account.accountType, 'CASH');
      expect(account.bankName, isNull);
      expect(account.accountNumber, isNull);
      expect(account.initialBalanceCents, 0);
      expect(account.currentBalanceCents, 0);
      expect(account.isActive, isTrue);
      expect(account.isDefault, isFalse);
      expect(account.notes, isNull);
    });

    test('FinancialAccountCreate serialization', () {
      final create = FinancialAccountCreate(
        name: 'Cofre Loja',
        accountType: 'CASH',
        initialBalanceCents: 50000,
        isDefault: true,
        notes: 'Fundo de troco',
      );

      final json = create.toJson();
      expect(json['name'], 'Cofre Loja');
      expect(json['account_type'], 'CASH');
      expect(json['initial_balance_cents'], 50000);
      expect(json['is_default'], isTrue);
      expect(json['notes'], 'Fundo de troco');
      expect(json.containsKey('bank_name'), isFalse);
    });

    test('FinancialAccountUpdate serialization', () {
      final update = FinancialAccountUpdate(
        name: 'Banco Itaú Alterado',
        bankName: 'Itaú Unibanco',
        notes: 'Agência atualizada',
      );

      final json = update.toJson();
      expect(json['name'], 'Banco Itaú Alterado');
      expect(json['bank_name'], 'Itaú Unibanco');
      expect(json['notes'], 'Agência atualizada');
      expect(json.containsKey('account_number'), isFalse);
      expect(json.containsKey('is_active'), isFalse);
    });
  });

  group('Phase 7 CashFlowEntry & Treasury Model Tests', () {
    test('CashFlowEntry fromJson parsing', () {
      final json = {
        'id': 'entry-01',
        'account_id': 'acc-001',
        'account_name': 'Banco do Brasil',
        'entry_type': 'CREDIT',
        'amount_cents': 75000,
        'category': 'VENDAS',
        'nature': 'BUSINESS',
        'description': 'Recebimento de duplicata #100',
        'source_type': 'RECEIVABLE_PAYMENT',
        'source_id': 'pay-rec-01',
        'payment_method': 'PIX',
        'occurred_at': '2026-10-11T15:30:00.000Z',
        'reversal_of_id': null,
        'is_reversal': false,
        'notes': 'Cliente pagou via chave CNPJ',
        'created_at': '2026-10-11T15:30:05.000Z',
      };

      final entry = CashFlowEntry.fromJson(json);
      expect(entry.id, 'entry-01');
      expect(entry.accountId, 'acc-001');
      expect(entry.accountName, 'Banco do Brasil');
      expect(entry.entryType, 'CREDIT');
      expect(entry.amountCents, 75000);
      expect(entry.category, 'VENDAS');
      expect(entry.nature, 'BUSINESS');
      expect(entry.description, 'Recebimento de duplicata #100');
      expect(entry.sourceType, 'RECEIVABLE_PAYMENT');
      expect(entry.sourceId, 'pay-rec-01');
      expect(entry.paymentMethod, 'PIX');
      expect(entry.isReversal, isFalse);
      expect(entry.reversalOfId, isNull);
    });

    test('CashFlowEntry reversal fromJson parsing', () {
      final json = {
        'id': 'entry-rev-02',
        'account_id': 'acc-001',
        'entry_type': 'DEBIT',
        'amount_cents': 75000,
        'category': 'ESTORNO',
        'nature': 'BUSINESS',
        'description': 'Estorno de recebimento #100',
        'source_type': 'REVERSAL',
        'source_id': 'pay-rec-01',
        'payment_method': 'PIX',
        'occurred_at': '2026-10-11T16:00:00.000Z',
        'reversal_of_id': 'entry-01',
        'is_reversal': true,
        'created_at': '2026-10-11T16:00:01.000Z',
      };

      final entry = CashFlowEntry.fromJson(json);
      expect(entry.id, 'entry-rev-02');
      expect(entry.isReversal, isTrue);
      expect(entry.reversalOfId, 'entry-01');
      expect(entry.entryType, 'DEBIT');
    });

    test('CashFlowEntryCreate toJson serialization', () {
      final create = CashFlowEntryCreate(
        accountId: 'acc-001',
        entryType: 'DEBIT',
        amountCents: 15000,
        category: 'DESPESA_COMBUSTIVEL',
        nature: 'BUSINESS',
        description: 'Abastecimento van entrega',
        paymentMethod: 'DEBIT_CARD',
        occurredAt: DateTime.parse('2026-10-11T11:00:00.000Z'),
        notes: 'Posto Shell',
      );

      final json = create.toJson();
      expect(json['account_id'], 'acc-001');
      expect(json['entry_type'], 'DEBIT');
      expect(json['amount_cents'], 15000);
      expect(json['category'], 'DESPESA_COMBUSTIVEL');
      expect(json['nature'], 'BUSINESS');
      expect(json['description'], 'Abastecimento van entrega');
      expect(json['payment_method'], 'DEBIT_CARD');
      expect(json['occurred_at'], '2026-10-11T11:00:00.000Z');
      expect(json['notes'], 'Posto Shell');
    });

    test('FinancialTransfer fromJson and FinancialTransferCreate toJson', () {
      final transferJson = {
        'transfer_id': 'transf-xyz',
        'source_account_id': 'acc-cash',
        'source_account_name': 'Caixa Físico',
        'destination_account_id': 'acc-bank',
        'destination_account_name': 'Banco do Brasil',
        'amount_cents': 300000,
        'transfer_date': '2026-10-11T17:00:00.000Z',
        'source_entry_id': 'entry-debit-1',
        'destination_entry_id': 'entry-credit-1',
        'description': 'Depósito de sangria do caixa',
        'notes': 'Envelope #4412',
      };

      final transfer = FinancialTransfer.fromJson(transferJson);
      expect(transfer.transferId, 'transf-xyz');
      expect(transfer.sourceAccountId, 'acc-cash');
      expect(transfer.sourceAccountName, 'Caixa Físico');
      expect(transfer.destinationAccountId, 'acc-bank');
      expect(transfer.destinationAccountName, 'Banco do Brasil');
      expect(transfer.amountCents, 300000);
      expect(transfer.sourceEntryId, 'entry-debit-1');
      expect(transfer.destinationEntryId, 'entry-credit-1');

      final create = FinancialTransferCreate(
        sourceAccountId: 'acc-cash',
        destinationAccountId: 'acc-bank',
        amountCents: 300000,
        description: 'Sangria do caixa para banco',
        notes: 'Malote 12',
      );
      final createJson = create.toJson();
      expect(createJson['source_account_id'], 'acc-cash');
      expect(createJson['destination_account_id'], 'acc-bank');
      expect(createJson['amount_cents'], 300000);
      expect(createJson['description'], 'Sangria do caixa para banco');
      expect(createJson['notes'], 'Malote 12');
    });

    test('TreasurySummary fromJson with embedded accounts', () {
      final json = {
        'total_available_cents': 500000,
        'cash_balance_cents': 200000,
        'bank_balance_cents': 300000,
        'open_receivables_cents': 400000,
        'overdue_receivables_cents': 50000,
        'open_payables_cents': 150000,
        'overdue_payables_cents': 20000,
        'route_cash_pending_cents': 80000,
        'projected_net_cents': 750000,
        'period_business_expenses_cents': 45000,
        'period_personal_withdrawals_cents': 10000,
        'accounts': [
          {
            'id': 'acc-1',
            'name': 'Caixa Loja',
            'account_type': 'CASH',
            'initial_balance_cents': 50000,
            'current_balance_cents': 200000,
            'is_active': true,
            'is_default': true,
            'created_at': '2026-10-11T10:00:00.000Z',
            'updated_at': '2026-10-11T10:00:00.000Z',
          },
          {
            'id': 'acc-2',
            'name': 'Conta Itaú',
            'account_type': 'BANK',
            'bank_name': 'Itaú',
            'account_number': '9988-7',
            'initial_balance_cents': 0,
            'current_balance_cents': 300000,
            'is_active': true,
            'is_default': false,
            'created_at': '2026-10-11T10:00:00.000Z',
            'updated_at': '2026-10-11T10:00:00.000Z',
          }
        ],
      };

      final summary = TreasurySummary.fromJson(json);
      expect(summary.totalAvailableCents, 500000);
      expect(summary.cashBalanceCents, 200000);
      expect(summary.bankBalanceCents, 300000);
      expect(summary.openReceivablesCents, 400000);
      expect(summary.overdueReceivablesCents, 50000);
      expect(summary.openPayablesCents, 150000);
      expect(summary.overduePayablesCents, 20000);
      expect(summary.routeCashPendingCents, 80000);
      expect(summary.projectedNetCents, 750000);
      expect(summary.periodBusinessExpensesCents, 45000);
      expect(summary.periodPersonalWithdrawalsCents, 10000);
      expect(summary.accounts.length, 2);
      expect(summary.accounts.first.name, 'Caixa Loja');
      expect(summary.accounts.last.name, 'Conta Itaú');
    });
  });

  group('Phase 7 AccountPayable Model Tests', () {
    test('AccountPayable and PayablePayment fromJson parsing', () {
      final json = {
        'id': 'pay-001',
        'payable_number': 1001,
        'description': 'Fornecedor Grãos ABC - Fatura 889',
        'beneficiary': 'Grãos ABC Alimentos Ltda',
        'category': 'FORNECEDORES_INSUMOS',
        'nature': 'BUSINESS',
        'original_amount_cents': 300000,
        'paid_amount_cents': 100000,
        'balance_cents': 200000,
        'due_date': '2026-10-25T00:00:00.000Z',
        'payment_method': 'BOLETO',
        'status': 'PARTIAL',
        'is_overdue': false,
        'purchase_id': 'pur-1234',
        'installment_number': 1,
        'total_installments': 3,
        'installment_group_id': 'grp-777',
        'is_recurrent': false,
        'recurrence_period': null,
        'notes': 'Parcela 1 de 3',
        'created_at': '2026-10-10T12:00:00.000Z',
        'updated_at': '2026-10-11T14:00:00.000Z',
        'payments_count': 1,
        'payments': [
          {
            'id': 'pay-sub-1',
            'payable_id': 'pay-001',
            'account_id': 'acc-bank',
            'account_name': 'Banco do Brasil',
            'payment_date': '2026-10-11T14:00:00.000Z',
            'amount_cents': 100000,
            'payment_method': 'BOLETO',
            'status': 'CONFIRMED',
            'reversal_reason': null,
            'reversal_of_id': null,
            'notes': 'Amortização inicial',
            'created_at': '2026-10-11T14:00:05.000Z',
          }
        ],
      };

      final payable = AccountPayable.fromJson(json);
      expect(payable.id, 'pay-001');
      expect(payable.payableNumber, 1001);
      expect(payable.description, 'Fornecedor Grãos ABC - Fatura 889');
      expect(payable.beneficiary, 'Grãos ABC Alimentos Ltda');
      expect(payable.category, 'FORNECEDORES_INSUMOS');
      expect(payable.nature, 'BUSINESS');
      expect(payable.originalAmountCents, 300000);
      expect(payable.paidAmountCents, 100000);
      expect(payable.balanceCents, 200000);
      expect(payable.status, 'PARTIAL');
      expect(payable.isOverdue, isFalse);
      expect(payable.purchaseId, 'pur-1234');
      expect(payable.installmentNumber, 1);
      expect(payable.totalInstallments, 3);
      expect(payable.installmentGroupId, 'grp-777');
      expect(payable.paymentsCount, 1);
      expect(payable.payments.length, 1);

      final payment = payable.payments.first;
      expect(payment.id, 'pay-sub-1');
      expect(payment.payableId, 'pay-001');
      expect(payment.accountId, 'acc-bank');
      expect(payment.accountName, 'Banco do Brasil');
      expect(payment.amountCents, 100000);
      expect(payment.status, 'CONFIRMED');
      expect(payment.notes, 'Amortização inicial');
    });

    test('AccountPayableCreate and PayablePaymentCreate serialization', () {
      final payableCreate = AccountPayableCreate(
        description: 'Aluguel do Galpão',
        beneficiary: 'Imobiliária Central',
        category: 'ALUGUEL_E_TAXAS',
        nature: 'BUSINESS',
        originalAmountCents: 250000,
        dueDate: DateTime.parse('2026-11-05T00:00:00.000Z'),
        paymentMethod: 'PIX',
        totalInstallments: 2,
        installmentDueDates: [
          DateTime.parse('2026-11-05T00:00:00.000Z'),
          DateTime.parse('2026-12-05T00:00:00.000Z'),
        ],
        isRecurrent: true,
        recurrencePeriod: 'MONTHLY',
        notes: 'Contrato de 12 meses',
      );

      final json = payableCreate.toJson();
      expect(json['description'], 'Aluguel do Galpão');
      expect(json['beneficiary'], 'Imobiliária Central');
      expect(json['category'], 'ALUGUEL_E_TAXAS');
      expect(json['original_amount_cents'], 250000);
      expect(json['payment_method'], 'PIX');
      expect(json['total_installments'], 2);
      expect(json['is_recurrent'], isTrue);
      expect(json['recurrence_period'], 'MONTHLY');
      expect((json['installment_due_dates'] as List).length, 2);

      final paymentCreate = PayablePaymentCreate(
        amountCents: 125000,
        accountId: 'acc-bank',
        paymentMethod: 'PIX',
        paymentDate: DateTime.parse('2026-11-05T10:00:00.000Z'),
        notes: 'Pagamento pontual com desconto',
      );
      final payJson = paymentCreate.toJson();
      expect(payJson['amount_cents'], 125000);
      expect(payJson['account_id'], 'acc-bank');
      expect(payJson['payment_method'], 'PIX');
      expect(payJson['payment_date'], '2026-11-05T10:00:00.000Z');
      expect(payJson['notes'], 'Pagamento pontual com desconto');
    });
  });

  group('Phase 7 SalesReceivable and ReceivablePayment Enriched Model Tests', () {
    test('SalesReceivable fromJson with Phase 7 enriched fields', () {
      final json = {
        'id': 'rec-001',
        'sale_id': 'sale-100',
        'sale_number': 100,
        'customer_id': 'cust-50',
        'customer_name': 'Mercadinho da Serra',
        'due_date': '2026-10-30T00:00:00.000Z',
        'original_amount_cents': 60000,
        'paid_amount_cents': 20000,
        'balance_cents': 40000,
        'status': 'PARTIAL',
        'is_overdue': false,
        'basket_types_summary': 'Cesta Básica Familiar (x3)',
        'sale_date': '2026-10-01T10:00:00.000Z',
        'created_at': '2026-10-01T10:00:00.000Z',
        'updated_at': '2026-10-05T11:00:00.000Z',
        'payments_count': 1,
        'payments': [
          {
            'id': 'rec-pay-01',
            'receivable_id': 'rec-001',
            'dispatch_id': 'disp-05',
            'account_id': 'acc-cash',
            'account_name': 'Caixa Físico',
            'payment_date': '2026-10-05T11:00:00.000Z',
            'amount_cents': 20000,
            'payment_method': 'CASH',
            'status': 'CONFIRMED',
            'is_route_collection': true,
            'repass_status': 'PENDING_REPASS',
            'notes': 'Recebido na rota pelo entregador',
            'created_at': '2026-10-05T11:00:05.000Z',
          }
        ],
      };

      final receivable = SalesReceivable.fromJson(json);
      expect(receivable.id, 'rec-001');
      expect(receivable.saleId, 'sale-100');
      expect(receivable.customerName, 'Mercadinho da Serra');
      expect(receivable.originalAmountCents, 60000);
      expect(receivable.paidAmountCents, 20000);
      expect(receivable.balanceCents, 40000);
      expect(receivable.status, 'PARTIAL');
      expect(receivable.basketTypesSummary, 'Cesta Básica Familiar (x3)');
      expect(receivable.saleDate, isNotNull);
      expect(receivable.payments.length, 1);

      final p = receivable.payments.first;
      expect(p.id, 'rec-pay-01');
      expect(p.dispatchId, 'disp-05');
      expect(p.accountId, 'acc-cash');
      expect(p.accountName, 'Caixa Físico');
      expect(p.isRouteCollection, isTrue);
      expect(p.repassStatus, 'PENDING_REPASS');
    });

    test('ReceivablePaymentCreate toJson serialization', () {
      final create = ReceivablePaymentCreate(
        amountCents: 40000,
        paymentMethod: 'PIX',
        accountId: 'acc-bank',
        paymentDate: DateTime.parse('2026-10-15T09:00:00.000Z'),
        notes: 'Quitação integral restante',
      );

      final json = create.toJson();
      expect(json['amount_cents'], 40000);
      expect(json['payment_method'], 'PIX');
      expect(json['account_id'], 'acc-bank');
      expect(json['dispatch_id'], isNull);
      expect(json['payment_date'], '2026-10-15T09:00:00.000Z');
      expect(json['notes'], 'Quitação integral restante');
    });
  });

  group('Phase 7 PayableService & ReceivableService Query & Recurrence Tests', () {
    late MockApiClient mockClient;

    setUp(() {
      mockClient = MockApiClient();
    });

    test('PayableService.getPayables formats all filter query parameters correctly', () async {
      final service = PayableService(client: mockClient);
      mockClient.nextResponse = [];

      final from = DateTime.parse('2026-10-01T00:00:00.000Z');
      final to = DateTime.parse('2026-10-31T23:59:59.000Z');

      await service.getPayables(
        dueDateFrom: from,
        dueDateTo: to,
        month: 10,
        year: 2026,
        category: 'FORNECEDOR',
        beneficiary: 'Grãos ABC',
        status: 'OPEN',
        nature: 'BUSINESS',
        overdueOnly: true,
      );

      expect(mockClient.lastGetPath, isNotNull);
      final path = mockClient.lastGetPath!;
      expect(path, startsWith('/api/v1/payables?'));
      expect(path, contains('due_date_from=2026-10-01T00%3A00%3A00.000Z'));
      expect(path, contains('due_date_to=2026-10-31T23%3A59%3A59.000Z'));
      expect(path, contains('month=10'));
      expect(path, contains('year=2026'));
      expect(path, contains('category=FORNECEDOR'));
      expect(path, contains('beneficiary=Gr%C3%A3os%20ABC'));
      expect(path, contains('status=OPEN'));
      expect(path, contains('nature=BUSINESS'));
      expect(path, contains('overdue_only=true'));
    });

    test('PayableService.generateNextRecurrence calls correct endpoint', () async {
      final service = PayableService(client: mockClient);
      mockClient.nextResponse = {
        'id': 'pay-rec-02',
        'payable_number': 1002,
        'description': 'Aluguel - Parcela 2',
        'beneficiary': 'Imobiliária Central',
        'category': 'ALUGUEL',
        'nature': 'BUSINESS',
        'original_amount_cents': 250000,
        'paid_amount_cents': 0,
        'balance_cents': 250000,
        'due_date': '2026-12-05T00:00:00.000Z',
        'payment_method': 'PIX',
        'status': 'OPEN',
        'is_overdue': false,
        'installment_number': 2,
        'total_installments': 1,
        'is_recurrent': true,
        'recurrence_period': 'MONTHLY',
        'created_at': '2026-11-05T00:00:00.000Z',
        'updated_at': '2026-11-05T00:00:00.000Z',
        'payments_count': 0,
        'payments': [],
      };

      final result = await service.generateNextRecurrence('pay-001');

      expect(mockClient.lastPostPath, '/api/v1/payables/pay-001/next-recurrence');
      expect(result.id, 'pay-rec-02');
      expect(result.isRecurrent, isTrue);
      expect(result.installmentNumber, 2);
    });

    test('ReceivableService.getReceivables formats all advanced filter query parameters correctly', () async {
      final service = ReceivableService(client: mockClient);
      mockClient.nextResponse = [];

      final saleFrom = DateTime.parse('2026-09-01T00:00:00.000Z');
      final saleTo = DateTime.parse('2026-09-30T23:59:59.000Z');
      final dueFrom = DateTime.parse('2026-10-01T00:00:00.000Z');
      final dueTo = DateTime.parse('2026-10-31T23:59:59.000Z');

      await service.getReceivables(
        customerId: 'cust-99',
        basketTypeId: 'bt-premium',
        status: 'PARTIAL',
        overdueOnly: true,
        saleDateFrom: saleFrom,
        saleDateTo: saleTo,
        dueDateFrom: dueFrom,
        dueDateTo: dueTo,
        minAmountCents: 5000,
        maxAmountCents: 50000,
      );

      expect(mockClient.lastGetPath, isNotNull);
      final path = mockClient.lastGetPath!;
      expect(path, startsWith('/api/v1/receivables?'));
      expect(path, contains('customer_id=cust-99'));
      expect(path, contains('basket_type_id=bt-premium'));
      expect(path, contains('status=PARTIAL'));
      expect(path, contains('overdue_only=true'));
      expect(path, contains('sale_date_from=2026-09-01T00%3A00%3A00.000Z'));
      expect(path, contains('sale_date_to=2026-09-30T23%3A59%3A59.000Z'));
      expect(path, contains('due_date_from=2026-10-01T00%3A00%3A00.000Z'));
      expect(path, contains('due_date_to=2026-10-31T23%3A59%3A59.000Z'));
      expect(path, contains('min_amount_cents=5000'));
      expect(path, contains('max_amount_cents=50000'));
    });
  });
}

class MockApiClient extends ApiClient {
  String? lastGetPath;
  String? lastPostPath;
  dynamic lastPostBody;
  dynamic nextResponse;

  @override
  Future<dynamic> get(String path) async {
    lastGetPath = path;
    return nextResponse ?? [];
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic body,
    String? idempotencyKey,
    bool isMutation = true,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    return nextResponse ?? {};
  }
}
