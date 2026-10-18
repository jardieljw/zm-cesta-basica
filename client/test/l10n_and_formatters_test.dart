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

    test(
        'AppLocalizationsPt returns Portuguese strings for app titles and common buttons',
        () {
      expect(l10n.appTitle, equals('ZM Cesta Básica'));
      expect(l10n.homeHeaderTitle, equals('ZM Cestas - Gestão de Estoque'));
      expect(l10n.commonSave, equals('Salvar'));
      expect(l10n.commonCancel, equals('Cancelar'));
      expect(l10n.commonConfirm, equals('Confirmar'));
      expect(l10n.commonDelete, equals('Excluir'));
      expect(l10n.commonRequired, equals('Obrigatório'));
    });

    test(
        'AppLocalizationsPt returns Portuguese strings for production and disassembly',
        () {
      expect(l10n.productionBatchesTitle, equals('Lotes de Produção'));
      expect(l10n.productionBatchNumber(42), equals('Lote #42'));
      expect(
          l10n.productionDisassembleTitle(101), equals('Desmontar Lote #101'));
      expect(
          l10n.productionDisassembleConfirm, equals('Confirmar Desmontagem'));
      expect(l10n.productionDisassembleQtyLabel, equals('Qtd. a Desmontar'));
      expect(l10n.productionDisassembleReasonLabel,
          equals('Motivo da Desmontagem'));
      expect(l10n.productionDisassembleTriageTitle,
          equals('Triagem Física dos Insumos'));
      expect(l10n.productionDisassembleAllIntact,
          equals('100% Intacto (Sem Avarias)'));
      expect(l10n.productionIntactQtyLabel('KG'), equals('Intacto (KG)'));
      expect(l10n.productionLossQtyLabel('KG'), equals('Perda/Avaria (KG)'));
      expect(l10n.productionCustom, equals('Cesta Personalizada'));
      expect(l10n.productionDirectSale, equals('Venda Direta'));
      expect(l10n.productionBatchCancelTitle(5),
          equals('Estorno Total do Lote #5'));
      expect(l10n.productionBatchCancelConfirm, equals('Confirmar Estorno'));
      expect(l10n.productionDisassembledSuccess,
          equals('Lote desmontado com sucesso!'));
      expect(l10n.productionBatchCancelSuccess,
          equals('Lote estornado com sucesso!'));
      expect(l10n.productionBatchEmpty,
          equals('Nenhum lote de produção encontrado.'));
      expect(l10n.productionBatchMountFirst, equals('Montar Primeira Cesta'));
      expect(l10n.validationMinChars(3), equals('Mínimo de 3 caracteres'));
      expect(l10n.validationMustBePositive,
          equals('A quantidade a desmontar deve ser maior que zero.'));
      expect(l10n.homePhase2Header, equals('Cadastros e Receitas'));
      expect(l10n.moduleProducts, equals('Produtos & Insumos'));
      expect(l10n.moduleBasketTypes, equals('Tipos de Cestas'));
      expect(l10n.modulePurchases, equals('Entrada de Compras'));
      expect(l10n.moduleProduction, equals('Ordens de Produção'));
      expect(l10n.moduleAssembly, equals('Montar Cestas'));
      expect(l10n.homeCheckConnection, equals('Verificar Conexão'));
      expect(l10n.homePairDevice, equals('Parear Dispositivo'));
    });

    test(
        'AppLocalizationsPt returns Portuguese strings for purchases, inventory, pairing and settings',
        () {
      expect(l10n.purchasesTitle, equals('Entrada de Compras'));
      expect(l10n.purchaseFormTitle, equals('Nova Entrada de Compras'));
      expect(
          l10n.purchaseFormSuccess, equals('Compra registrada com sucesso!'));
      expect(l10n.inventorySummaryHeaderTitle,
          equals('Saldo de Estoque em Tempo Real'));
      expect(l10n.inventoryMovementsHeaderTitle,
          equals('Extrato do Razão Contábil'));
      expect(
          l10n.stockAdjustmentDialogTitle, equals('Ajuste Manual de Estoque'));
      expect(l10n.pairingViewTitle, equals('Pareamento do Dispositivo'));
      expect(l10n.settingsHeaderTitle,
          equals('Configurações de Rede e Dispositivo'));
      expect(l10n.movementPurchase, equals('COMPRA'));
      expect(l10n.movementPurchaseCancel, equals('ESTORNO COMPRA'));
      expect(l10n.movementAdjustmentIn, equals('SOBRA / ENTRADA'));
      expect(l10n.movementAdjustmentOut, equals('AVARIA / SAÍDA'));
      expect(
          l10n.purchaseDetailUnitCost('R\$ 10,00'), equals('Unit.: R\$ 10,00'));
      expect(l10n.purchaseStatusConfirmedWithStock,
          equals('Confirmada (Aumenta Estoque)'));
      expect(l10n.purchaseStatusDraftWithoutStock,
          equals('Rascunho (Sem movimentar estoque)'));
      expect(l10n.purchaseItemIndex(3), equals('Item #3'));
      expect(l10n.stockAdjustmentTypeIn, equals('Sobra / Entrada (+)'));
      expect(l10n.stockAdjustmentTypeOut, equals('Avaria / Saída (-)'));
      expect(l10n.stockAdjustmentQtyHint, equals('Ex: 10'));
      expect(l10n.categoryFood, equals('Alimentação'));
      expect(l10n.categoryCleaning, equals('Limpeza'));
      expect(l10n.categoryMeat, equals('Carnes & Frios'));
      expect(l10n.categoryAll, equals('Todas'));
      expect(l10n.recipeUnknownIngredient('XYZ'), equals('Insumo (XYZ)'));
      expect(l10n.productionBatchViewIngredients, equals('Ver Insumos'));
      expect(l10n.productionDisassembleNoIngredients,
          equals('Nenhum insumo registrado neste lote.'));
      expect(
          l10n.homeLocalConnectionInfo, equals('Informações da Conexão Local'));
      expect(l10n.homeApiVersionLabel, equals('Versão da API'));
      expect(l10n.homeDatabaseStatusLabel, equals('Banco de Dados'));
    });

    test(
        'AppLocalizationsPt returns Portuguese strings for Phase 5 modules and dialogs',
        () {
      expect(l10n.customersTitle, equals('Clientes'));
      expect(l10n.customersEmpty, equals('Nenhum cliente cadastrado.'));
      expect(l10n.customerNameHint, equals('Ex: Supermercado São José'));
      expect(l10n.salesTitle, equals('Vendas de Cestas'));
      expect(l10n.salesEmpty, equals('Nenhuma venda registrada.'));
      expect(
          l10n.saleCreditCustomerRequired,
          equals(
              'Vendas a prazo (fiado) exigem a seleção de um cliente cadastrado.'));
      expect(
          l10n.saleInsufficientStockAlert('Cesta 1', 2, 5),
          contains(
              'Estoque insuficiente de cestas prontas para "Cesta 1". Saldo: 2, Solicitado: 5.'));
      expect(l10n.receivablesTitle, equals('Contas a Receber (Fiados)'));
      expect(
          l10n.receivablesEmpty, equals('Nenhum título a receber encontrado.'));
      expect(l10n.receivablePaymentAmountMustBePositive,
          equals('Informe um valor maior que zero.'));
      expect(l10n.commonViewDetails, equals('Ver Detalhes'));
    });

    test(
        'AppLocalizationsPt returns Portuguese strings for Phase 8 Dashboard, Reports, Forms & Printing',
        () {
      expect(l10n.dashboardTitle, equals('Dashboard Operacional e Financeiro'));
      expect(l10n.reportsTitle, equals('Relatórios Gerenciais e Planilhas'));
      expect(l10n.blankFormsTitle, equals('Formulários A4 para Impressão'));
      expect(l10n.formXlsxDownloadSuccess('relatorio.xlsx'),
          equals('Planilha XLSX baixada com sucesso: relatorio.xlsx'));
      expect(l10n.formXlsxDownloadError('Falha'),
          equals('Erro ao baixar planilha: Falha'));
      expect(l10n.printerLocating,
          equals('Localizando impressoras instaladas...'));
      expect(l10n.printerSystemDefault, equals('Padrão do Sistema'));
      expect(l10n.printerAvailable, equals('Disponível'));
      expect(l10n.printerActionPrint, equals('Imprimir'));
      expect(l10n.reportExportSuccess('XLSX'),
          equals('Planilha XLSX exportada com sucesso!'));
      expect(l10n.commonSelectedDateLabel('12/10/2026'),
          equals('Data: 12/10/2026'));
      expect(l10n.commonChange, equals('Alterar'));
      expect(l10n.commonPeriodLabel('01/10/2026', '31/10/2026'),
          equals('Período: 01/10/2026 até 31/10/2026'));
      expect(l10n.commonMonthNumber(5), equals('Mês 5'));
      expect(l10n.commonYearLabel, equals('Ano:'));
      expect(l10n.reportPhysicalBelowMinOnly,
          equals('Exibir apenas itens abaixo do estoque mínimo'));
      expect(l10n.dashboardSelectedDate('12/10/2026'),
          equals('Data selecionada: 12/10/2026'));
      expect(l10n.dashboardBatchesCount(4), equals('Lotes (4)'));
      expect(
          l10n.dashboardNoBatches, equals('Nenhum lote montado no período.'));
      expect(l10n.dashboardSalesCount(7), equals('Vendas (7)'));
      expect(l10n.dashboardNoSales,
          equals('Nenhuma venda registrada no período.'));
      expect(l10n.dashboardDispatchesCount(3), equals('Saídas (3)'));
      expect(l10n.dashboardExaminePendingDivergences(2),
          equals('Examinar Divergências Pendentes (2)'));
      expect(l10n.dashboardNoDispatches,
          equals('Nenhuma saída registrada no período.'));
      expect(l10n.dashboardDispatchItemSubtitle('12/10/2026 09:00', 20),
          equals('Data: 12/10/2026 09:00 | Cestas: 20 un.'));
      expect(l10n.dashboardNoRetainedValues,
          equals('Nenhum valor retido por responsável no momento.'));
      expect(l10n.dashboardResponsiblePhone('11999999999'),
          equals('Tel: 11999999999'));
      expect(l10n.dashboardResponsibleDate('12/10/2026'),
          equals('Data: 12/10/2026'));
      expect(
          l10n.dashboardNoDivergences, equals('Nenhuma divergência pendente.'));
      expect(l10n.dashboardSettledAt('12/10/2026 14:00'),
          equals('Acerto em: 12/10/2026 14:00'));
      expect(l10n.commonNotesPrefix('Observação física'),
          equals('Obs: Observação física'));
      expect(l10n.dashboardStockColBasket, equals('Cesta'));
      expect(l10n.dashboardStockColStore, equals('Loja'));
      expect(l10n.dashboardStockColTransit, equals('Trânsito'));
      expect(l10n.dashboardStockColTotal, equals('Total'));
      expect(l10n.dashboardAllAboveMinStock,
          equals('Todos os itens estão acima do estoque mínimo.'));
      expect(l10n.dashboardItemSku('SKU-100'), equals('SKU: SKU-100'));
      expect(l10n.dashboardCashRecordsCount(12), equals('Caixa (12)'));
      expect(l10n.dashboardProjectedInflow('R\$ 1.500,00'),
          equals('Entradas Previstas: R\$ 1.500,00'));
      expect(l10n.dashboardProjectedOutflow('R\$ 800,00'),
          equals('Saídas Previstas: R\$ 800,00'));
      expect(
          l10n.dashboardNoCashRecords, equals('Nenhum lançamento no período.'));
      expect(l10n.dashboardNoOpenReceivables,
          equals('Nenhum título a receber em aberto.'));
      expect(l10n.dashboardNoOpenPayables,
          equals('Nenhuma conta a pagar em aberto.'));
      expect(
          l10n.payableConfirmCancelObligationNamed('Conta de Luz'),
          equals(
              'Tem certeza que deseja cancelar a obrigação "Conta de Luz"?'));
      expect(l10n.tooltipPrintSelectPrinter,
          equals('Imprimir / Selecionar impressora'));
      expect(l10n.tooltipShareSavePdf, equals('Compartilhar / Salvar PDF'));
      expect(l10n.filterAllOption, equals('Todos'));
      expect(l10n.monthJan, equals('Jan'));
      expect(l10n.monthDec, equals('Dez'));
    });

    test(
        'AppLocalizations delegate loads pt_BR correctly and verifies supported locales',
        () {
      expect(
          AppLocalizations.supportedLocales
              .any((loc) => loc.languageCode == 'pt'),
          isTrue);
      final resolved = lookupAppLocalizations(const Locale('pt', 'BR'));
      expect(resolved.appTitle, equals('ZM Cesta Básica'));
      final resolvedPt = lookupAppLocalizations(const Locale('pt'));
      expect(resolvedPt.appTitle, equals('ZM Cesta Básica'));
    });

    testWidgets(
        'App falls back gracefully to default locale when device locale is foreign',
        (tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF1E88E5),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeListResolutionCallback: (locales, supported) {
            // When user device uses English/Spanish, resolution falls back safely to primary supported locale
            return supported.first;
          },
          locale: const Locale('en', 'US'),
          pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
            return PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, __) => builder(context),
            );
          },
          home: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context)!;
              return Text(loc.dashboardTitle, textDirection: TextDirection.ltr);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dashboard Operacional e Financeiro'), findsOneWidget);
    });

    testWidgets(
        'MaterialApp with pt_BR locale renders localized widgets seamlessly',
        (tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF1E88E5),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('pt'),
          ],
          locale: const Locale('pt', 'BR'),
          pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
            return PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, __) => builder(context),
            );
          },
          home: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context)!;
              return Text(loc.salesTitle, textDirection: TextDirection.ltr);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Vendas de Cestas'), findsOneWidget);
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
      final formattedZero =
          AppFormatters.formatCurrency(0).replaceAll('\u00A0', ' ');
      expect(formattedZero, contains('0,00'));

      final formattedHundred =
          AppFormatters.formatCurrency(10000).replaceAll('\u00A0', ' ');
      expect(formattedHundred, contains('100,00'));
    });

    test('formatCurrencyFromMicrocents scales correctly', () {
      // 15,500,000 microcents = 1,550 cents = R$ 15,50
      final formatted = AppFormatters.formatCurrencyFromMicrocents(15500000)
          .replaceAll('\u00A0', ' ');
      expect(formatted, contains('15,50'));
    });

    test('formatDate and formatDateTime follow Brazilian standard dd/MM/yyyy',
        () {
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

    test(
        'maps stable error_code INSUFFICIENT_STOCK to friendly localized message',
        () {
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
      expect(ApiErrorMapper.toLocalizedMessage(err401, l10n),
          equals(l10n.errorUnauthorized));

      final err403 = ApiException(statusCode: 403, message: 'Forbidden');
      expect(ApiErrorMapper.toLocalizedMessage(err403, l10n),
          equals(l10n.errorForbidden));
    });

    test('maps HTTP 0 and SocketException to connection failure message', () {
      final errConn =
          ApiException(statusCode: 0, message: 'Connection refused');
      expect(ApiErrorMapper.toLocalizedMessage(errConn, l10n),
          equals(l10n.errorConnectionFailed));

      const sockErr = SocketException('Failed host lookup');
      expect(ApiErrorMapper.toLocalizedMessage(sockErr, l10n),
          equals(l10n.errorConnectionFailed));
    });

    test('maps HTTP 500 to server error message', () {
      final err500 =
          ApiException(statusCode: 500, message: 'Internal Server Error');
      expect(ApiErrorMapper.toLocalizedMessage(err500, l10n),
          equals(l10n.errorServer));
    });
  });
}
