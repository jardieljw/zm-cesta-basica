import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/core/api_client.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations_pt.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:zm_cesta_basica_client/utils/api_error_mapper.dart';

void main() {
  setUpAll(() async {
    await AppFormatters.initialize();
  });
  group('Localization (l10n) Tests', () {
    late AppLocalizations l10n;

    setUp(() {
      l10n = AppLocalizationsPt();
    });

    test('AppLocalizationsPt returns Portuguese strings for app titles and common buttons', () {
      expect(l10n.appTitle, equals('ZM Cesta Básica'));
      expect(l10n.homeHeaderTitle, equals('ZM Cestas - Gestão de Estoque'));
      expect(l10n.commonSave, equals('Salvar'));
      expect(l10n.commonCancel, equals('Cancelar'));
      expect(l10n.commonConfirm, equals('Confirmar'));
      expect(l10n.commonDelete, equals('Excluir'));
      expect(l10n.commonRequired, equals('Obrigatório'));
    });

    test('AppLocalizationsPt returns Portuguese strings for production and disassembly', () {
      expect(l10n.productionBatchesTitle, equals('Lotes de Produção'));
      expect(l10n.productionBatchNumber(42), equals('Lote #42'));
      expect(l10n.productionDisassembleTitle(101), equals('Desmontar Lote #101'));
      expect(l10n.productionDisassembleConfirm, equals('Confirmar Desmontagem'));
      expect(l10n.productionDisassembleQtyLabel, equals('Qtd. a Desmontar'));
      expect(l10n.productionDisassembleReasonLabel, equals('Motivo da Desmontagem'));
      expect(l10n.productionDisassembleTriageTitle, equals('Triagem Física dos Insumos'));
      expect(l10n.productionDisassembleAllIntact, equals('100% Intacto (Sem Avarias)'));
      expect(l10n.productionIntactQtyLabel('KG'), equals('Intacto (KG)'));
      expect(l10n.productionLossQtyLabel('KG'), equals('Perda/Avaria (KG)'));
      expect(l10n.productionCustom, equals('Cesta Personalizada'));
      expect(l10n.productionDirectSale, equals('Venda Direta'));
      expect(l10n.productionBatchCancelTitle(5), equals('Estorno Total do Lote #5'));
      expect(l10n.productionBatchCancelConfirm, equals('Confirmar Estorno'));
      expect(l10n.productionDisassembledSuccess, equals('Lote desmontado com sucesso!'));
      expect(l10n.productionBatchCancelSuccess, equals('Lote estornado com sucesso!'));
      expect(l10n.productionBatchEmpty, equals('Nenhum lote de produção encontrado.'));
      expect(l10n.productionBatchMountFirst, equals('Montar Primeira Cesta'));
      expect(l10n.validationMinChars(3), equals('Mínimo de 3 caracteres'));
      expect(l10n.validationMustBePositive, equals('A quantidade a desmontar deve ser maior que zero.'));
      expect(l10n.homePhase2Header, equals('Cadastros e Receitas'));
      expect(l10n.moduleProducts, equals('Produtos & Insumos'));
      expect(l10n.moduleBasketTypes, equals('Tipos de Cestas'));
      expect(l10n.modulePurchases, equals('Entrada de Compras'));
      expect(l10n.moduleProduction, equals('Ordens de Produção'));
      expect(l10n.moduleAssembly, equals('Montar Cestas'));
      expect(l10n.homeCheckConnection, equals('Verificar Conexão'));
      expect(l10n.homePairDevice, equals('Parear Dispositivo'));
    });

    test('AppLocalizations delegate loads pt_BR correctly', () {
      expect(AppLocalizations.supportedLocales.any((loc) => loc.languageCode == 'pt'), isTrue);
      final resolved = lookupAppLocalizations(const Locale('pt', 'BR'));
      expect(resolved.appTitle, equals('ZM Cesta Básica'));
    });
  });

  group('Centralized AppFormatters Tests', () {
    test(r'formatCurrency formats integer cents to Brazilian Real (R$)', () {
      final formatted = AppFormatters.formatCurrency(1550);
      // Clean non-breaking spaces if intl uses nbsp
      final normalized = formatted.replaceAll('\u00A0', ' ');
      expect(normalized, contains('R\$'));
      expect(normalized, contains('15,50'));
    });

    test('formatCurrency handles zero and round values', () {
      final formattedZero = AppFormatters.formatCurrency(0).replaceAll('\u00A0', ' ');
      expect(formattedZero, contains('0,00'));

      final formattedHundred = AppFormatters.formatCurrency(10000).replaceAll('\u00A0', ' ');
      expect(formattedHundred, contains('100,00'));
    });

    test('formatCurrencyFromMicrocents scales correctly', () {
      // 15,500,000 microcents = 1,550 cents = R$ 15,50
      final formatted = AppFormatters.formatCurrencyFromMicrocents(15500000).replaceAll('\u00A0', ' ');
      expect(formatted, contains('15,50'));
    });

    test('formatDate and formatDateTime follow Brazilian standard dd/MM/yyyy', () {
      final date = DateTime(2026, 10, 11, 14, 30);
      expect(AppFormatters.formatDate(date), equals('11/10/2026'));
      expect(AppFormatters.formatDateTime(date), equals('11/10/2026 14:30'));
    });

    test('formatNumber and formatQuantity format correctly', () {
      expect(AppFormatters.formatQuantity(5000, 'G'), contains('5.000 G'));
      expect(AppFormatters.formatQuantity(2, 'un'), contains('2 un'));
    });
  });

  group('ApiErrorMapper Tests', () {
    late AppLocalizations l10n;

    setUp(() {
      l10n = AppLocalizationsPt();
    });

    test('maps stable error_code INSUFFICIENT_STOCK to friendly localized message', () {
      final error = ApiException(
        statusCode: 409,
        message: 'Technical raw message',
        errorCode: 'INSUFFICIENT_STOCK',
      );
      final msg = ApiErrorMapper.toLocalizedMessage(error, l10n);
      expect(msg, equals(l10n.errorInsufficientStock));
      expect(msg, equals('Estoque insuficiente para realizar esta operação.'));
    });

    test('maps stable error_code IDEMPOTENCY_PAYLOAD_MISMATCH', () {
      final error = ApiException(
        statusCode: 422,
        message: 'Mismatch',
        errorCode: 'IDEMPOTENCY_PAYLOAD_MISMATCH',
      );
      final msg = ApiErrorMapper.toLocalizedMessage(error, l10n);
      expect(msg, equals(l10n.errorIdempotencyMismatch));
    });

    test('maps stable error_code REQUEST_IN_PROGRESS', () {
      final error = ApiException(
        statusCode: 409,
        message: 'Lock busy',
        errorCode: 'REQUEST_IN_PROGRESS',
      );
      final msg = ApiErrorMapper.toLocalizedMessage(error, l10n);
      expect(msg, equals(l10n.errorRequestInProgress));
    });

    test('maps HTTP 401 and 403 to unauthorized/forbidden messages', () {
      final err401 = ApiException(statusCode: 401, message: 'Unauthorized');
      expect(ApiErrorMapper.toLocalizedMessage(err401, l10n), equals(l10n.errorUnauthorized));

      final err403 = ApiException(statusCode: 403, message: 'Forbidden');
      expect(ApiErrorMapper.toLocalizedMessage(err403, l10n), equals(l10n.errorForbidden));
    });

    test('maps HTTP 0 and SocketException to connection failure message', () {
      final errConn = ApiException(statusCode: 0, message: 'Connection refused');
      expect(ApiErrorMapper.toLocalizedMessage(errConn, l10n), equals(l10n.errorConnectionFailed));

      const sockErr = SocketException('Failed host lookup');
      expect(ApiErrorMapper.toLocalizedMessage(sockErr, l10n), equals(l10n.errorConnectionFailed));
    });

    test('maps HTTP 500 to server error message', () {
      final err500 = ApiException(statusCode: 500, message: 'Internal Server Error');
      expect(ApiErrorMapper.toLocalizedMessage(err500, l10n), equals(l10n.errorServer));
    });
  });
}
