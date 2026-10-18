import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'ZM Cesta Básica'**
  String get appTitle;

  /// No description provided for @homeHeaderTitle.
  ///
  /// In pt, this message translates to:
  /// **'ZM Cestas - Gestão de Estoque'**
  String get homeHeaderTitle;

  /// No description provided for @commonSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @commonClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get commonBack;

  /// No description provided for @commonSearch.
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get commonSearch;

  /// No description provided for @commonClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get commonClear;

  /// No description provided for @commonLoading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get commonLoading;

  /// No description provided for @commonRefresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get commonRefresh;

  /// No description provided for @commonStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get commonStatus;

  /// No description provided for @commonActions.
  ///
  /// In pt, this message translates to:
  /// **'Ações'**
  String get commonActions;

  /// No description provided for @commonNotes.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get commonNotes;

  /// No description provided for @commonOptional.
  ///
  /// In pt, this message translates to:
  /// **'Opcional'**
  String get commonOptional;

  /// No description provided for @commonRequired.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatório'**
  String get commonRequired;

  /// No description provided for @commonYes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get commonYes;

  /// No description provided for @commonSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Operação realizada com sucesso'**
  String get commonSuccess;

  /// No description provided for @commonError.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro'**
  String get commonError;

  /// No description provided for @commonWarning.
  ///
  /// In pt, this message translates to:
  /// **'Atenção'**
  String get commonWarning;

  /// No description provided for @commonViewDetails.
  ///
  /// In pt, this message translates to:
  /// **'Ver Detalhes'**
  String get commonViewDetails;

  /// No description provided for @statusOnline.
  ///
  /// In pt, this message translates to:
  /// **'Conectado'**
  String get statusOnline;

  /// No description provided for @statusOffline.
  ///
  /// In pt, this message translates to:
  /// **'Desconectado'**
  String get statusOffline;

  /// No description provided for @statusPaired.
  ///
  /// In pt, this message translates to:
  /// **'Pareado'**
  String get statusPaired;

  /// No description provided for @statusUnpaired.
  ///
  /// In pt, this message translates to:
  /// **'Não Pareado'**
  String get statusUnpaired;

  /// No description provided for @serverUrlLabel.
  ///
  /// In pt, this message translates to:
  /// **'URL do Servidor'**
  String get serverUrlLabel;

  /// No description provided for @fingerprintLabel.
  ///
  /// In pt, this message translates to:
  /// **'Fingerprint TLS'**
  String get fingerprintLabel;

  /// No description provided for @moduleProducts.
  ///
  /// In pt, this message translates to:
  /// **'Produtos & Insumos'**
  String get moduleProducts;

  /// No description provided for @moduleBasketTypes.
  ///
  /// In pt, this message translates to:
  /// **'Tipos de Cestas'**
  String get moduleBasketTypes;

  /// No description provided for @modulePurchases.
  ///
  /// In pt, this message translates to:
  /// **'Entrada de Compras'**
  String get modulePurchases;

  /// No description provided for @moduleProduction.
  ///
  /// In pt, this message translates to:
  /// **'Ordens de Produção'**
  String get moduleProduction;

  /// No description provided for @moduleAssembly.
  ///
  /// In pt, this message translates to:
  /// **'Montar Cestas'**
  String get moduleAssembly;

  /// No description provided for @moduleInventorySummary.
  ///
  /// In pt, this message translates to:
  /// **'Posição de Estoque'**
  String get moduleInventorySummary;

  /// No description provided for @moduleInventoryMovements.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Movimentações'**
  String get moduleInventoryMovements;

  /// No description provided for @moduleSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get moduleSettings;

  /// No description provided for @modulePairing.
  ///
  /// In pt, this message translates to:
  /// **'Pareamento de Dispositivo'**
  String get modulePairing;

  /// No description provided for @productsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Produtos e Insumos'**
  String get productsTitle;

  /// No description provided for @productNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo Produto'**
  String get productNew;

  /// No description provided for @productEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar Produto'**
  String get productEdit;

  /// No description provided for @productName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Produto'**
  String get productName;

  /// No description provided for @productCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get productCategory;

  /// No description provided for @productBaseUnit.
  ///
  /// In pt, this message translates to:
  /// **'Unidade Base'**
  String get productBaseUnit;

  /// No description provided for @productMinStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque Mínimo'**
  String get productMinStock;

  /// No description provided for @productActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get productActive;

  /// No description provided for @productInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get productInactive;

  /// No description provided for @productPackagings.
  ///
  /// In pt, this message translates to:
  /// **'Embalagens / Apresentações'**
  String get productPackagings;

  /// No description provided for @packagingNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova Embalagem'**
  String get packagingNew;

  /// No description provided for @packagingName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Embalagem'**
  String get packagingName;

  /// No description provided for @packagingBarcode.
  ///
  /// In pt, this message translates to:
  /// **'Código de Barras'**
  String get packagingBarcode;

  /// No description provided for @packagingMultiplier.
  ///
  /// In pt, this message translates to:
  /// **'Fator Multiplicador'**
  String get packagingMultiplier;

  /// No description provided for @packagingUnit.
  ///
  /// In pt, this message translates to:
  /// **'Unidade de Embalagem'**
  String get packagingUnit;

  /// No description provided for @basketTypesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tipos de Cestas'**
  String get basketTypesTitle;

  /// No description provided for @basketTypeNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo Tipo de Cesta'**
  String get basketTypeNew;

  /// No description provided for @basketTypeEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar Tipo de Cesta'**
  String get basketTypeEdit;

  /// No description provided for @basketTypeCode.
  ///
  /// In pt, this message translates to:
  /// **'Código da Cesta'**
  String get basketTypeCode;

  /// No description provided for @basketTypeName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Cesta'**
  String get basketTypeName;

  /// No description provided for @basketTypeAllowsCustom.
  ///
  /// In pt, this message translates to:
  /// **'Permite Personalização'**
  String get basketTypeAllowsCustom;

  /// No description provided for @recipeVersionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Versão da Receita'**
  String get recipeVersionLabel;

  /// No description provided for @recipeAddIngredient.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Insumo'**
  String get recipeAddIngredient;

  /// No description provided for @purchasesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entrada de Compras'**
  String get purchasesTitle;

  /// No description provided for @purchaseNew.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Compra'**
  String get purchaseNew;

  /// No description provided for @purchaseInvoiceNumber.
  ///
  /// In pt, this message translates to:
  /// **'Número da NF'**
  String get purchaseInvoiceNumber;

  /// No description provided for @purchaseSupplier.
  ///
  /// In pt, this message translates to:
  /// **'Fornecedor'**
  String get purchaseSupplier;

  /// No description provided for @purchaseDate.
  ///
  /// In pt, this message translates to:
  /// **'Data da Compra'**
  String get purchaseDate;

  /// No description provided for @purchaseItems.
  ///
  /// In pt, this message translates to:
  /// **'Itens da Compra'**
  String get purchaseItems;

  /// No description provided for @purchasePackagesCount.
  ///
  /// In pt, this message translates to:
  /// **'Qtd. Embalagens'**
  String get purchasePackagesCount;

  /// No description provided for @purchaseUnitCost.
  ///
  /// In pt, this message translates to:
  /// **'Preço Unitário'**
  String get purchaseUnitCost;

  /// No description provided for @purchaseTotalCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo Total'**
  String get purchaseTotalCost;

  /// No description provided for @productionBatchesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lotes de Produção'**
  String get productionBatchesTitle;

  /// No description provided for @productionBatchNumber.
  ///
  /// In pt, this message translates to:
  /// **'Lote #{number}'**
  String productionBatchNumber(int number);

  /// No description provided for @productionDirectSale.
  ///
  /// In pt, this message translates to:
  /// **'Venda Direta'**
  String get productionDirectSale;

  /// No description provided for @productionCustom.
  ///
  /// In pt, this message translates to:
  /// **'Cesta Personalizada'**
  String get productionCustom;

  /// No description provided for @productionDisassembleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desmontar Lote #{number}'**
  String productionDisassembleTitle(int number);

  /// No description provided for @productionDisassembleConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Desmontagem'**
  String get productionDisassembleConfirm;

  /// No description provided for @productionDisassembleQtyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Qtd. a Desmontar'**
  String get productionDisassembleQtyLabel;

  /// No description provided for @productionDisassembleReasonLabel.
  ///
  /// In pt, this message translates to:
  /// **'Motivo da Desmontagem'**
  String get productionDisassembleReasonLabel;

  /// No description provided for @productionDisassembleTriageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Triagem Física dos Insumos'**
  String get productionDisassembleTriageTitle;

  /// No description provided for @productionDisassembleAllIntact.
  ///
  /// In pt, this message translates to:
  /// **'100% Intacto (Sem Avarias)'**
  String get productionDisassembleAllIntact;

  /// No description provided for @productionIntactQtyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Intacto ({unit})'**
  String productionIntactQtyLabel(String unit);

  /// No description provided for @productionLossQtyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Perda/Avaria ({unit})'**
  String productionLossQtyLabel(String unit);

  /// No description provided for @productionDisassembledSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Lote desmontado com sucesso!'**
  String get productionDisassembledSuccess;

  /// No description provided for @productionBatchEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum lote de produção encontrado.'**
  String get productionBatchEmpty;

  /// No description provided for @productionBatchMountFirst.
  ///
  /// In pt, this message translates to:
  /// **'Montar Primeira Cesta'**
  String get productionBatchMountFirst;

  /// No description provided for @productionBatchCancelTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estorno Total do Lote #{number}'**
  String productionBatchCancelTitle(int number);

  /// No description provided for @productionBatchCancelConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Estorno'**
  String get productionBatchCancelConfirm;

  /// No description provided for @productionBatchCancelSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Lote estornado com sucesso!'**
  String get productionBatchCancelSuccess;

  /// No description provided for @validationMinChars.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo de {min} caracteres'**
  String validationMinChars(int min);

  /// No description provided for @validationMustBePositive.
  ///
  /// In pt, this message translates to:
  /// **'A quantidade a desmontar deve ser maior que zero.'**
  String get validationMustBePositive;

  /// No description provided for @commonTryAgain.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Novamente'**
  String get commonTryAgain;

  /// No description provided for @homePhase2Header.
  ///
  /// In pt, this message translates to:
  /// **'Cadastros e Receitas'**
  String get homePhase2Header;

  /// No description provided for @homeProductsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Catálogo de itens, embalagens comerciais e estoque mínimo.'**
  String get homeProductsDescription;

  /// No description provided for @homeBasketTypesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Tipos de cestas e versionamento imutável de receitas.'**
  String get homeBasketTypesDescription;

  /// No description provided for @homePhase3Header.
  ///
  /// In pt, this message translates to:
  /// **'Estoque, Compras e Razão Contábil'**
  String get homePhase3Header;

  /// No description provided for @homePurchasesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Entrada de notas, conversão de fardos/caixas e cancelamento seguro.'**
  String get homePurchasesDescription;

  /// No description provided for @homeInventorySummaryDescription.
  ///
  /// In pt, this message translates to:
  /// **'Posição consolidada e alerta de ruptura de estoque.'**
  String get homeInventorySummaryDescription;

  /// No description provided for @homeInventoryMovementsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Histórico auditável e imutável de todas as movimentações.'**
  String get homeInventoryMovementsDescription;

  /// No description provided for @homeServerStatusTitle.
  ///
  /// In pt, this message translates to:
  /// **'Status do Servidor'**
  String get homeServerStatusTitle;

  /// No description provided for @homeCentralServer.
  ///
  /// In pt, this message translates to:
  /// **'Servidor Central'**
  String get homeCentralServer;

  /// No description provided for @homeCheckConnection.
  ///
  /// In pt, this message translates to:
  /// **'Verificar Conexão'**
  String get homeCheckConnection;

  /// No description provided for @homePairDevice.
  ///
  /// In pt, this message translates to:
  /// **'Parear Dispositivo'**
  String get homePairDevice;

  /// No description provided for @inventorySummaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Posição de Estoque'**
  String get inventorySummaryTitle;

  /// No description provided for @inventoryMovementsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Movimentações de Estoque'**
  String get inventoryMovementsTitle;

  /// No description provided for @stockAdjustmentsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste Manual de Estoque'**
  String get stockAdjustmentsTitle;

  /// No description provided for @stockAdjustmentNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo Ajuste de Estoque'**
  String get stockAdjustmentNew;

  /// No description provided for @stockAdjustmentTypeIn.
  ///
  /// In pt, this message translates to:
  /// **'Sobra / Entrada (+)'**
  String get stockAdjustmentTypeIn;

  /// No description provided for @stockAdjustmentTypeOut.
  ///
  /// In pt, this message translates to:
  /// **'Avaria / Saída (-)'**
  String get stockAdjustmentTypeOut;

  /// No description provided for @stockAdjustmentReasonLabel.
  ///
  /// In pt, this message translates to:
  /// **'Justificativa do Ajuste'**
  String get stockAdjustmentReasonLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// No description provided for @pairingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pareamento do Dispositivo'**
  String get pairingTitle;

  /// No description provided for @pairingPinLabel.
  ///
  /// In pt, this message translates to:
  /// **'PIN de Pareamento'**
  String get pairingPinLabel;

  /// No description provided for @pairingScanQr.
  ///
  /// In pt, this message translates to:
  /// **'Escanear QR Code'**
  String get pairingScanQr;

  /// No description provided for @pairingDeviceName.
  ///
  /// In pt, this message translates to:
  /// **'Nome deste Dispositivo'**
  String get pairingDeviceName;

  /// No description provided for @errorInsufficientStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque insuficiente para realizar esta operação.'**
  String get errorInsufficientStock;

  /// No description provided for @errorIdempotencyMismatch.
  ///
  /// In pt, this message translates to:
  /// **'Operação já executada com parâmetros divergentes.'**
  String get errorIdempotencyMismatch;

  /// No description provided for @errorRequestInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Requisição em processamento concorrente. Aguarde alguns instantes.'**
  String get errorRequestInProgress;

  /// No description provided for @errorUnauthorized.
  ///
  /// In pt, this message translates to:
  /// **'Dispositivo não autenticado. Realize o pareamento novamente.'**
  String get errorUnauthorized;

  /// No description provided for @errorDeviceRevoked.
  ///
  /// In pt, this message translates to:
  /// **'Dispositivo revogado pelo servidor central.'**
  String get errorDeviceRevoked;

  /// No description provided for @errorForbidden.
  ///
  /// In pt, this message translates to:
  /// **'Acesso não permitido.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Registro ou recurso não encontrado.'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In pt, this message translates to:
  /// **'Conflito de estado ou dados inconsistentes na operação.'**
  String get errorConflict;

  /// No description provided for @errorValidationError.
  ///
  /// In pt, this message translates to:
  /// **'Dados enviados são inválidos. Verifique os campos preenchidos.'**
  String get errorValidationError;

  /// No description provided for @errorServer.
  ///
  /// In pt, this message translates to:
  /// **'Erro interno no servidor local. Tente novamente mais tarde.'**
  String get errorServer;

  /// No description provided for @errorConnectionFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conectar ao servidor local. Verifique sua rede e se o serviço está ativo.'**
  String get errorConnectionFailed;

  /// No description provided for @errorUnexpected.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro inesperado.'**
  String get errorUnexpected;

  /// No description provided for @productsCatalogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Catálogo de Produtos e Insumos'**
  String get productsCatalogTitle;

  /// No description provided for @productSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por nome, SKU ou código de barras...'**
  String get productSearchHint;

  /// No description provided for @productEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto encontrado com os filtros selecionados.'**
  String get productEmpty;

  /// No description provided for @productInactivateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Inativar Produto'**
  String get productInactivateTitle;

  /// No description provided for @productInactivateConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja inativar o produto \"{name}\"?\n\nO cadastro e o histórico serão preservados. Ele deixará de aparecer em novas compras e composições. Produtos nunca utilizados também podem ser excluídos definitivamente pela ação de excluir.'**
  String productInactivateConfirm(String name);

  /// No description provided for @productInactivateButton.
  ///
  /// In pt, this message translates to:
  /// **'Inativar'**
  String get productInactivateButton;

  /// No description provided for @productInactivatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Produto inativado com sucesso.'**
  String get productInactivatedSuccess;

  /// No description provided for @productInactivateError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao inativar produto: {error}'**
  String productInactivateError(String error);

  /// No description provided for @productLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar produtos: {error}'**
  String productLoadError(String error);

  /// No description provided for @productCostPriceRef.
  ///
  /// In pt, this message translates to:
  /// **'Custo Ref.:'**
  String get productCostPriceRef;

  /// No description provided for @productSalePriceRef.
  ///
  /// In pt, this message translates to:
  /// **'Venda Ref.:'**
  String get productSalePriceRef;

  /// No description provided for @productPackagingsCount.
  ///
  /// In pt, this message translates to:
  /// **'Formas de compra ({count})'**
  String productPackagingsCount(int count);

  /// No description provided for @productSkuLabel.
  ///
  /// In pt, this message translates to:
  /// **'SKU: {sku}  '**
  String productSkuLabel(String sku);

  /// No description provided for @productBarcodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'EAN: {barcode}'**
  String productBarcodeLabel(String barcode);

  /// No description provided for @productFormNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo Produto / Insumo'**
  String get productFormNewTitle;

  /// No description provided for @productFormEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Produto / Insumo'**
  String get productFormEditTitle;

  /// No description provided for @productFormNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Produto *'**
  String get productFormNameLabel;

  /// No description provided for @productFormNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Arroz Agulhinha 5kg, Detergente 500ml'**
  String get productFormNameHint;

  /// No description provided for @productFormNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Nome é obrigatório'**
  String get productFormNameRequired;

  /// No description provided for @productFormCategoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria *'**
  String get productFormCategoryLabel;

  /// No description provided for @productFormBaseUnitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Unidade Base no Estoque *'**
  String get productFormBaseUnitLabel;

  /// No description provided for @productFormSkuLabel.
  ///
  /// In pt, this message translates to:
  /// **'SKU / Código Interno'**
  String get productFormSkuLabel;

  /// No description provided for @productFormSkuHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: ARR-5KG'**
  String get productFormSkuHint;

  /// No description provided for @productFormBarcodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código de Barras / EAN'**
  String get productFormBarcodeLabel;

  /// No description provided for @productFormBarcodeHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 7891234567890'**
  String get productFormBarcodeHint;

  /// No description provided for @productFormMinStockLabel.
  ///
  /// In pt, this message translates to:
  /// **'Estoque Mínimo ({unit})'**
  String productFormMinStockLabel(String unit);

  /// No description provided for @productFormMinStockInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo deve ser >= 0'**
  String get productFormMinStockInvalid;

  /// No description provided for @productFormCostPriceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço de Custo (R\$)'**
  String get productFormCostPriceLabel;

  /// No description provided for @productFormSalePriceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço de Venda (R\$)'**
  String get productFormSalePriceLabel;

  /// No description provided for @productFormNotesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get productFormNotesLabel;

  /// No description provided for @productFormStatusActive.
  ///
  /// In pt, this message translates to:
  /// **'Status Ativo'**
  String get productFormStatusActive;

  /// No description provided for @productFormStatusActiveSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Produtos inativos não podem ser incluídos em novas receitas ou compras.'**
  String get productFormStatusActiveSubtitle;

  /// No description provided for @productFormSaveCreate.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar Produto'**
  String get productFormSaveCreate;

  /// No description provided for @productFormSaveUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar Produto'**
  String get productFormSaveUpdate;

  /// No description provided for @productFormSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao salvar produto: {error}'**
  String productFormSaveError(String error);

  /// No description provided for @packagingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Formas de compra (embalagens)'**
  String get packagingsTitle;

  /// No description provided for @packagingProductSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{name} (Base: {unit})'**
  String packagingProductSubtitle(String name, String unit);

  /// No description provided for @packagingEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma embalagem comercial cadastrada. O estoque será movimentado diretamente na unidade base.'**
  String get packagingEmpty;

  /// No description provided for @packagingFactorLabel.
  ///
  /// In pt, this message translates to:
  /// **'Fator: {factor} {unit} {defaultTag}'**
  String packagingFactorLabel(int factor, String unit, String defaultTag);

  /// No description provided for @packagingDefaultTag.
  ///
  /// In pt, this message translates to:
  /// **'• (Padrão)'**
  String get packagingDefaultTag;

  /// No description provided for @packagingInactivateTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Inativar'**
  String get packagingInactivateTooltip;

  /// No description provided for @packagingAddButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Embalagem'**
  String get packagingAddButton;

  /// No description provided for @packagingDialogNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Embalagem Comercial'**
  String get packagingDialogNewTitle;

  /// No description provided for @packagingDialogNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Embalagem *'**
  String get packagingDialogNameLabel;

  /// No description provided for @packagingDialogNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Fardo c/ 10 un, Caixa c/ 12'**
  String get packagingDialogNameHint;

  /// No description provided for @packagingDialogQtyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conteúdo de uma embalagem ({unit}) *'**
  String packagingDialogQtyLabel(String unit);

  /// No description provided for @packagingDialogQtyHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 10, 5000'**
  String get packagingDialogQtyHint;

  /// No description provided for @packagingDialogDefaultSwitch.
  ///
  /// In pt, this message translates to:
  /// **'Embalagem Padrão de Compra'**
  String get packagingDialogDefaultSwitch;

  /// No description provided for @packagingDialogValidation.
  ///
  /// In pt, this message translates to:
  /// **'Informe nome e quantidade maior que 0.'**
  String get packagingDialogValidation;

  /// No description provided for @packagingDialogSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao cadastrar: {error}'**
  String packagingDialogSaveError(String error);

  /// No description provided for @packagingDialogLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar embalagens: {error}'**
  String packagingDialogLoadError(String error);

  /// No description provided for @basketTypesHeaderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tipos de Cestas e Receitas'**
  String get basketTypesHeaderTitle;

  /// No description provided for @basketTypeSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por nome ou código...'**
  String get basketTypeSearchHint;

  /// No description provided for @basketTypeEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum tipo de cesta encontrado.'**
  String get basketTypeEmpty;

  /// No description provided for @basketTypeInactivateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Inativar Tipo de Cesta'**
  String get basketTypeInactivateTitle;

  /// No description provided for @basketTypeInactivateConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja inativar \"{name}\"?\n\nA exclusão física é proibida para preservar histórico de vendas e montagens.'**
  String basketTypeInactivateConfirm(String name);

  /// No description provided for @basketTypeInactivateButton.
  ///
  /// In pt, this message translates to:
  /// **'Inativar'**
  String get basketTypeInactivateButton;

  /// No description provided for @basketTypeInactivatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de cesta inativado com sucesso.'**
  String get basketTypeInactivatedSuccess;

  /// No description provided for @basketTypeInactivateError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao inativar: {error}'**
  String basketTypeInactivateError(String error);

  /// No description provided for @basketTypeLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar tipos de cestas: {error}'**
  String basketTypeLoadError(String error);

  /// No description provided for @basketTypeRecipeActive.
  ///
  /// In pt, this message translates to:
  /// **'Receita Versão {version} Ativa ({count} itens)'**
  String basketTypeRecipeActive(int version, int count);

  /// No description provided for @basketTypeRecipeNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem receita cadastrada'**
  String get basketTypeRecipeNone;

  /// No description provided for @basketTypeManageRecipe.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar Receita'**
  String get basketTypeManageRecipe;

  /// No description provided for @basketTypeFormNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo Tipo de Cesta'**
  String get basketTypeFormNewTitle;

  /// No description provided for @basketTypeFormEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Tipo de Cesta'**
  String get basketTypeFormEditTitle;

  /// No description provided for @basketTypeFormCodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código da Cesta *'**
  String get basketTypeFormCodeLabel;

  /// No description provided for @basketTypeFormCodeHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: BASICA-FAMILIA-01'**
  String get basketTypeFormCodeHint;

  /// No description provided for @basketTypeFormCodeRequired.
  ///
  /// In pt, this message translates to:
  /// **'Código é obrigatório'**
  String get basketTypeFormCodeRequired;

  /// No description provided for @basketTypeFormNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Cesta *'**
  String get basketTypeFormNameLabel;

  /// No description provided for @basketTypeFormNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Cesta Básica Familiar Completa'**
  String get basketTypeFormNameHint;

  /// No description provided for @basketTypeFormNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Nome é obrigatório'**
  String get basketTypeFormNameRequired;

  /// No description provided for @basketTypeFormCategoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria *'**
  String get basketTypeFormCategoryLabel;

  /// No description provided for @basketTypeFormPriceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço de Venda Padrão (R\$)'**
  String get basketTypeFormPriceLabel;

  /// No description provided for @basketTypeFormDescLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição / Apresentação'**
  String get basketTypeFormDescLabel;

  /// No description provided for @basketTypeFormAllowsCustom.
  ///
  /// In pt, this message translates to:
  /// **'Permite Personalização'**
  String get basketTypeFormAllowsCustom;

  /// No description provided for @basketTypeFormAllowsCustomSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Permite que operadores alterem itens durante a montagem física.'**
  String get basketTypeFormAllowsCustomSubtitle;

  /// No description provided for @basketTypeFormTracksStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque de cestas prontas'**
  String get basketTypeFormTracksStock;

  /// No description provided for @basketTypeFormTracksStockSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Mantém o saldo de cestas prontas no estoque. Na venda, permite escolher Pronta ou Montar.'**
  String get basketTypeFormTracksStockSubtitle;

  /// No description provided for @basketTypeFormStatusActive.
  ///
  /// In pt, this message translates to:
  /// **'Status Ativo'**
  String get basketTypeFormStatusActive;

  /// No description provided for @basketTypeFormSaveCreate.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar Tipo de Cesta'**
  String get basketTypeFormSaveCreate;

  /// No description provided for @basketTypeFormSaveUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar Tipo de Cesta'**
  String get basketTypeFormSaveUpdate;

  /// No description provided for @basketTypeFormSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao salvar tipo de cesta: {error}'**
  String basketTypeFormSaveError(String error);

  /// No description provided for @recipeAppTitle.
  ///
  /// In pt, this message translates to:
  /// **'Receita: {name}'**
  String recipeAppTitle(String name);

  /// No description provided for @recipeNewVersionButton.
  ///
  /// In pt, this message translates to:
  /// **'Nova Versão'**
  String get recipeNewVersionButton;

  /// No description provided for @recipeEmptyVersions.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma versão de receita cadastrada para esta cesta.'**
  String get recipeEmptyVersions;

  /// No description provided for @recipeCreateFirstVersion.
  ///
  /// In pt, this message translates to:
  /// **'Criar Primeira Versão'**
  String get recipeCreateFirstVersion;

  /// No description provided for @recipeImmutabilityBanner.
  ///
  /// In pt, this message translates to:
  /// **'Versionamento Imutável: As receitas gravadas nunca são sobrescritas. Para alterar componentes, clique em \"Nova Versão\". Montagens antigas mantêm fidelidade exata à composição da época.'**
  String get recipeImmutabilityBanner;

  /// No description provided for @recipeVersionDisplayed.
  ///
  /// In pt, this message translates to:
  /// **'Versão em exibição: '**
  String get recipeVersionDisplayed;

  /// No description provided for @recipeVersionItem.
  ///
  /// In pt, this message translates to:
  /// **'Versão {version}'**
  String recipeVersionItem(int version);

  /// No description provided for @recipeStatusActive.
  ///
  /// In pt, this message translates to:
  /// **'ATIVA'**
  String get recipeStatusActive;

  /// No description provided for @recipeStatusArchived.
  ///
  /// In pt, this message translates to:
  /// **'ARQUIVADA'**
  String get recipeStatusArchived;

  /// No description provided for @recipeNotesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Notas da Versão: \"{notes}\"'**
  String recipeNotesLabel(String notes);

  /// No description provided for @recipeSectionHeader.
  ///
  /// In pt, this message translates to:
  /// **'Seção: {section} ({count} itens)'**
  String recipeSectionHeader(String section, int count);

  /// No description provided for @recipeDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Versão de Receita (Imutável)'**
  String get recipeDialogTitle;

  /// No description provided for @recipeDialogSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ao salvar, a composição atual será arquivada permanentemente e uma nova versão ativa será criada.'**
  String get recipeDialogSubtitle;

  /// No description provided for @recipeDialogNotesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Motivo da revisão / Notas da versão'**
  String get recipeDialogNotesLabel;

  /// No description provided for @recipeDialogNotesHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Troca de fornecedor do arroz, ajuste sazonal'**
  String get recipeDialogNotesHint;

  /// No description provided for @recipeDialogItemsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Insumos da Receita ({count})'**
  String recipeDialogItemsTitle(int count);

  /// No description provided for @recipeDialogAllProductsAdded.
  ///
  /// In pt, this message translates to:
  /// **'Todos os produtos ativos já estão na receita.'**
  String get recipeDialogAllProductsAdded;

  /// No description provided for @recipeDialogDuplicateItem.
  ///
  /// In pt, this message translates to:
  /// **'Este insumo já está na receita. Consolide a quantidade em um único item.'**
  String get recipeDialogDuplicateItem;

  /// No description provided for @recipeDialogNoItems.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum insumo adicionado. Clique em \"Adicionar Insumo\".'**
  String get recipeDialogNoItems;

  /// No description provided for @recipeDialogQtyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Qtd ({unit})'**
  String recipeDialogQtyLabel(String unit);

  /// No description provided for @recipeDialogValidationMinItems.
  ///
  /// In pt, this message translates to:
  /// **'A receita deve ter ao menos 1 item.'**
  String get recipeDialogValidationMinItems;

  /// No description provided for @recipeDialogSaveButton.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Nova Versão'**
  String get recipeDialogSaveButton;

  /// No description provided for @recipeDialogSaveSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Nova versão de receita criada com sucesso!'**
  String get recipeDialogSaveSuccess;

  /// No description provided for @recipeDialogSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao criar receita: {error}'**
  String recipeDialogSaveError(String error);

  /// No description provided for @recipeLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar receitas: {error}'**
  String recipeLoadError(String error);

  /// No description provided for @recipeLoadProductsError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar insumos: {error}'**
  String recipeLoadProductsError(String error);

  /// No description provided for @recipeNoActiveProducts.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum insumo ativo encontrado. Cadastre produtos primeiro.'**
  String get recipeNoActiveProducts;

  /// No description provided for @purchaseNumberTitle.
  ///
  /// In pt, this message translates to:
  /// **'Compra #{number}'**
  String purchaseNumberTitle(int number);

  /// No description provided for @purchaseFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos os Status'**
  String get purchaseFilterAll;

  /// No description provided for @purchaseFilterConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Confirmadas'**
  String get purchaseFilterConfirmed;

  /// No description provided for @purchaseFilterDraft.
  ///
  /// In pt, this message translates to:
  /// **'Rascunho'**
  String get purchaseFilterDraft;

  /// No description provided for @purchaseFilterCanceled.
  ///
  /// In pt, this message translates to:
  /// **'Canceladas'**
  String get purchaseFilterCanceled;

  /// No description provided for @purchaseSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por fornecedor, NF ou notas...'**
  String get purchaseSearchHint;

  /// No description provided for @purchaseEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma compra registrada.'**
  String get purchaseEmpty;

  /// No description provided for @purchaseCancelTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar Compra #{number}'**
  String purchaseCancelTitle(int number);

  /// No description provided for @purchaseCancelWarning.
  ///
  /// In pt, this message translates to:
  /// **'Esta operação realizará o estorno contábil dos produtos no livro-razão. Se os produtos já foram consumidos e não houver saldo suficiente, a operação será rejeitada.'**
  String get purchaseCancelWarning;

  /// No description provided for @purchaseCancelReasonLabel.
  ///
  /// In pt, this message translates to:
  /// **'Motivo do Cancelamento'**
  String get purchaseCancelReasonLabel;

  /// No description provided for @purchaseCancelReasonHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Nota fiscal cancelada pelo fornecedor'**
  String get purchaseCancelReasonHint;

  /// No description provided for @purchaseCancelReasonRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o motivo do cancelamento'**
  String get purchaseCancelReasonRequired;

  /// No description provided for @purchaseCancelSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Compra cancelada e estoque estornado com sucesso!'**
  String get purchaseCancelSuccess;

  /// No description provided for @purchaseCancelError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao cancelar compra: {error}'**
  String purchaseCancelError(String error);

  /// No description provided for @purchaseLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar compras: {error}'**
  String purchaseLoadError(String error);

  /// No description provided for @purchaseDetailItems.
  ///
  /// In pt, this message translates to:
  /// **'Itens da Compra ({count})'**
  String purchaseDetailItems(int count);

  /// No description provided for @purchaseDetailInvoice.
  ///
  /// In pt, this message translates to:
  /// **'NF: {invoice}'**
  String purchaseDetailInvoice(String invoice);

  /// No description provided for @purchaseDetailSupplier.
  ///
  /// In pt, this message translates to:
  /// **'Fornecedor: {supplier}'**
  String purchaseDetailSupplier(String supplier);

  /// No description provided for @purchaseDetailDate.
  ///
  /// In pt, this message translates to:
  /// **'Data: {date}'**
  String purchaseDetailDate(String date);

  /// No description provided for @purchaseDetailTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total da Compra: {total}'**
  String purchaseDetailTotal(String total);

  /// No description provided for @purchaseStatusConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'CONFIRMADA'**
  String get purchaseStatusConfirmed;

  /// No description provided for @purchaseStatusDraft.
  ///
  /// In pt, this message translates to:
  /// **'RASCUNHO'**
  String get purchaseStatusDraft;

  /// No description provided for @purchaseStatusCanceled.
  ///
  /// In pt, this message translates to:
  /// **'CANCELADA'**
  String get purchaseStatusCanceled;

  /// No description provided for @purchaseCancelButton.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar Compra'**
  String get purchaseCancelButton;

  /// No description provided for @purchaseFormTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Entrada de Compras'**
  String get purchaseFormTitle;

  /// No description provided for @purchaseFormSupplierLabel.
  ///
  /// In pt, this message translates to:
  /// **'Fornecedor *'**
  String get purchaseFormSupplierLabel;

  /// No description provided for @purchaseFormSupplierHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Atacadão Distribuidora Ltda'**
  String get purchaseFormSupplierHint;

  /// No description provided for @purchaseFormSupplierRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o fornecedor'**
  String get purchaseFormSupplierRequired;

  /// No description provided for @purchaseFormInvoiceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Número da NF'**
  String get purchaseFormInvoiceLabel;

  /// No description provided for @purchaseFormInvoiceHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 123456'**
  String get purchaseFormInvoiceHint;

  /// No description provided for @purchaseFormDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data da Compra'**
  String get purchaseFormDateLabel;

  /// No description provided for @purchaseFormNotesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get purchaseFormNotesLabel;

  /// No description provided for @purchaseFormNotesHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Prazo de pagamento 30 dias, lote promocional'**
  String get purchaseFormNotesHint;

  /// No description provided for @purchaseFormItemsHeader.
  ///
  /// In pt, this message translates to:
  /// **'Itens da Compra'**
  String get purchaseFormItemsHeader;

  /// No description provided for @purchaseFormAddItem.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Item'**
  String get purchaseFormAddItem;

  /// No description provided for @purchaseFormProductLabel.
  ///
  /// In pt, this message translates to:
  /// **'Produto *'**
  String get purchaseFormProductLabel;

  /// No description provided for @purchaseFormPackagingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Forma de compra'**
  String get purchaseFormPackagingLabel;

  /// No description provided for @purchaseFormBaseUnitPackaging.
  ///
  /// In pt, this message translates to:
  /// **'Sem embalagem: comprar em {unit}'**
  String purchaseFormBaseUnitPackaging(String unit);

  /// No description provided for @purchaseFormQtyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Qtd. Embalagens'**
  String get purchaseFormQtyLabel;

  /// No description provided for @purchaseFormQtyRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe a quantidade'**
  String get purchaseFormQtyRequired;

  /// No description provided for @purchaseFormUnitCostLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço Unitário (R\$)'**
  String get purchaseFormUnitCostLabel;

  /// No description provided for @purchaseFormUnitCostRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o preço unitário'**
  String get purchaseFormUnitCostRequired;

  /// No description provided for @purchaseFormTotalItem.
  ///
  /// In pt, this message translates to:
  /// **'Subtotal: {total}'**
  String purchaseFormTotalItem(String total);

  /// No description provided for @purchaseFormTotalOverall.
  ///
  /// In pt, this message translates to:
  /// **'Total Geral da Compra: {total}'**
  String purchaseFormTotalOverall(String total);

  /// No description provided for @purchaseFormSaveButton.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Compra'**
  String get purchaseFormSaveButton;

  /// No description provided for @purchaseFormSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Compra registrada com sucesso!'**
  String get purchaseFormSuccess;

  /// No description provided for @purchaseFormSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao registrar compra: {error}'**
  String purchaseFormSaveError(String error);

  /// No description provided for @purchaseFormAtLeastOneItem.
  ///
  /// In pt, this message translates to:
  /// **'Adicione ao menos um item à compra.'**
  String get purchaseFormAtLeastOneItem;

  /// No description provided for @purchaseFormConvertedStock.
  ///
  /// In pt, this message translates to:
  /// **'Equivalente em Estoque: {qty} {unit}'**
  String purchaseFormConvertedStock(int qty, String unit);

  /// No description provided for @inventorySummaryHeaderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Saldo de Estoque em Tempo Real'**
  String get inventorySummaryHeaderTitle;

  /// No description provided for @inventorySummaryHistoryTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Extrato do Razão Contábil'**
  String get inventorySummaryHistoryTooltip;

  /// No description provided for @inventorySummaryAdjustmentTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste Manual'**
  String get inventorySummaryAdjustmentTooltip;

  /// No description provided for @inventorySummarySearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por produto, categoria...'**
  String get inventorySummarySearchHint;

  /// No description provided for @inventorySummaryBelowMinFilter.
  ///
  /// In pt, this message translates to:
  /// **'Apenas Abaixo do Mínimo'**
  String get inventorySummaryBelowMinFilter;

  /// No description provided for @inventorySummaryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum item em estoque com os filtros selecionados.'**
  String get inventorySummaryEmpty;

  /// No description provided for @inventorySummaryCurrentStock.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Atual: {quantity}'**
  String inventorySummaryCurrentStock(String quantity);

  /// No description provided for @inventorySummaryMinStock.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo: {quantity}'**
  String inventorySummaryMinStock(String quantity);

  /// No description provided for @inventorySummaryAverageCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo Médio Ponderado: {cost}'**
  String inventorySummaryAverageCost(String cost);

  /// No description provided for @inventorySummaryTotalValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor em Estoque: {value}'**
  String inventorySummaryTotalValue(String value);

  /// No description provided for @inventorySummaryAdjustmentSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste de estoque registrado com sucesso!'**
  String get inventorySummaryAdjustmentSuccess;

  /// No description provided for @inventorySummaryLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar saldo de estoque: {error}'**
  String inventorySummaryLoadError(String error);

  /// No description provided for @inventorySummaryStatusOk.
  ///
  /// In pt, this message translates to:
  /// **'ESTOQUE REGULAR'**
  String get inventorySummaryStatusOk;

  /// No description provided for @inventorySummaryStatusAlert.
  ///
  /// In pt, this message translates to:
  /// **'ALERTA: ABAIXO DO MÍNIMO'**
  String get inventorySummaryStatusAlert;

  /// No description provided for @inventoryMovementsHeaderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Extrato do Razão Contábil'**
  String get inventoryMovementsHeaderTitle;

  /// No description provided for @inventoryMovementsFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos os Tipos'**
  String get inventoryMovementsFilterAll;

  /// No description provided for @inventoryMovementsFilterPurchase.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get inventoryMovementsFilterPurchase;

  /// No description provided for @inventoryMovementsFilterCancel.
  ///
  /// In pt, this message translates to:
  /// **'Estornos'**
  String get inventoryMovementsFilterCancel;

  /// No description provided for @inventoryMovementsFilterAdjustment.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes Manuais'**
  String get inventoryMovementsFilterAdjustment;

  /// No description provided for @inventoryMovementsFilterAssembly.
  ///
  /// In pt, this message translates to:
  /// **'Produção / Montagem'**
  String get inventoryMovementsFilterAssembly;

  /// No description provided for @inventoryMovementsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma movimentação registrada no livro-razão.'**
  String get inventoryMovementsEmpty;

  /// No description provided for @inventoryMovementDelta.
  ///
  /// In pt, this message translates to:
  /// **'Qtd: {delta} {unit}'**
  String inventoryMovementDelta(String delta, String unit);

  /// No description provided for @inventoryMovementBalanceAfter.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Após: {balance} {unit}'**
  String inventoryMovementBalanceAfter(String balance, String unit);

  /// No description provided for @inventoryMovementUnitPrice.
  ///
  /// In pt, this message translates to:
  /// **'Custo Unit: {price}'**
  String inventoryMovementUnitPrice(String price);

  /// No description provided for @inventoryMovementReason.
  ///
  /// In pt, this message translates to:
  /// **'Motivo: {reason}'**
  String inventoryMovementReason(String reason);

  /// No description provided for @inventoryMovementsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar extrato de movimentações: {error}'**
  String inventoryMovementsLoadError(String error);

  /// No description provided for @movementPurchase.
  ///
  /// In pt, this message translates to:
  /// **'COMPRA'**
  String get movementPurchase;

  /// No description provided for @movementPurchaseCancel.
  ///
  /// In pt, this message translates to:
  /// **'ESTORNO COMPRA'**
  String get movementPurchaseCancel;

  /// No description provided for @movementAdjustmentIn.
  ///
  /// In pt, this message translates to:
  /// **'SOBRA / ENTRADA'**
  String get movementAdjustmentIn;

  /// No description provided for @movementAdjustmentOut.
  ///
  /// In pt, this message translates to:
  /// **'AVARIA / SAÍDA'**
  String get movementAdjustmentOut;

  /// No description provided for @movementLoss.
  ///
  /// In pt, this message translates to:
  /// **'PERDA / DESCARTE'**
  String get movementLoss;

  /// No description provided for @movementAssemblyConsume.
  ///
  /// In pt, this message translates to:
  /// **'CONSUMO MONTAGEM'**
  String get movementAssemblyConsume;

  /// No description provided for @movementAssemblyProduce.
  ///
  /// In pt, this message translates to:
  /// **'CESTA MONTADA'**
  String get movementAssemblyProduce;

  /// No description provided for @movementSale.
  ///
  /// In pt, this message translates to:
  /// **'VENDA'**
  String get movementSale;

  /// No description provided for @stockAdjustmentDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste Manual de Estoque'**
  String get stockAdjustmentDialogTitle;

  /// No description provided for @stockAdjustmentProductLabel.
  ///
  /// In pt, this message translates to:
  /// **'Produto *'**
  String get stockAdjustmentProductLabel;

  /// No description provided for @stockAdjustmentTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Ajuste *'**
  String get stockAdjustmentTypeLabel;

  /// No description provided for @stockAdjustmentTypeLoss.
  ///
  /// In pt, this message translates to:
  /// **'Perda / Avaria (-)'**
  String get stockAdjustmentTypeLoss;

  /// No description provided for @stockAdjustmentTypeCount.
  ///
  /// In pt, this message translates to:
  /// **'Contagem Física (Balanço)'**
  String get stockAdjustmentTypeCount;

  /// No description provided for @stockAdjustmentQtyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade ({unit})'**
  String stockAdjustmentQtyLabel(String unit);

  /// No description provided for @stockAdjustmentQtyRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe uma quantidade válida maior que 0'**
  String get stockAdjustmentQtyRequired;

  /// No description provided for @stockAdjustmentReasonHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Quebra acidental no transporte, acerto de inventário'**
  String get stockAdjustmentReasonHint;

  /// No description provided for @stockAdjustmentReasonRequired.
  ///
  /// In pt, this message translates to:
  /// **'A justificativa é obrigatória para auditoria contábil'**
  String get stockAdjustmentReasonRequired;

  /// No description provided for @stockAdjustmentConfirmButton.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Ajuste'**
  String get stockAdjustmentConfirmButton;

  /// No description provided for @stockAdjustmentSelectProductError.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um produto.'**
  String get stockAdjustmentSelectProductError;

  /// No description provided for @pairingViewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pareamento do Dispositivo'**
  String get pairingViewTitle;

  /// No description provided for @pairingTabManual.
  ///
  /// In pt, this message translates to:
  /// **'Código PIN'**
  String get pairingTabManual;

  /// No description provided for @pairingTabQr.
  ///
  /// In pt, this message translates to:
  /// **'Escanear QR'**
  String get pairingTabQr;

  /// No description provided for @pairingPinValidation.
  ///
  /// In pt, this message translates to:
  /// **'O PIN deve conter exatamente 6 dígitos.'**
  String get pairingPinValidation;

  /// No description provided for @pairingUrlValidation.
  ///
  /// In pt, this message translates to:
  /// **'Informe o endereço IP/URL do servidor.'**
  String get pairingUrlValidation;

  /// No description provided for @pairingSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Dispositivo \"{name}\" pareado com sucesso!'**
  String pairingSuccess(String name);

  /// No description provided for @pairingError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao parear: {error}'**
  String pairingError(String error);

  /// No description provided for @pairingServerUrlHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: https://192.168.1.100:8000'**
  String get pairingServerUrlHint;

  /// No description provided for @pairingPinHint.
  ///
  /// In pt, this message translates to:
  /// **'PIN de 6 dígitos exibido no servidor'**
  String get pairingPinHint;

  /// No description provided for @pairingFingerprintHint.
  ///
  /// In pt, this message translates to:
  /// **'Fingerprint SHA256 do certificado (opcional se auto-assinado)'**
  String get pairingFingerprintHint;

  /// No description provided for @pairingDeviceNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Tablet Depósito 01'**
  String get pairingDeviceNameHint;

  /// No description provided for @pairingButton.
  ///
  /// In pt, this message translates to:
  /// **'Parear Dispositivo'**
  String get pairingButton;

  /// No description provided for @pairingQrInstructions.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmera para o QR Code de Pareamento exibido na tela do servidor central.'**
  String get pairingQrInstructions;

  /// No description provided for @pairingScanning.
  ///
  /// In pt, this message translates to:
  /// **'Processando pareamento...'**
  String get pairingScanning;

  /// No description provided for @settingsHeaderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações de Rede e Dispositivo'**
  String get settingsHeaderTitle;

  /// No description provided for @settingsServerSection.
  ///
  /// In pt, this message translates to:
  /// **'Servidor Local'**
  String get settingsServerSection;

  /// No description provided for @settingsServerUrlHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: https://192.168.1.100:8000'**
  String get settingsServerUrlHint;

  /// No description provided for @settingsFingerprintHint.
  ///
  /// In pt, this message translates to:
  /// **'Fingerprint SHA256 do certificado'**
  String get settingsFingerprintHint;

  /// No description provided for @settingsSaved.
  ///
  /// In pt, this message translates to:
  /// **'Configurações de rede salvas.'**
  String get settingsSaved;

  /// No description provided for @settingsDeviceInfoSection.
  ///
  /// In pt, this message translates to:
  /// **'Identificação do Dispositivo'**
  String get settingsDeviceInfoSection;

  /// No description provided for @settingsDeviceIdLabel.
  ///
  /// In pt, this message translates to:
  /// **'ID do Dispositivo (UUID)'**
  String get settingsDeviceIdLabel;

  /// No description provided for @settingsDeviceNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Dispositivo'**
  String get settingsDeviceNameLabel;

  /// No description provided for @settingsDeviceTokenLabel.
  ///
  /// In pt, this message translates to:
  /// **'Token de Autenticação'**
  String get settingsDeviceTokenLabel;

  /// No description provided for @settingsDeviceTokenConfigured.
  ///
  /// In pt, this message translates to:
  /// **'Configurado e Ativo'**
  String get settingsDeviceTokenConfigured;

  /// No description provided for @settingsDeviceTokenMissing.
  ///
  /// In pt, this message translates to:
  /// **'Não autenticado'**
  String get settingsDeviceTokenMissing;

  /// No description provided for @settingsSaveButton.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Configurações'**
  String get settingsSaveButton;

  /// No description provided for @settingsUnpairButton.
  ///
  /// In pt, this message translates to:
  /// **'Desvincular Dispositivo'**
  String get settingsUnpairButton;

  /// No description provided for @settingsUnpairTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Desconexão'**
  String get settingsUnpairTitle;

  /// No description provided for @settingsUnpairContent.
  ///
  /// In pt, this message translates to:
  /// **'Deseja realmente desvincular este dispositivo do servidor local?'**
  String get settingsUnpairContent;

  /// No description provided for @settingsUnpairConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Desvincular'**
  String get settingsUnpairConfirm;

  /// No description provided for @settingsUnpairedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Dispositivo desvinculado com sucesso.'**
  String get settingsUnpairedSuccess;

  /// No description provided for @settingsPairNewButton.
  ///
  /// In pt, this message translates to:
  /// **'Novo Pareamento'**
  String get settingsPairNewButton;

  /// Título da seção de geração de QR Code para celular
  ///
  /// In pt, this message translates to:
  /// **'Pareamento de Celulares / Tablets'**
  String get settingsGenerateQrTitle;

  /// Botão para gerar QR Code de pareamento
  ///
  /// In pt, this message translates to:
  /// **'Gerar QR Code para Celular'**
  String get settingsGenerateQrButton;

  /// Título do diálogo de QR Code gerado
  ///
  /// In pt, this message translates to:
  /// **'Conectar Celular / Tablet'**
  String get settingsQrDialogTitle;

  /// Instruções do diálogo de QR Code
  ///
  /// In pt, this message translates to:
  /// **'No celular Android, abra o aplicativo, toque em \'Parear Dispositivo\' > aba \'Escanear QR\' e aponte a câmera para a imagem abaixo:'**
  String get settingsQrDialogInstructions;

  /// PIN temporário de validação
  ///
  /// In pt, this message translates to:
  /// **'PIN válido por 5 minutos: {pin}'**
  String settingsPinExpiresLabel(String pin);

  /// Botão fechar do diálogo QR
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get settingsQrClose;

  /// Mensagem quando a câmera precisa ser ativada
  ///
  /// In pt, this message translates to:
  /// **'O acesso à câmera não foi permitido.'**
  String get cameraPermissionDenied;

  /// No description provided for @pairingCameraPermissionHint.
  ///
  /// In pt, this message translates to:
  /// **'Permita o acesso à câmera para ler o QR Code. Se o Android não perguntar novamente, habilite a câmera nas configurações de permissões deste aplicativo e volte para esta tela.'**
  String get pairingCameraPermissionHint;

  /// No description provided for @pairingCameraUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir a câmera. Feche outros aplicativos que estejam usando a câmera e tente novamente.'**
  String get pairingCameraUnavailable;

  /// Botão para solicitar permissão de câmera
  ///
  /// In pt, this message translates to:
  /// **'Ativar Câmera'**
  String get cameraPermissionRequest;

  /// No description provided for @purchaseDetailUnitCost.
  ///
  /// In pt, this message translates to:
  /// **'Unit.: {cost}'**
  String purchaseDetailUnitCost(String cost);

  /// No description provided for @purchaseStatusConfirmedWithStock.
  ///
  /// In pt, this message translates to:
  /// **'Confirmada (Aumenta Estoque)'**
  String get purchaseStatusConfirmedWithStock;

  /// No description provided for @purchaseStatusDraftWithoutStock.
  ///
  /// In pt, this message translates to:
  /// **'Rascunho (Sem movimentar estoque)'**
  String get purchaseStatusDraftWithoutStock;

  /// No description provided for @purchaseItemIndex.
  ///
  /// In pt, this message translates to:
  /// **'Item #{index}'**
  String purchaseItemIndex(int index);

  /// No description provided for @stockAdjustmentQtyHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 10'**
  String get stockAdjustmentQtyHint;

  /// No description provided for @categoryFood.
  ///
  /// In pt, this message translates to:
  /// **'Alimentação'**
  String get categoryFood;

  /// No description provided for @categoryCleaning.
  ///
  /// In pt, this message translates to:
  /// **'Limpeza'**
  String get categoryCleaning;

  /// No description provided for @categoryMeat.
  ///
  /// In pt, this message translates to:
  /// **'Carnes & Frios'**
  String get categoryMeat;

  /// No description provided for @categoryOthers.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get categoryOthers;

  /// No description provided for @categoryInput.
  ///
  /// In pt, this message translates to:
  /// **'Insumo'**
  String get categoryInput;

  /// No description provided for @categoryAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get categoryAll;

  /// No description provided for @categoryStandard.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get categoryStandard;

  /// No description provided for @categoryChristmas.
  ///
  /// In pt, this message translates to:
  /// **'Natalina'**
  String get categoryChristmas;

  /// No description provided for @categoryCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizada'**
  String get categoryCustom;

  /// No description provided for @recipeUnknownIngredient.
  ///
  /// In pt, this message translates to:
  /// **'Insumo ({id})'**
  String recipeUnknownIngredient(String id);

  /// No description provided for @productionBatchViewIngredients.
  ///
  /// In pt, this message translates to:
  /// **'Ver Insumos'**
  String get productionBatchViewIngredients;

  /// No description provided for @productionDisassembleNoIngredients.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum insumo registrado neste lote.'**
  String get productionDisassembleNoIngredients;

  /// No description provided for @homeLocalConnectionInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações da Conexão Local'**
  String get homeLocalConnectionInfo;

  /// No description provided for @homeApiVersionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Versão da API'**
  String get homeApiVersionLabel;

  /// No description provided for @homeDatabaseStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Banco de Dados'**
  String get homeDatabaseStatusLabel;

  /// No description provided for @homeTlsFingerprintLabel.
  ///
  /// In pt, this message translates to:
  /// **'Impressão Digital TLS (SHA-256)'**
  String get homeTlsFingerprintLabel;

  /// No description provided for @homeNotConfigured.
  ///
  /// In pt, this message translates to:
  /// **'Não configurado'**
  String get homeNotConfigured;

  /// No description provided for @homeNotAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Não disponível'**
  String get homeNotAvailable;

  /// No description provided for @homePending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get homePending;

  /// No description provided for @errorCustomerDocumentConflict.
  ///
  /// In pt, this message translates to:
  /// **'Já existe um cliente cadastrado com este documento (CPF/CNPJ).'**
  String get errorCustomerDocumentConflict;

  /// No description provided for @errorCreditLimitExceeded.
  ///
  /// In pt, this message translates to:
  /// **'Limite de crédito do cliente excedido para esta operação.'**
  String get errorCreditLimitExceeded;

  /// No description provided for @homePhase5Header.
  ///
  /// In pt, this message translates to:
  /// **'Fase 5 — Vendas, Clientes e Recebíveis'**
  String get homePhase5Header;

  /// No description provided for @homeCustomersDescription.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro de clientes, limites de crédito e histórico financeiro'**
  String get homeCustomersDescription;

  /// No description provided for @homeSalesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Vendas diretas, montagem sob demanda e vendas a prazo'**
  String get homeSalesDescription;

  /// No description provided for @homeReceivablesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Controle de fiados, vencimentos e recebimentos parciais'**
  String get homeReceivablesDescription;

  /// No description provided for @moduleCustomers.
  ///
  /// In pt, this message translates to:
  /// **'Clientes'**
  String get moduleCustomers;

  /// No description provided for @moduleSales.
  ///
  /// In pt, this message translates to:
  /// **'Vendas de Cestas'**
  String get moduleSales;

  /// No description provided for @moduleReceivables.
  ///
  /// In pt, this message translates to:
  /// **'Contas a Receber (Fiados)'**
  String get moduleReceivables;

  /// No description provided for @customersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Clientes'**
  String get customersTitle;

  /// No description provided for @customerNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo Cliente'**
  String get customerNew;

  /// No description provided for @customerEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar Cliente'**
  String get customerEdit;

  /// No description provided for @customerName.
  ///
  /// In pt, this message translates to:
  /// **'Nome / Razão Social'**
  String get customerName;

  /// No description provided for @customerDocument.
  ///
  /// In pt, this message translates to:
  /// **'CPF / CNPJ'**
  String get customerDocument;

  /// No description provided for @customerPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get customerPhone;

  /// No description provided for @customerAddress.
  ///
  /// In pt, this message translates to:
  /// **'Endereço'**
  String get customerAddress;

  /// No description provided for @customerCreditLimit.
  ///
  /// In pt, this message translates to:
  /// **'Limite de Crédito'**
  String get customerCreditLimit;

  /// No description provided for @customerCreditLimitUnlimited.
  ///
  /// In pt, this message translates to:
  /// **'Sem limite pré-definido'**
  String get customerCreditLimitUnlimited;

  /// No description provided for @customerCurrentDebt.
  ///
  /// In pt, this message translates to:
  /// **'Dívida Atual'**
  String get customerCurrentDebt;

  /// No description provided for @customerAvailableCredit.
  ///
  /// In pt, this message translates to:
  /// **'Crédito Disponível'**
  String get customerAvailableCredit;

  /// No description provided for @customerStatement.
  ///
  /// In pt, this message translates to:
  /// **'Extrato do Cliente'**
  String get customerStatement;

  /// No description provided for @customerStatementTitle.
  ///
  /// In pt, this message translates to:
  /// **'Extrato Financeiro — {name}'**
  String customerStatementTitle(String name);

  /// No description provided for @customerStatementEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma movimentação registrada para este cliente.'**
  String get customerStatementEmpty;

  /// No description provided for @customerInactivate.
  ///
  /// In pt, this message translates to:
  /// **'Inativar Cliente'**
  String get customerInactivate;

  /// No description provided for @customerInactivateConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja realmente inativar o cliente \"{name}\"?'**
  String customerInactivateConfirm(String name);

  /// No description provided for @customerActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get customerActive;

  /// No description provided for @customerInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get customerInactive;

  /// No description provided for @customerSavedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Cliente salvo com sucesso.'**
  String get customerSavedSuccess;

  /// No description provided for @customerInactivatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Cliente inativado com sucesso.'**
  String get customerInactivatedSuccess;

  /// No description provided for @customersEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum cliente cadastrado.'**
  String get customersEmpty;

  /// No description provided for @customerNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Supermercado São José'**
  String get customerNameHint;

  /// No description provided for @customerDocumentHint.
  ///
  /// In pt, this message translates to:
  /// **'CPF ou CNPJ'**
  String get customerDocumentHint;

  /// No description provided for @customerPhoneHint.
  ///
  /// In pt, this message translates to:
  /// **'(11) 99999-9999'**
  String get customerPhoneHint;

  /// No description provided for @customerAddressHint.
  ///
  /// In pt, this message translates to:
  /// **'Rua, número, bairro, cidade'**
  String get customerAddressHint;

  /// No description provided for @salesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vendas de Cestas'**
  String get salesTitle;

  /// No description provided for @saleNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova Venda'**
  String get saleNew;

  /// No description provided for @saleNumber.
  ///
  /// In pt, this message translates to:
  /// **'Venda #{number}'**
  String saleNumber(int number);

  /// No description provided for @saleDate.
  ///
  /// In pt, this message translates to:
  /// **'Data da Venda'**
  String get saleDate;

  /// No description provided for @saleCustomer.
  ///
  /// In pt, this message translates to:
  /// **'Cliente'**
  String get saleCustomer;

  /// No description provided for @saleCustomerAnonymous.
  ///
  /// In pt, this message translates to:
  /// **'Consumidor Não Identificado (Balcão)'**
  String get saleCustomerAnonymous;

  /// No description provided for @salePaymentMode.
  ///
  /// In pt, this message translates to:
  /// **'Forma de Pagamento'**
  String get salePaymentMode;

  /// No description provided for @salePaymentModeCash.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro (À Vista)'**
  String get salePaymentModeCash;

  /// No description provided for @salePaymentModePix.
  ///
  /// In pt, this message translates to:
  /// **'PIX'**
  String get salePaymentModePix;

  /// No description provided for @salePaymentModeCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão'**
  String get salePaymentModeCard;

  /// No description provided for @salePaymentModeCredit.
  ///
  /// In pt, this message translates to:
  /// **'Venda a Prazo (Fiado)'**
  String get salePaymentModeCredit;

  /// No description provided for @saleDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Data de Vencimento'**
  String get saleDueDate;

  /// No description provided for @saleDueDateSuggested.
  ///
  /// In pt, this message translates to:
  /// **'Sugerido 30 dias'**
  String get saleDueDateSuggested;

  /// No description provided for @saleItemsSection.
  ///
  /// In pt, this message translates to:
  /// **'Cestas e Composição'**
  String get saleItemsSection;

  /// No description provided for @saleAddItem.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Cesta'**
  String get saleAddItem;

  /// No description provided for @saleBasketType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Cesta'**
  String get saleBasketType;

  /// No description provided for @saleQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get saleQuantity;

  /// No description provided for @saleUnitPrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço Unitário'**
  String get saleUnitPrice;

  /// No description provided for @saleDiscount.
  ///
  /// In pt, this message translates to:
  /// **'Desconto'**
  String get saleDiscount;

  /// No description provided for @saleSubtotal.
  ///
  /// In pt, this message translates to:
  /// **'Subtotal'**
  String get saleSubtotal;

  /// No description provided for @saleAssemblyMode.
  ///
  /// In pt, this message translates to:
  /// **'Origem da Cesta'**
  String get saleAssemblyMode;

  /// No description provided for @saleAssemblyModeStock.
  ///
  /// In pt, this message translates to:
  /// **'Pronta'**
  String get saleAssemblyModeStock;

  /// No description provided for @saleAssemblyModeDemand.
  ///
  /// In pt, this message translates to:
  /// **'Montar'**
  String get saleAssemblyModeDemand;

  /// No description provided for @saleGrossTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total Bruto'**
  String get saleGrossTotal;

  /// No description provided for @saleTotalDiscount.
  ///
  /// In pt, this message translates to:
  /// **'Total de Descontos'**
  String get saleTotalDiscount;

  /// No description provided for @saleNetTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total Líquido'**
  String get saleNetTotal;

  /// No description provided for @saleStatusConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Confirmada'**
  String get saleStatusConfirmed;

  /// No description provided for @saleStatusCanceled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelada'**
  String get saleStatusCanceled;

  /// No description provided for @salePaymentStatusPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pago'**
  String get salePaymentStatusPaid;

  /// No description provided for @salePaymentStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get salePaymentStatusPending;

  /// No description provided for @salePaymentStatusPartial.
  ///
  /// In pt, this message translates to:
  /// **'Parcial'**
  String get salePaymentStatusPartial;

  /// No description provided for @saleCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar Venda'**
  String get saleCancel;

  /// No description provided for @saleCancelConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja realmente estornar a venda #{number}?'**
  String saleCancelConfirm(int number);

  /// No description provided for @saleCancelReason.
  ///
  /// In pt, this message translates to:
  /// **'Motivo do cancelamento'**
  String get saleCancelReason;

  /// No description provided for @saleCanceledSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Venda cancelada e estoque estornado com sucesso.'**
  String get saleCanceledSuccess;

  /// No description provided for @saleCreatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Venda registrada com sucesso.'**
  String get saleCreatedSuccess;

  /// No description provided for @saleCreditLimitAlertTitle.
  ///
  /// In pt, this message translates to:
  /// **'Limite de Crédito Excedido'**
  String get saleCreditLimitAlertTitle;

  /// No description provided for @saleCreditLimitAlertMessage.
  ///
  /// In pt, this message translates to:
  /// **'O valor da venda excede o limite de crédito do cliente em {amount}. Deseja autorizar a liberação manual desta venda?'**
  String saleCreditLimitAlertMessage(String amount);

  /// No description provided for @saleCreditLimitAuthorize.
  ///
  /// In pt, this message translates to:
  /// **'Autorizar e Concluir Venda'**
  String get saleCreditLimitAuthorize;

  /// No description provided for @saleStockAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Cestas prontas disponíveis: {qty}'**
  String saleStockAvailable(int qty);

  /// No description provided for @salesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma venda registrada.'**
  String get salesEmpty;

  /// No description provided for @saleCreditCustomerRequired.
  ///
  /// In pt, this message translates to:
  /// **'Vendas a prazo (fiado) exigem a seleção de um cliente cadastrado.'**
  String get saleCreditCustomerRequired;

  /// No description provided for @saleSelectBasketTypeRequired.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a cesta para todos os itens.'**
  String get saleSelectBasketTypeRequired;

  /// No description provided for @saleQuantityMustBePositive.
  ///
  /// In pt, this message translates to:
  /// **'A quantidade deve ser maior que zero.'**
  String get saleQuantityMustBePositive;

  /// No description provided for @saleInsufficientStockAlert.
  ///
  /// In pt, this message translates to:
  /// **'Estoque insuficiente de cestas prontas para \"{name}\". Saldo: {stock}, Solicitado: {qty}. Marque \"Montar Imediatamente\" para produzir na hora.'**
  String saleInsufficientStockAlert(String name, int stock, int qty);

  /// No description provided for @saleAnonymousCustomerHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome do cliente no balcão (opcional)'**
  String get saleAnonymousCustomerHint;

  /// No description provided for @saleCmvAndMargin.
  ///
  /// In pt, this message translates to:
  /// **'CMV: {cmv} | Margem: {margin}'**
  String saleCmvAndMargin(String cmv, String margin);

  /// No description provided for @saleNotesPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Obs: {notes}'**
  String saleNotesPrefix(String notes);

  /// No description provided for @receivablesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contas a Receber (Fiados)'**
  String get receivablesTitle;

  /// No description provided for @receivablesSummaryTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total a Receber'**
  String get receivablesSummaryTotal;

  /// No description provided for @receivablesSummaryOpen.
  ///
  /// In pt, this message translates to:
  /// **'Títulos em Aberto'**
  String get receivablesSummaryOpen;

  /// No description provided for @receivablesSummaryPartial.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos Parciais'**
  String get receivablesSummaryPartial;

  /// No description provided for @receivablesSummaryPaid.
  ///
  /// In pt, this message translates to:
  /// **'Títulos Quitados'**
  String get receivablesSummaryPaid;

  /// No description provided for @receivableOriginalAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor Original'**
  String get receivableOriginalAmount;

  /// No description provided for @receivablePaidAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor Pago'**
  String get receivablePaidAmount;

  /// No description provided for @receivableRemainingBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Devedor'**
  String get receivableRemainingBalance;

  /// No description provided for @receivableDueDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento: {date}'**
  String receivableDueDateLabel(String date);

  /// No description provided for @receivableOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Vencido'**
  String get receivableOverdue;

  /// No description provided for @receivableRecordPayment.
  ///
  /// In pt, this message translates to:
  /// **'Receber Pagamento'**
  String get receivableRecordPayment;

  /// No description provided for @receivablePaymentAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor a Receber'**
  String get receivablePaymentAmount;

  /// No description provided for @receivablePaymentMethod.
  ///
  /// In pt, this message translates to:
  /// **'Meio de Recebimento'**
  String get receivablePaymentMethod;

  /// No description provided for @receivablePaymentNotes.
  ///
  /// In pt, this message translates to:
  /// **'Observações do Pagamento'**
  String get receivablePaymentNotes;

  /// No description provided for @receivablePaymentSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Recebimento registrado com sucesso.'**
  String get receivablePaymentSuccess;

  /// No description provided for @receivablePaymentsHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Amortizações'**
  String get receivablePaymentsHistory;

  /// No description provided for @receivableNoPayments.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum pagamento registrado ainda.'**
  String get receivableNoPayments;

  /// No description provided for @receivableStatusOpen.
  ///
  /// In pt, this message translates to:
  /// **'Em Aberto'**
  String get receivableStatusOpen;

  /// No description provided for @receivableStatusPartial.
  ///
  /// In pt, this message translates to:
  /// **'Parcialmente Pago'**
  String get receivableStatusPartial;

  /// No description provided for @receivableStatusPaid.
  ///
  /// In pt, this message translates to:
  /// **'Quitado'**
  String get receivableStatusPaid;

  /// No description provided for @receivableStatusCanceled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get receivableStatusCanceled;

  /// No description provided for @receivablesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum título a receber encontrado.'**
  String get receivablesEmpty;

  /// No description provided for @receivablePaymentAmountMustBePositive.
  ///
  /// In pt, this message translates to:
  /// **'Informe um valor maior que zero.'**
  String get receivablePaymentAmountMustBePositive;

  /// No description provided for @receivablePaymentAmountExceedsBalance.
  ///
  /// In pt, this message translates to:
  /// **'Valor informado excede o saldo devedor.'**
  String get receivablePaymentAmountExceedsBalance;

  /// No description provided for @homePhase6Header.
  ///
  /// In pt, this message translates to:
  /// **'Fase 6: Expedição, Conferência e Custódia'**
  String get homePhase6Header;

  /// No description provided for @moduleDispatches.
  ///
  /// In pt, this message translates to:
  /// **'Saídas e Conferências'**
  String get moduleDispatches;

  /// No description provided for @moduleResponsiblePersons.
  ///
  /// In pt, this message translates to:
  /// **'Pessoas Responsáveis'**
  String get moduleResponsiblePersons;

  /// No description provided for @homeResponsiblePersonsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro de entregadores, vendedores externos e motoristas'**
  String get homeResponsiblePersonsDescription;

  /// No description provided for @responsiblePersonsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pessoas Responsáveis'**
  String get responsiblePersonsTitle;

  /// No description provided for @responsiblePersonName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get responsiblePersonName;

  /// No description provided for @responsiblePersonCustodyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Custódia Atual de Cestas'**
  String get responsiblePersonCustodyTitle;

  /// No description provided for @dispatchesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Saídas Físicas e Conferência'**
  String get dispatchesTitle;

  /// No description provided for @dispatchNumber.
  ///
  /// In pt, this message translates to:
  /// **'Saída #{number}'**
  String dispatchNumber(int number);

  /// No description provided for @dispatchDate.
  ///
  /// In pt, this message translates to:
  /// **'Data da Saída'**
  String get dispatchDate;

  /// No description provided for @dispatchStatusResolved.
  ///
  /// In pt, this message translates to:
  /// **'Resolvido'**
  String get dispatchStatusResolved;

  /// No description provided for @dispatchDuplicateBasketConsolidatedNotice.
  ///
  /// In pt, this message translates to:
  /// **'Cesta repetida: será consolidada automaticamente no despacho.'**
  String get dispatchDuplicateBasketConsolidatedNotice;

  /// No description provided for @conferencePhysicalEquationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Equação Física de Custódia (4 Termos)'**
  String get conferencePhysicalEquationTitle;

  /// No description provided for @conferenceDispatchedLabel.
  ///
  /// In pt, this message translates to:
  /// **'1. Retiradas: {qty}'**
  String conferenceDispatchedLabel(int qty);

  /// No description provided for @conferenceSoldLabel.
  ///
  /// In pt, this message translates to:
  /// **'2. Vendidas: {qty}'**
  String conferenceSoldLabel(int qty);

  /// No description provided for @conferenceReturnedLabel.
  ///
  /// In pt, this message translates to:
  /// **'3. Devolvidas Intactas: {qty}'**
  String conferenceReturnedLabel(int qty);

  /// No description provided for @conferenceLostLabel.
  ///
  /// In pt, this message translates to:
  /// **'4. Avariadas / Perdidas: {qty}'**
  String conferenceLostLabel(int qty);

  /// No description provided for @conferencePhysicalEquationBalanced.
  ///
  /// In pt, this message translates to:
  /// **'Equação Física Bateu (Sem divergências)'**
  String get conferencePhysicalEquationBalanced;

  /// No description provided for @conferencePhysicalEquationDivergent.
  ///
  /// In pt, this message translates to:
  /// **'Divergência Física Detectada!'**
  String get conferencePhysicalEquationDivergent;

  /// No description provided for @conferenceExpectedCashLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro em Mãos Esperado: {amount}'**
  String conferenceExpectedCashLabel(String amount);

  /// No description provided for @conferenceFinancialDivergent.
  ///
  /// In pt, this message translates to:
  /// **'Divergência Financeira Detectada!'**
  String get conferenceFinancialDivergent;

  /// No description provided for @conferenceFinancialBalanced.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro Bateu (Repasse integral)'**
  String get conferenceFinancialBalanced;

  /// No description provided for @conferenceDirectNotice.
  ///
  /// In pt, this message translates to:
  /// **'* Pix e cartões recebidos diretamente na conta da empresa NÃO são devidos pelo motorista/entregador.'**
  String get conferenceDirectNotice;

  /// No description provided for @conferenceExpenseExceedsNotice.
  ///
  /// In pt, this message translates to:
  /// **'As despesas autorizadas superaram as vendas em dinheiro da rota. Saldo credor ao entregador / ressarcimento pela empresa.'**
  String get conferenceExpenseExceedsNotice;

  /// No description provided for @saleCustodyStockAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Saldo sob custódia: {qty}'**
  String saleCustodyStockAvailable(int qty);

  /// No description provided for @homePhase7Header.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro'**
  String get homePhase7Header;

  /// No description provided for @modulePayables.
  ///
  /// In pt, this message translates to:
  /// **'Contas a Pagar'**
  String get modulePayables;

  /// No description provided for @homePayablesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Boletos, cheques, empréstimos, fornecedores e parcelamentos'**
  String get homePayablesDescription;

  /// No description provided for @payablesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contas a Pagar'**
  String get payablesTitle;

  /// No description provided for @payablesNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova Obrigação a Pagar'**
  String get payablesNew;

  /// No description provided for @payableDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get payableDescription;

  /// No description provided for @payableBeneficiary.
  ///
  /// In pt, this message translates to:
  /// **'Favorecido / Fornecedor'**
  String get payableBeneficiary;

  /// No description provided for @payableCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get payableCategory;

  /// No description provided for @payableNature.
  ///
  /// In pt, this message translates to:
  /// **'Natureza'**
  String get payableNature;

  /// No description provided for @payableNatureBusiness.
  ///
  /// In pt, this message translates to:
  /// **'Operacional (Empresa)'**
  String get payableNatureBusiness;

  /// No description provided for @payableNaturePersonal.
  ///
  /// In pt, this message translates to:
  /// **'Retirada Particular (Sócios)'**
  String get payableNaturePersonal;

  /// No description provided for @payableOriginalAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor Nominal'**
  String get payableOriginalAmount;

  /// No description provided for @payablePaidAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor Pago'**
  String get payablePaidAmount;

  /// No description provided for @payableBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Devedor'**
  String get payableBalance;

  /// No description provided for @payableDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento'**
  String get payableDueDate;

  /// No description provided for @payablePaymentMethod.
  ///
  /// In pt, this message translates to:
  /// **'Forma de Pagamento'**
  String get payablePaymentMethod;

  /// No description provided for @payableStatus.
  ///
  /// In pt, this message translates to:
  /// **'Situação'**
  String get payableStatus;

  /// No description provided for @payableStatusOpen.
  ///
  /// In pt, this message translates to:
  /// **'Em Aberto'**
  String get payableStatusOpen;

  /// No description provided for @payableStatusPartial.
  ///
  /// In pt, this message translates to:
  /// **'Parcialmente Pago'**
  String get payableStatusPartial;

  /// No description provided for @payableStatusPaid.
  ///
  /// In pt, this message translates to:
  /// **'Quitado'**
  String get payableStatusPaid;

  /// No description provided for @payableStatusCanceled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get payableStatusCanceled;

  /// No description provided for @payableOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Vencido'**
  String get payableOverdue;

  /// No description provided for @payableInstallment.
  ///
  /// In pt, this message translates to:
  /// **'Parcela {current} de {total}'**
  String payableInstallment(int current, int total);

  /// No description provided for @payableRecurrent.
  ///
  /// In pt, this message translates to:
  /// **'Despesa Recorrente'**
  String get payableRecurrent;

  /// No description provided for @payableRecurrenceMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get payableRecurrenceMonthly;

  /// No description provided for @payableRecurrenceWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get payableRecurrenceWeekly;

  /// No description provided for @payableRecurrenceYearly.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get payableRecurrenceYearly;

  /// No description provided for @payableTotalInstallments.
  ///
  /// In pt, this message translates to:
  /// **'Total de Parcelas'**
  String get payableTotalInstallments;

  /// No description provided for @payablePaymentAction.
  ///
  /// In pt, this message translates to:
  /// **'Pagar / Amortizar'**
  String get payablePaymentAction;

  /// No description provided for @payableHistoryAction.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Pagamentos'**
  String get payableHistoryAction;

  /// No description provided for @payableCancelAction.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar Obrigação'**
  String get payableCancelAction;

  /// No description provided for @payableCancelReason.
  ///
  /// In pt, this message translates to:
  /// **'Motivo do cancelamento'**
  String get payableCancelReason;

  /// No description provided for @payableCancelConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar cancelamento do título'**
  String get payableCancelConfirm;

  /// No description provided for @payablePaymentSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento registrado com sucesso'**
  String get payablePaymentSuccess;

  /// No description provided for @payableCancelSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Título cancelado com sucesso'**
  String get payableCancelSuccess;

  /// No description provided for @payableReversePaymentSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento estornado com sucesso'**
  String get payableReversePaymentSuccess;

  /// No description provided for @payablePaymentAmountExceedsBalance.
  ///
  /// In pt, this message translates to:
  /// **'O valor informado excede o saldo devedor.'**
  String get payablePaymentAmountExceedsBalance;

  /// No description provided for @payablePaymentAmountMustBePositive.
  ///
  /// In pt, this message translates to:
  /// **'O valor do pagamento deve ser maior que zero.'**
  String get payablePaymentAmountMustBePositive;

  /// No description provided for @payableNoPayables.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma obrigação a pagar encontrada.'**
  String get payableNoPayables;

  /// No description provided for @payableFilterMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get payableFilterMonth;

  /// No description provided for @payableFilterYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get payableFilterYear;

  /// No description provided for @treasuryOpenPayables.
  ///
  /// In pt, this message translates to:
  /// **'A Pagar (Obrigações Abertas)'**
  String get treasuryOpenPayables;

  /// No description provided for @treasuryOverduePayables.
  ///
  /// In pt, this message translates to:
  /// **'A Pagar Vencidos'**
  String get treasuryOverduePayables;

  /// No description provided for @receivableRepassDirect.
  ///
  /// In pt, this message translates to:
  /// **'Direto na Empresa / Loja'**
  String get receivableRepassDirect;

  /// No description provided for @receivableRepassPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente de Repasse (Dinheiro em Rota)'**
  String get receivableRepassPending;

  /// No description provided for @receivableRepassDone.
  ///
  /// In pt, this message translates to:
  /// **'Repassado e Liquidado'**
  String get receivableRepassDone;

  /// No description provided for @receivableReversePayment.
  ///
  /// In pt, this message translates to:
  /// **'Estornar Recebimento'**
  String get receivableReversePayment;

  /// No description provided for @receivableReverseReason.
  ///
  /// In pt, this message translates to:
  /// **'Justificativa do estorno do recebimento'**
  String get receivableReverseReason;

  /// No description provided for @receivableReverseSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Recebimento estornado com sucesso'**
  String get receivableReverseSuccess;

  /// No description provided for @payableGenerateNextRecurrence.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Próxima Recorrência'**
  String get payableGenerateNextRecurrence;

  /// No description provided for @payableRecurrenceSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Nova parcela de recorrência gerada com sucesso!'**
  String get payableRecurrenceSuccess;

  /// No description provided for @payableFilterPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período de Vencimento'**
  String get payableFilterPeriod;

  /// No description provided for @payableFilterPeriodAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos os períodos'**
  String get payableFilterPeriodAll;

  /// No description provided for @receivableFilterPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período da Venda'**
  String get receivableFilterPeriod;

  /// No description provided for @receivableFilterDuePeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período do Vencimento'**
  String get receivableFilterDuePeriod;

  /// No description provided for @receivableFilterCustomer.
  ///
  /// In pt, this message translates to:
  /// **'Cliente'**
  String get receivableFilterCustomer;

  /// No description provided for @receivableFilterBasketType.
  ///
  /// In pt, this message translates to:
  /// **'Cesta'**
  String get receivableFilterBasketType;

  /// No description provided for @receivableFilterMinValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor Mínimo'**
  String get receivableFilterMinValue;

  /// No description provided for @receivableFilterMaxValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor Máximo'**
  String get receivableFilterMaxValue;

  /// No description provided for @receivableFilterAdvanced.
  ///
  /// In pt, this message translates to:
  /// **'Filtros Avançados'**
  String get receivableFilterAdvanced;

  /// No description provided for @receivableFilterHideAdvanced.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar Filtros'**
  String get receivableFilterHideAdvanced;

  /// No description provided for @receivableFilterClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar Filtros'**
  String get receivableFilterClear;

  /// No description provided for @receivableFilterApply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar Filtros'**
  String get receivableFilterApply;

  /// No description provided for @homePhase8Header.
  ///
  /// In pt, this message translates to:
  /// **'Fase 8: Dashboard, Relatórios, Planilhas e Impressão'**
  String get homePhase8Header;

  /// No description provided for @moduleDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard Geral'**
  String get moduleDashboard;

  /// No description provided for @homeDashboardDescription.
  ///
  /// In pt, this message translates to:
  /// **'Vendas, estoque, recebimentos, pagamentos e resultado'**
  String get homeDashboardDescription;

  /// No description provided for @moduleReports.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios & Planilhas'**
  String get moduleReports;

  /// No description provided for @homeReportsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Consultas analíticas, exportação CSV/XLSX e impressão PDF'**
  String get homeReportsDescription;

  /// No description provided for @moduleBlankForms.
  ///
  /// In pt, this message translates to:
  /// **'Formulários A4 & Impressão'**
  String get moduleBlankForms;

  /// No description provided for @homeBlankFormsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Modelos em branco para prancheta e folhas preenchidas para auditoria'**
  String get homeBlankFormsDescription;

  /// No description provided for @dashboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard Operacional e Financeiro'**
  String get dashboardTitle;

  /// No description provided for @dashboardFilterToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get dashboardFilterToday;

  /// No description provided for @dashboardFilterDate.
  ///
  /// In pt, this message translates to:
  /// **'Data Específica'**
  String get dashboardFilterDate;

  /// No description provided for @dashboardFilterRange.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo'**
  String get dashboardFilterRange;

  /// No description provided for @dashboardFilterMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get dashboardFilterMonth;

  /// No description provided for @dashboardFilterYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get dashboardFilterYear;

  /// No description provided for @dashboardFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get dashboardFilterAll;

  /// No description provided for @dashboardSectionProduction.
  ///
  /// In pt, this message translates to:
  /// **'Produção & Montagem'**
  String get dashboardSectionProduction;

  /// No description provided for @dashboardAssembledBaskets.
  ///
  /// In pt, this message translates to:
  /// **'Cestas Montadas'**
  String get dashboardAssembledBaskets;

  /// No description provided for @dashboardSectionSales.
  ///
  /// In pt, this message translates to:
  /// **'Vendas & Faturamento'**
  String get dashboardSectionSales;

  /// No description provided for @dashboardSoldBaskets.
  ///
  /// In pt, this message translates to:
  /// **'Cestas Vendidas'**
  String get dashboardSoldBaskets;

  /// No description provided for @dashboardTotalSold.
  ///
  /// In pt, this message translates to:
  /// **'Valor Total Vendido'**
  String get dashboardTotalSold;

  /// No description provided for @dashboardSectionDispatches.
  ///
  /// In pt, this message translates to:
  /// **'Expedição & Rotas'**
  String get dashboardSectionDispatches;

  /// No description provided for @dashboardDispatchedBaskets.
  ///
  /// In pt, this message translates to:
  /// **'Cestas em Saída'**
  String get dashboardDispatchedBaskets;

  /// No description provided for @dashboardUnremittedCash.
  ///
  /// In pt, this message translates to:
  /// **'Repasses de Rota Pendentes'**
  String get dashboardUnremittedCash;

  /// No description provided for @dashboardPendingDivergences.
  ///
  /// In pt, this message translates to:
  /// **'Divergências Pendentes'**
  String get dashboardPendingDivergences;

  /// No description provided for @dashboardSectionInventory.
  ///
  /// In pt, this message translates to:
  /// **'Estoque & Alertas'**
  String get dashboardSectionInventory;

  /// No description provided for @dashboardLowStockAlert.
  ///
  /// In pt, this message translates to:
  /// **'Itens Abaixo do Mínimo'**
  String get dashboardLowStockAlert;

  /// No description provided for @dashboardStockNormal.
  ///
  /// In pt, this message translates to:
  /// **'Estoque em Nível Regular'**
  String get dashboardStockNormal;

  /// No description provided for @dashboardOverdueReceivables.
  ///
  /// In pt, this message translates to:
  /// **'A Receber Vencidos'**
  String get dashboardOverdueReceivables;

  /// No description provided for @dashboardOverduePayables.
  ///
  /// In pt, this message translates to:
  /// **'A Pagar Vencidos'**
  String get dashboardOverduePayables;

  /// No description provided for @dashboardCashInflow.
  ///
  /// In pt, this message translates to:
  /// **'Entradas de Caixa'**
  String get dashboardCashInflow;

  /// No description provided for @dashboardCashOutflow.
  ///
  /// In pt, this message translates to:
  /// **'Saídas de Caixa'**
  String get dashboardCashOutflow;

  /// No description provided for @dashboardTreasuryBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Disponível (Tesouraria)'**
  String get dashboardTreasuryBalance;

  /// No description provided for @reportsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios Gerenciais e Planilhas'**
  String get reportsTitle;

  /// No description provided for @reportSalesDispatches.
  ///
  /// In pt, this message translates to:
  /// **'Vendas e Saídas de Cestas'**
  String get reportSalesDispatches;

  /// No description provided for @reportAssembly.
  ///
  /// In pt, this message translates to:
  /// **'Montagem e Produção de Cestas'**
  String get reportAssembly;

  /// No description provided for @reportPurchasesMovements.
  ///
  /// In pt, this message translates to:
  /// **'Compras e Movimentações do Razão'**
  String get reportPurchasesMovements;

  /// No description provided for @reportReceivables.
  ///
  /// In pt, this message translates to:
  /// **'Contas a Receber, Pagamentos e Quitações'**
  String get reportReceivables;

  /// No description provided for @reportPayables.
  ///
  /// In pt, this message translates to:
  /// **'Contas a Pagar, Vencimentos e Pagamentos'**
  String get reportPayables;

  /// No description provided for @reportDispatchSettlements.
  ///
  /// In pt, this message translates to:
  /// **'Conferência de Saídas e Repasses de Rota'**
  String get reportDispatchSettlements;

  /// No description provided for @reportPhysicalInventory.
  ///
  /// In pt, this message translates to:
  /// **'Estoque Atual e Contagem Física'**
  String get reportPhysicalInventory;

  /// No description provided for @reportFinancialSummary.
  ///
  /// In pt, this message translates to:
  /// **'DRE Gerencial e Demonstrativo Financeiro'**
  String get reportFinancialSummary;

  /// No description provided for @reportExportCsv.
  ///
  /// In pt, this message translates to:
  /// **'Exportar CSV'**
  String get reportExportCsv;

  /// No description provided for @reportExportXlsx.
  ///
  /// In pt, this message translates to:
  /// **'Exportar XLSX'**
  String get reportExportXlsx;

  /// No description provided for @reportPrintPdf.
  ///
  /// In pt, this message translates to:
  /// **'Imprimir / PDF A4'**
  String get reportPrintPdf;

  /// No description provided for @reportEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum registro encontrado para os filtros selecionados.'**
  String get reportEmpty;

  /// No description provided for @reportTotals.
  ///
  /// In pt, this message translates to:
  /// **'Totais Consolidados'**
  String get reportTotals;

  /// No description provided for @blankFormsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Formulários A4 para Impressão'**
  String get blankFormsTitle;

  /// No description provided for @blankFormsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Modelos em branco para preenchimento manual à caneta e folhas para auditoria física'**
  String get blankFormsSubtitle;

  /// No description provided for @formTypePayments.
  ///
  /// In pt, this message translates to:
  /// **'Tabela de Pagamentos de Cestas (Fiados / Quitações)'**
  String get formTypePayments;

  /// No description provided for @formTypePayables.
  ///
  /// In pt, this message translates to:
  /// **'Tabela de Contas a Pagar e Vencimentos'**
  String get formTypePayables;

  /// No description provided for @formTypeDispatch.
  ///
  /// In pt, this message translates to:
  /// **'Folha de Conferência de Saídas e Custódia'**
  String get formTypeDispatch;

  /// No description provided for @formTypeInventory.
  ///
  /// In pt, this message translates to:
  /// **'Folha de Contagem Física (Auditoria / Balanço)'**
  String get formTypeInventory;

  /// No description provided for @formModeBlank.
  ///
  /// In pt, this message translates to:
  /// **'Formulário em Branco (Para Caneta)'**
  String get formModeBlank;

  /// No description provided for @formModeFilled.
  ///
  /// In pt, this message translates to:
  /// **'Documento Preenchido (Auditoria Física)'**
  String get formModeFilled;

  /// No description provided for @formActionPrint.
  ///
  /// In pt, this message translates to:
  /// **'Visualizar e Imprimir A4'**
  String get formActionPrint;

  /// No description provided for @formActionDownloadXlsx.
  ///
  /// In pt, this message translates to:
  /// **'Baixar Modelo XLSX Vazio'**
  String get formActionDownloadXlsx;

  /// No description provided for @formBlankNotice.
  ///
  /// In pt, this message translates to:
  /// **'Modelos formatados com linhas amplas (mínimo de 8 a 10 mm) para escrita manual confortável em prancheta.'**
  String get formBlankNotice;

  /// Mensagem de sucesso ao baixar modelo ou auditoria XLSX
  ///
  /// In pt, this message translates to:
  /// **'Planilha XLSX baixada com sucesso: {filename}'**
  String formXlsxDownloadSuccess(String filename);

  /// Mensagem de erro ao baixar modelo ou auditoria XLSX
  ///
  /// In pt, this message translates to:
  /// **'Erro ao baixar planilha: {error}'**
  String formXlsxDownloadError(String error);

  /// Mensagem durante busca de impressoras
  ///
  /// In pt, this message translates to:
  /// **'Localizando impressoras instaladas...'**
  String get printerLocating;

  /// Badge de impressora padrão do sistema operacional
  ///
  /// In pt, this message translates to:
  /// **'Padrão do Sistema'**
  String get printerSystemDefault;

  /// Badge de impressora online/disponível
  ///
  /// In pt, this message translates to:
  /// **'Disponível'**
  String get printerAvailable;

  /// Botão de impressão direta
  ///
  /// In pt, this message translates to:
  /// **'Imprimir'**
  String get printerActionPrint;

  /// Mensagem de sucesso ao exportar relatório em CSV ou XLSX
  ///
  /// In pt, this message translates to:
  /// **'Planilha {format} exportada com sucesso!'**
  String reportExportSuccess(String format);

  /// Mensagem de erro ao exportar relatório
  ///
  /// In pt, this message translates to:
  /// **'Erro ao exportar {format}: {error}'**
  String reportExportError(String format, String error);

  /// Label com a data selecionada
  ///
  /// In pt, this message translates to:
  /// **'Data: {date}'**
  String commonSelectedDateLabel(String date);

  /// Botão para alterar data ou período
  ///
  /// In pt, this message translates to:
  /// **'Alterar'**
  String get commonChange;

  /// Label com intervalo de datas
  ///
  /// In pt, this message translates to:
  /// **'Período: {start} até {end}'**
  String commonPeriodLabel(String start, String end);

  /// Exibição do número do mês
  ///
  /// In pt, this message translates to:
  /// **'Mês {month}'**
  String commonMonthNumber(int month);

  /// Rótulo do seletor de ano
  ///
  /// In pt, this message translates to:
  /// **'Ano:'**
  String get commonYearLabel;

  /// Filtro de contagem física
  ///
  /// In pt, this message translates to:
  /// **'Exibir apenas itens abaixo do estoque mínimo'**
  String get reportPhysicalBelowMinOnly;

  /// Data selecionada no dashboard
  ///
  /// In pt, this message translates to:
  /// **'Data selecionada: {date}'**
  String dashboardSelectedDate(String date);

  /// Título da lista de lotes com contagem
  ///
  /// In pt, this message translates to:
  /// **'Lotes ({count})'**
  String dashboardBatchesCount(int count);

  /// Estado vazio da lista de lotes
  ///
  /// In pt, this message translates to:
  /// **'Nenhum lote montado no período.'**
  String get dashboardNoBatches;

  /// Título da lista de vendas com contagem
  ///
  /// In pt, this message translates to:
  /// **'Vendas ({count})'**
  String dashboardSalesCount(int count);

  /// Estado vazio da lista de vendas
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma venda registrada no período.'**
  String get dashboardNoSales;

  /// Título da lista de saídas com contagem
  ///
  /// In pt, this message translates to:
  /// **'Saídas ({count})'**
  String dashboardDispatchesCount(int count);

  /// Botão de conferência com divergências pendentes
  ///
  /// In pt, this message translates to:
  /// **'Examinar Divergências Pendentes ({count})'**
  String dashboardExaminePendingDivergences(int count);

  /// Estado vazio de saídas
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma saída registrada no período.'**
  String get dashboardNoDispatches;

  /// Subtítulo do item de saída no dashboard
  ///
  /// In pt, this message translates to:
  /// **'Data: {date} | Cestas: {baskets} un.'**
  String dashboardDispatchItemSubtitle(String date, int baskets);

  /// Estado vazio de valores retidos por responsáveis
  ///
  /// In pt, this message translates to:
  /// **'Nenhum valor retido por responsável no momento.'**
  String get dashboardNoRetainedValues;

  /// Telefone do responsável
  ///
  /// In pt, this message translates to:
  /// **'Tel: {phone}'**
  String dashboardResponsiblePhone(String phone);

  /// Data da saída do responsável
  ///
  /// In pt, this message translates to:
  /// **'Data: {date}'**
  String dashboardResponsibleDate(String date);

  /// Estado vazio de divergências
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma divergência pendente.'**
  String get dashboardNoDivergences;

  /// Data e hora do acerto da divergência
  ///
  /// In pt, this message translates to:
  /// **'Acerto em: {date}'**
  String dashboardSettledAt(String date);

  /// Observações prefixadas
  ///
  /// In pt, this message translates to:
  /// **'Obs: {notes}'**
  String commonNotesPrefix(String notes);

  /// Coluna Cesta no cabeçalho de estoque
  ///
  /// In pt, this message translates to:
  /// **'Cesta'**
  String get dashboardStockColBasket;

  /// Coluna Loja no cabeçalho de estoque
  ///
  /// In pt, this message translates to:
  /// **'Loja'**
  String get dashboardStockColStore;

  /// Coluna Trânsito no cabeçalho de estoque
  ///
  /// In pt, this message translates to:
  /// **'Trânsito'**
  String get dashboardStockColTransit;

  /// Coluna Total no cabeçalho de estoque
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get dashboardStockColTotal;

  /// Alerta de que não há insumos em falta
  ///
  /// In pt, this message translates to:
  /// **'Todos os itens estão acima do estoque mínimo.'**
  String get dashboardAllAboveMinStock;

  /// Código SKU do item
  ///
  /// In pt, this message translates to:
  /// **'SKU: {sku}'**
  String dashboardItemSku(String sku);

  /// Contagem de lançamentos de caixa
  ///
  /// In pt, this message translates to:
  /// **'Caixa ({count})'**
  String dashboardCashRecordsCount(int count);

  /// Total de entradas financeiras previstas
  ///
  /// In pt, this message translates to:
  /// **'Entradas Previstas: {amount}'**
  String dashboardProjectedInflow(String amount);

  /// Total de saídas financeiras previstas
  ///
  /// In pt, this message translates to:
  /// **'Saídas Previstas: {amount}'**
  String dashboardProjectedOutflow(String amount);

  /// Estado vazio do extrato de caixa
  ///
  /// In pt, this message translates to:
  /// **'Nenhum lançamento no período.'**
  String get dashboardNoCashRecords;

  /// Estado vazio de títulos a receber
  ///
  /// In pt, this message translates to:
  /// **'Nenhum título a receber em aberto.'**
  String get dashboardNoOpenReceivables;

  /// Estado vazio de contas a pagar
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta a pagar em aberto.'**
  String get dashboardNoOpenPayables;

  /// Categoria de conta: Fornecedor
  ///
  /// In pt, this message translates to:
  /// **'Fornecedor'**
  String get payableCategorySupplier;

  /// Categoria de conta: Energia Elétrica
  ///
  /// In pt, this message translates to:
  /// **'Energia Elétrica'**
  String get payableCategoryElectricity;

  /// Categoria de conta: Aluguel
  ///
  /// In pt, this message translates to:
  /// **'Aluguel'**
  String get payableCategoryRent;

  /// Categoria de conta: Frete / Logística
  ///
  /// In pt, this message translates to:
  /// **'Frete / Logística'**
  String get payableCategoryFreight;

  /// Categoria de conta: Frete simplificado
  ///
  /// In pt, this message translates to:
  /// **'Frete'**
  String get payableCategoryFreightShort;

  /// Categoria de conta: Manutenção
  ///
  /// In pt, this message translates to:
  /// **'Manutenção'**
  String get payableCategoryMaintenance;

  /// Categoria de conta: Empréstimo
  ///
  /// In pt, this message translates to:
  /// **'Empréstimo'**
  String get payableCategoryLoan;

  /// Categoria de conta: Cartão de Crédito
  ///
  /// In pt, this message translates to:
  /// **'Cartão de Crédito'**
  String get payableCategoryCreditCard;

  /// Categoria de conta: Retirada de Sócios
  ///
  /// In pt, this message translates to:
  /// **'Retirada Sócios'**
  String get payableCategoryPartnerWithdrawal;

  /// Categoria de conta: Impostos / Taxas
  ///
  /// In pt, this message translates to:
  /// **'Impostos / Taxas'**
  String get payableCategoryTaxes;

  /// Categoria de conta: Impostos simplificado
  ///
  /// In pt, this message translates to:
  /// **'Impostos'**
  String get payableCategoryTaxesShort;

  /// Categoria de conta: Outros
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get payableCategoryOthers;

  /// Forma de pagamento de despesa: Boleto
  ///
  /// In pt, this message translates to:
  /// **'Boleto'**
  String get payablePaymentMethodBoleto;

  /// Forma de pagamento de despesa: PIX
  ///
  /// In pt, this message translates to:
  /// **'PIX'**
  String get payablePaymentMethodPix;

  /// Forma de pagamento de despesa: Transferência
  ///
  /// In pt, this message translates to:
  /// **'Transferência'**
  String get payablePaymentMethodTransfer;

  /// Forma de pagamento de despesa: Cheque
  ///
  /// In pt, this message translates to:
  /// **'Cheque'**
  String get payablePaymentMethodCheck;

  /// Forma de pagamento de despesa: Cartão de Crédito
  ///
  /// In pt, this message translates to:
  /// **'Cartão de Crédito'**
  String get payablePaymentMethodCard;

  /// Forma de pagamento de despesa: Dinheiro
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro'**
  String get payablePaymentMethodCash;

  /// Forma de pagamento de despesa: Outro
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get payablePaymentMethodOther;

  /// Campo de periodicidade de recorrência
  ///
  /// In pt, this message translates to:
  /// **'Periodicidade'**
  String get payableRecurrenceFrequency;

  /// Histórico vazio de pagamentos de uma conta a pagar
  ///
  /// In pt, this message translates to:
  /// **'Nenhum pagamento efetuado até o momento.'**
  String get payableNoPaymentsYet;

  /// Título do modal de estorno de pagamento
  ///
  /// In pt, this message translates to:
  /// **'Estornar Pagamento'**
  String get payableRevertPaymentTitle;

  /// Campo de justificativa para estorno
  ///
  /// In pt, this message translates to:
  /// **'Justificativa do Estorno'**
  String get payableRevertPaymentReason;

  /// Confirmação de cancelamento de conta a pagar
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja cancelar a obrigação?'**
  String get payableConfirmCancelObligation;

  /// Janeiro abreviado
  ///
  /// In pt, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// Fevereiro abreviado
  ///
  /// In pt, this message translates to:
  /// **'Fev'**
  String get monthFeb;

  /// Março abreviado
  ///
  /// In pt, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// Abril abreviado
  ///
  /// In pt, this message translates to:
  /// **'Abr'**
  String get monthApr;

  /// Maio abreviado
  ///
  /// In pt, this message translates to:
  /// **'Mai'**
  String get monthMay;

  /// Junho abreviado
  ///
  /// In pt, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// Julho abreviado
  ///
  /// In pt, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// Agosto abreviado
  ///
  /// In pt, this message translates to:
  /// **'Ago'**
  String get monthAug;

  /// Setembro abreviado
  ///
  /// In pt, this message translates to:
  /// **'Set'**
  String get monthSep;

  /// Outubro abreviado
  ///
  /// In pt, this message translates to:
  /// **'Out'**
  String get monthOct;

  /// Novembro abreviado
  ///
  /// In pt, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// Dezembro abreviado
  ///
  /// In pt, this message translates to:
  /// **'Dez'**
  String get monthDec;

  /// Opção Todos em filtros suspensos
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get filterAllOption;

  /// Resumo de cestas do recebível
  ///
  /// In pt, this message translates to:
  /// **'Cestas: {summary}'**
  String receivablesBasketsPrefix(String summary);

  /// Confirmação de cancelamento de obrigação com nome
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja cancelar a obrigação \"{description}\"?'**
  String payableConfirmCancelObligationNamed(String description);

  /// Tooltip do botão de seleção de impressoras e Epson
  ///
  /// In pt, this message translates to:
  /// **'Imprimir / Selecionar impressora'**
  String get tooltipPrintSelectPrinter;

  /// Tooltip para compartilhar ou salvar arquivo PDF
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar / Salvar PDF'**
  String get tooltipShareSavePdf;

  /// Texto auxiliar para parcelamento de conta a pagar
  ///
  /// In pt, this message translates to:
  /// **'Dividir em N parcelas mensais'**
  String get payableInstallmentsHelper;

  /// Tooltip do botão de estorno de pagamento
  ///
  /// In pt, this message translates to:
  /// **'Estornar este pagamento'**
  String get payableRevertPaymentTooltip;

  /// Mensagem durante a inicialização da câmera
  ///
  /// In pt, this message translates to:
  /// **'Iniciando leitor de câmera...'**
  String get cameraStarting;

  /// Título da seção de pareamento no celular
  ///
  /// In pt, this message translates to:
  /// **'Conexão com o Servidor Local'**
  String get settingsPairDeviceSection;

  /// Descrição do pareamento no celular
  ///
  /// In pt, this message translates to:
  /// **'Escaneie o QR Code gerado na tela de Configurações do computador ou informe o PIN manualmente para conectar este celular.'**
  String get settingsPairDeviceDesc;

  /// Botão para abrir a tela de pareamento
  ///
  /// In pt, this message translates to:
  /// **'Parear Dispositivo (Escanear QR / PIN)'**
  String get settingsPairDeviceButton;

  /// Título da seção de rede
  ///
  /// In pt, this message translates to:
  /// **'Rede e Conexão'**
  String get settingsServerNetworkSection;

  /// Descrição da geração de QR Code no Windows
  ///
  /// In pt, this message translates to:
  /// **'Gere um QR Code neste computador para que celulares Android possam escanear e parear automaticamente sem digitar IP, PIN ou Fingerprint.'**
  String get settingsGenerateQrDesc;

  /// Status conectado e autenticado
  ///
  /// In pt, this message translates to:
  /// **'Conectado e Pareado com Sucesso'**
  String get settingsStatusConnectedPaired;

  /// Status conectado sem autenticacao
  ///
  /// In pt, this message translates to:
  /// **'Conectado (Aguardando Pareamento)'**
  String get settingsStatusConnectedWaiting;

  /// Status desconectado
  ///
  /// In pt, this message translates to:
  /// **'Servidor Local Desconectado'**
  String get settingsStatusDisconnected;

  /// Subtítulo quando pareado
  ///
  /// In pt, this message translates to:
  /// **'Operações comerciais autenticadas ativas.'**
  String get settingsStatusPairedSubtitle;

  /// Subtítulo aguardando pareamento
  ///
  /// In pt, this message translates to:
  /// **'Pareie este dispositivo com o servidor para habilitar operações.'**
  String get settingsStatusWaitingSubtitle;

  /// Título para dados de pareamento manual
  ///
  /// In pt, this message translates to:
  /// **'Ou conecte manualmente no celular:'**
  String get settingsQrManualTitle;

  /// Rótulo de URL no diálogo de QR
  ///
  /// In pt, this message translates to:
  /// **'URL do Servidor:'**
  String get settingsQrServerUrlLabel;

  /// Rótulo de Fingerprint TLS no diálogo de QR
  ///
  /// In pt, this message translates to:
  /// **'Fingerprint TLS (Impressão Digital):'**
  String get settingsQrFingerprintLabel;

  /// Rótulo do PIN no diálogo de QR
  ///
  /// In pt, this message translates to:
  /// **'PIN de Pareamento:'**
  String get settingsQrPinLabel;

  /// Notificação de texto copiado
  ///
  /// In pt, this message translates to:
  /// **'Copiado para a área de transferência!'**
  String get settingsCopiedToClipboard;

  /// Explicação amigável do Fingerprint TLS
  ///
  /// In pt, this message translates to:
  /// **'O Fingerprint TLS é o código de segurança criptográfico gerado pelo servidor para garantir que seu celular está conectando diretamente no seu computador com HTTPS confiável.'**
  String get settingsFingerprintExplanation;

  /// Descrição da seção de rede no Windows
  ///
  /// In pt, this message translates to:
  /// **'Endereço local onde o servidor está operando neste computador.'**
  String get settingsNetworkSectionDescWindows;

  /// Descrição da seção de rede no Android
  ///
  /// In pt, this message translates to:
  /// **'Endereço do servidor e certificado seguro para comunicação em rede local.'**
  String get settingsNetworkSectionDescAndroid;

  /// Dica de inicialização da câmera
  ///
  /// In pt, this message translates to:
  /// **'Toque no botão abaixo para inicializar a captura da câmera:'**
  String get pairingCameraInitializeHint;

  /// No description provided for @purchasePaymentConditionsHeader.
  ///
  /// In pt, this message translates to:
  /// **'Condições de Pagamento'**
  String get purchasePaymentConditionsHeader;

  /// No description provided for @purchasePaymentStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Situação do Pagamento'**
  String get purchasePaymentStatusLabel;

  /// No description provided for @purchasePaymentStatusPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pago / Liquidado'**
  String get purchasePaymentStatusPaid;

  /// No description provided for @purchasePaymentStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente / Em Aberto'**
  String get purchasePaymentStatusPending;

  /// No description provided for @purchasePaymentMethodLabel.
  ///
  /// In pt, this message translates to:
  /// **'Forma de Pagamento'**
  String get purchasePaymentMethodLabel;

  /// No description provided for @purchasePaymentAmountDueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor Devido / Total Financeiro'**
  String get purchasePaymentAmountDueLabel;

  /// No description provided for @purchasePaymentDueDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data de Vencimento'**
  String get purchasePaymentDueDateLabel;

  /// No description provided for @purchasePaymentDueDateRequired.
  ///
  /// In pt, this message translates to:
  /// **'A data de vencimento é obrigatória para compras pendentes.'**
  String get purchasePaymentDueDateRequired;

  /// No description provided for @purchasePaymentPendingNotice.
  ///
  /// In pt, this message translates to:
  /// **'Esta compra gerará uma obrigação em aberto no módulo de Contas a Pagar com vencimento em {date}.'**
  String purchasePaymentPendingNotice(String date);

  /// No description provided for @purchasePaymentPaidNotice.
  ///
  /// In pt, this message translates to:
  /// **'O valor da compra será baixado imediatamente no livro-caixa da empresa.'**
  String get purchasePaymentPaidNotice;

  /// No description provided for @purchasePaymentDetailMethod.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento: {method} ({status})'**
  String purchasePaymentDetailMethod(String method, String status);

  /// No description provided for @purchasePaymentDetailDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento: {date}'**
  String purchasePaymentDetailDueDate(String date);

  /// Texto genérico de botão para selecionar
  ///
  /// In pt, this message translates to:
  /// **'Selecionar'**
  String get commonSelect;

  /// No description provided for @backupSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Backup e Segurança do Banco de Dados'**
  String get backupSectionTitle;

  /// No description provided for @backupSectionDesc.
  ///
  /// In pt, this message translates to:
  /// **'Gere cópias de segurança consistentes e verificadas do banco de dados (SQLite) para prevenir perdas de dados comerciais.'**
  String get backupSectionDesc;

  /// No description provided for @backupCreateButton.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Backup Agora'**
  String get backupCreateButton;

  /// No description provided for @backupCreating.
  ///
  /// In pt, this message translates to:
  /// **'Gerando e verificando backup...'**
  String get backupCreating;

  /// No description provided for @backupSuccessMsg.
  ///
  /// In pt, this message translates to:
  /// **'Backup gerado com sucesso: {filename}'**
  String backupSuccessMsg(String filename);

  /// No description provided for @backupErrorMsg.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao gerar backup: {error}'**
  String backupErrorMsg(String error);

  /// No description provided for @backupListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Backups Disponíveis no Servidor'**
  String get backupListTitle;

  /// No description provided for @backupEmptyList.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum backup encontrado no servidor.'**
  String get backupEmptyList;

  /// No description provided for @backupIntegrityOk.
  ///
  /// In pt, this message translates to:
  /// **'Integridade Verificada'**
  String get backupIntegrityOk;

  /// No description provided for @backupRestoreButton.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get backupRestoreButton;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar este backup?'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'O banco de dados atual será substituído por {filename}. Tudo o que foi lançado depois deste backup será perdido. Um backup de segurança do estado atual será criado automaticamente antes da restauração.'**
  String backupRestoreConfirmBody(String filename);

  /// No description provided for @backupRestoreConfirmAction.
  ///
  /// In pt, this message translates to:
  /// **'Sim, restaurar'**
  String get backupRestoreConfirmAction;

  /// No description provided for @backupRestoreCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get backupRestoreCancel;

  /// No description provided for @backupRestoreSuccessMsg.
  ///
  /// In pt, this message translates to:
  /// **'Backup restaurado. Backup de segurança criado: {safety}. Reinicie o aplicativo para recarregar os dados.'**
  String backupRestoreSuccessMsg(String safety);

  /// No description provided for @backupRestoreErrorMsg.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao restaurar backup: {error}'**
  String backupRestoreErrorMsg(String error);

  /// No description provided for @companyFinanceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Recebimentos, pagamentos e resultado'**
  String get companyFinanceTitle;

  /// No description provided for @companyFinancialReportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resultado, recebimentos e pagamentos'**
  String get companyFinancialReportTitle;

  /// No description provided for @companyPaymentsScope.
  ///
  /// In pt, this message translates to:
  /// **'Valores confirmados no período selecionado, incluindo os estornos registrados nesse período.'**
  String get companyPaymentsScope;

  /// No description provided for @companyReceived.
  ///
  /// In pt, this message translates to:
  /// **'Recebimentos confirmados'**
  String get companyReceived;

  /// No description provided for @companyPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos confirmados'**
  String get companyPaid;

  /// No description provided for @companyPaymentDifference.
  ///
  /// In pt, this message translates to:
  /// **'Diferença entre recebido e pago'**
  String get companyPaymentDifference;

  /// No description provided for @companyDifferenceExplanation.
  ///
  /// In pt, this message translates to:
  /// **'Compara os movimentos do período. Não representa saldo bancário nem lucro.'**
  String get companyDifferenceExplanation;

  /// No description provided for @companyResultTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resultado das vendas no período'**
  String get companyResultTitle;

  /// No description provided for @companyResultExplanation.
  ///
  /// In pt, this message translates to:
  /// **'As vendas a prazo entram no valor vendido, mesmo antes do recebimento. As outras despesas são consideradas quando pagas.'**
  String get companyResultExplanation;

  /// No description provided for @companySalesRevenue.
  ///
  /// In pt, this message translates to:
  /// **'Valor das vendas'**
  String get companySalesRevenue;

  /// No description provided for @companySoldCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo das cestas vendidas'**
  String get companySoldCost;

  /// No description provided for @companyGrossProfit.
  ///
  /// In pt, this message translates to:
  /// **'Lucro bruto das vendas'**
  String get companyGrossProfit;

  /// No description provided for @companyOperatingExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Outras despesas do negócio pagas'**
  String get companyOperatingExpenses;

  /// No description provided for @companyOperatingResult.
  ///
  /// In pt, this message translates to:
  /// **'Resultado gerencial do período'**
  String get companyOperatingResult;

  /// No description provided for @companyCostExplanation.
  ///
  /// In pt, this message translates to:
  /// **'O custo dos insumos vendidos já está no custo das cestas. As compras de estoque não são descontadas novamente do lucro bruto. Retiradas pessoais são mostradas separadamente.'**
  String get companyCostExplanation;

  /// No description provided for @companyPendingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contas ainda pendentes'**
  String get companyPendingTitle;

  /// No description provided for @companyPendingScope.
  ///
  /// In pt, this message translates to:
  /// **'Totais atuais de todas as contas em aberto. Os vencimentos no período aparecem abaixo.'**
  String get companyPendingScope;

  /// No description provided for @companyPendingReceivable.
  ///
  /// In pt, this message translates to:
  /// **'Total pendente a receber'**
  String get companyPendingReceivable;

  /// No description provided for @companyPendingPayable.
  ///
  /// In pt, this message translates to:
  /// **'Total pendente a pagar'**
  String get companyPendingPayable;

  /// No description provided for @companyReceivableDueInPeriod.
  ///
  /// In pt, this message translates to:
  /// **'A receber com vencimento no período'**
  String get companyReceivableDueInPeriod;

  /// No description provided for @companyPayableDueInPeriod.
  ///
  /// In pt, this message translates to:
  /// **'A pagar com vencimento no período'**
  String get companyPayableDueInPeriod;

  /// No description provided for @companyReceivedDetails.
  ///
  /// In pt, this message translates to:
  /// **'Recebimentos confirmados no período'**
  String get companyReceivedDetails;

  /// No description provided for @companyPaidDetails.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos confirmados no período'**
  String get companyPaidDetails;

  /// No description provided for @companyNoPayments.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum registro confirmado neste período.'**
  String get companyNoPayments;

  /// No description provided for @companyPaidStatus.
  ///
  /// In pt, this message translates to:
  /// **'Recebida'**
  String get companyPaidStatus;

  /// No description provided for @companyPartialStatus.
  ///
  /// In pt, this message translates to:
  /// **'Recebida parcialmente'**
  String get companyPartialStatus;

  /// No description provided for @companyPendingStatus.
  ///
  /// In pt, this message translates to:
  /// **'A receber'**
  String get companyPendingStatus;

  /// No description provided for @companyStockAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Disponível'**
  String get companyStockAvailable;

  /// No description provided for @companyMissingCost.
  ///
  /// In pt, this message translates to:
  /// **'Há {count} venda(s) com custo incompleto. O resultado gerencial precisa ser conferido.'**
  String companyMissingCost(int count);

  /// No description provided for @companyStockPaid.
  ///
  /// In pt, this message translates to:
  /// **'Compras de estoque pagas: {value}'**
  String companyStockPaid(String value);

  /// No description provided for @companyWithdrawalsPaid.
  ///
  /// In pt, this message translates to:
  /// **'Retiradas pessoais pagas: {value}'**
  String companyWithdrawalsPaid(String value);

  /// No description provided for @companyOverdueAmount.
  ///
  /// In pt, this message translates to:
  /// **'Vencido: {value}'**
  String companyOverdueAmount(String value);

  /// No description provided for @companyPaymentDescription.
  ///
  /// In pt, this message translates to:
  /// **'{method} · {date}'**
  String companyPaymentDescription(String method, String date);

  /// No description provided for @companyPurchasesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Compras registradas no período'**
  String get companyPurchasesTitle;

  /// No description provided for @companyPurchaseCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} compra(s) confirmada(s)'**
  String companyPurchaseCount(int count);

  /// No description provided for @companyPurchasesExplanation.
  ///
  /// In pt, this message translates to:
  /// **'Inclui compras pagas e a prazo. Os pagamentos confirmados aparecem separadamente no financeiro.'**
  String get companyPurchasesExplanation;

  /// No description provided for @productDeleteButton.
  ///
  /// In pt, this message translates to:
  /// **'Excluir definitivamente'**
  String get productDeleteButton;

  /// No description provided for @productDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir produto nunca utilizado?'**
  String get productDeleteTitle;

  /// No description provided for @productDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir definitivamente \"{name}\"? O cadastro e suas embalagens nunca usadas serão removidos. Essa ação não pode ser desfeita.'**
  String productDeleteConfirm(String name);

  /// No description provided for @productDeletedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Produto nunca utilizado excluído definitivamente.'**
  String get productDeletedSuccess;

  /// No description provided for @productDeleteBlockedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Este produto tem vínculos ou histórico'**
  String get productDeleteBlockedTitle;

  /// No description provided for @productDeleteBlocked.
  ///
  /// In pt, this message translates to:
  /// **'\"{name}\" não pode ser excluído definitivamente porque possui registros em:\n\n{reasons}\n\nPara deixar de utilizá-lo, você pode inativar o cadastro. Se ele estiver em uma receita ativa, retire-o dessa composição antes de inativar.'**
  String productDeleteBlocked(String name, String reasons);

  /// No description provided for @productDeleteHistoryError.
  ///
  /// In pt, this message translates to:
  /// **'O produto possui vínculos ou histórico. A exclusão definitiva foi bloqueada para preservar esses registros.'**
  String get productDeleteHistoryError;

  /// No description provided for @productUsageRecipes.
  ///
  /// In pt, this message translates to:
  /// **'• Receitas de cestas, incluindo versões anteriores'**
  String get productUsageRecipes;

  /// No description provided for @productUsagePurchases.
  ///
  /// In pt, this message translates to:
  /// **'• Compras, incluindo rascunhos e compras canceladas'**
  String get productUsagePurchases;

  /// No description provided for @productUsageProduction.
  ///
  /// In pt, this message translates to:
  /// **'• Montagens ou composições já registradas'**
  String get productUsageProduction;

  /// No description provided for @productUsageMovements.
  ///
  /// In pt, this message translates to:
  /// **'• Movimentações de estoque, mesmo com estoque zerado'**
  String get productUsageMovements;

  /// No description provided for @productUsageHistory.
  ///
  /// In pt, this message translates to:
  /// **'• Outros registros anteriores'**
  String get productUsageHistory;

  /// No description provided for @packagingHelpExplanation.
  ///
  /// In pt, this message translates to:
  /// **'A embalagem comercial é a forma como você compra este produto: pacote, saco, fardo, caixa ou unidade. Ela informa quanto uma embalagem acrescenta ao estoque. Não é a embalagem vazia usada para montar a cesta.\n\nExemplo: se o arroz é controlado em gramas, um saco de 5 kg contém 5.000 g. Ao comprar 3 sacos, entram 15.000 g no estoque. Sem uma embalagem cadastrada, a compra é informada diretamente na unidade-base do produto.'**
  String get packagingHelpExplanation;

  /// No description provided for @packagingContentHelp.
  ///
  /// In pt, this message translates to:
  /// **'Informe o conteúdo de uma única embalagem na unidade-base {unit}. Exemplos: caixa com 12 unidades = 12 UNIT; saco de 5 kg = 5.000 G; frasco de 500 ml = 500 ML. Use o exemplo que corresponde à unidade deste produto.'**
  String packagingContentHelp(String unit);

  /// No description provided for @purchasePackagingHelpTitle.
  ///
  /// In pt, this message translates to:
  /// **'Como informar quantidade e preço?'**
  String get purchasePackagingHelpTitle;

  /// No description provided for @purchasePackagingHelpExplanation.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a forma como comprou o produto. A quantidade indica quantas embalagens você comprou, e o preço é o valor de uma delas.\n\nExemplo: 3 sacos de arroz de 5 kg a R\$ 25 por saco = 15 kg no estoque e R\$ 75 na compra. Caixa com 12 unidades: 2 caixas = 24 unidades.\n\nSe escolher \"Sem embalagem\", informe a quantidade e o preço na unidade-base exibida. Para comprar por kg ou litro com preço por kg/litro, cadastre essa forma de compra antes: 1 kg = 1.000 g; 1 litro = 1.000 ml.'**
  String get purchasePackagingHelpExplanation;

  /// No description provided for @purchaseQuantityPackages.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade de embalagens'**
  String get purchaseQuantityPackages;

  /// No description provided for @purchaseQuantityBaseUnits.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade em {unit}'**
  String purchaseQuantityBaseUnits(String unit);

  /// No description provided for @purchasePricePerPackage.
  ///
  /// In pt, this message translates to:
  /// **'Preço de uma embalagem (R\$)'**
  String get purchasePricePerPackage;

  /// No description provided for @purchasePricePerBaseUnit.
  ///
  /// In pt, this message translates to:
  /// **'Preço por {unit} (R\$)'**
  String purchasePricePerBaseUnit(String unit);

  /// No description provided for @purchasePackageCountHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: para 3 sacos ou 3 caixas, informe 3.'**
  String get purchasePackageCountHelp;

  /// No description provided for @purchaseBaseCountHelp.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade diretamente na unidade-base exibida.'**
  String get purchaseBaseCountHelp;

  /// No description provided for @purchasePackagePriceHelp.
  ///
  /// In pt, this message translates to:
  /// **'Valor de um saco, pacote ou caixa da forma de compra escolhida.'**
  String get purchasePackagePriceHelp;

  /// No description provided for @purchaseBasePriceHelp.
  ///
  /// In pt, this message translates to:
  /// **'Preço de uma única unidade-base. Para preço por kg/litro, cadastre a forma de compra.'**
  String get purchaseBasePriceHelp;

  /// No description provided for @purchasePackagingContents.
  ///
  /// In pt, this message translates to:
  /// **'Cada \"{name}\" acrescenta {quantity} ao estoque.'**
  String purchasePackagingContents(String name, String quantity);

  /// No description provided for @settingsHttpsUrlRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe uma URL HTTPS válida do servidor, sem usuário ou senha no endereço.'**
  String get settingsHttpsUrlRequired;

  /// No description provided for @settingsTokenEntryHelp.
  ///
  /// In pt, this message translates to:
  /// **'Opcional: cole um token já emitido pelo servidor. Deixe vazio para manter a autenticação atual ou autenticar automaticamente no servidor deste computador (localhost).'**
  String get settingsTokenEntryHelp;

  /// No description provided for @settingsSaveAuthenticate.
  ///
  /// In pt, this message translates to:
  /// **'Salvar e autenticar este computador'**
  String get settingsSaveAuthenticate;

  /// No description provided for @settingsPairComputer.
  ///
  /// In pt, this message translates to:
  /// **'Parear este computador por PIN'**
  String get settingsPairComputer;

  /// No description provided for @settingsAuthenticatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Computador autenticado no servidor.'**
  String get settingsAuthenticatedSuccess;

  /// No description provided for @settingsSavedNeedsAuthentication.
  ///
  /// In pt, this message translates to:
  /// **'Configurações salvas. O servidor ainda não confirmou a autenticação. Confira a conexão, informe um token válido ou faça o pareamento por PIN.'**
  String get settingsSavedNeedsAuthentication;

  /// No description provided for @newDatabaseTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar e usar um novo banco'**
  String get newDatabaseTitle;

  /// No description provided for @newDatabaseCreating.
  ///
  /// In pt, this message translates to:
  /// **'Criando e ativando o novo banco...'**
  String get newDatabaseCreating;

  /// No description provided for @newDatabaseHelp.
  ///
  /// In pt, this message translates to:
  /// **'Gera um backup verificado do banco atual e começa com um banco vazio. Os pareamentos dos dispositivos são mantidos.'**
  String get newDatabaseHelp;

  /// No description provided for @newDatabaseConfirmationBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação troca o banco usado por toda a empresa, incluindo computadores, celulares e tablets. Produtos, receitas, clientes, compras, vendas, estoque e contas começarão vazios. Um backup obrigatório do banco atual será criado e verificado antes da troca. Os dispositivos continuam pareados. Para recuperar os dados anteriores, use Restaurar no backup de segurança. Para confirmar, digite NOVO BANCO.'**
  String get newDatabaseConfirmationBody;

  /// No description provided for @newDatabaseConfirmationLabel.
  ///
  /// In pt, this message translates to:
  /// **'Digite NOVO BANCO'**
  String get newDatabaseConfirmationLabel;

  /// No description provided for @newDatabaseConfirmAction.
  ///
  /// In pt, this message translates to:
  /// **'Gerar backup e ativar banco novo'**
  String get newDatabaseConfirmAction;

  /// No description provided for @newDatabaseSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Novo banco ativado. Backup anterior: {filename}. Recarregue as páginas nos demais dispositivos.'**
  String newDatabaseSuccess(String filename);

  /// No description provided for @newDatabaseFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir a criação do banco. Confira a conexão e tente novamente; a mesma operação será retomada com segurança.'**
  String get newDatabaseFailed;

  /// No description provided for @newDatabaseAlreadyProcessed.
  ///
  /// In pt, this message translates to:
  /// **'Esta solicitação já foi concluída anteriormente. O banco atual foi mantido. Para criar outro banco, inicie uma nova solicitação.'**
  String get newDatabaseAlreadyProcessed;

  /// No description provided for @payableFiltersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get payableFiltersTitle;

  /// No description provided for @payableCreateShort.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta a pagar'**
  String get payableCreateShort;

  /// No description provided for @payableOpenShort.
  ///
  /// In pt, this message translates to:
  /// **'A pagar'**
  String get payableOpenShort;

  /// No description provided for @payableDisplayedSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo das contas exibidas'**
  String get payableDisplayedSummary;

  /// No description provided for @payableSearch.
  ///
  /// In pt, this message translates to:
  /// **'Buscar favorecido'**
  String get payableSearch;

  /// No description provided for @saleCancelAssemblyHelp.
  ///
  /// In pt, this message translates to:
  /// **'Informe o que aconteceu fisicamente com cada item montado nesta venda. Cestas vendidas de estoque pronto voltam como cestas prontas.'**
  String get saleCancelAssemblyHelp;

  /// No description provided for @saleCancelAssemblyQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Situação da montagem'**
  String get saleCancelAssemblyQuestion;

  /// No description provided for @saleCancelKeepBaskets.
  ///
  /// In pt, this message translates to:
  /// **'As cestas continuam montadas'**
  String get saleCancelKeepBaskets;

  /// No description provided for @saleCancelReturnIngredients.
  ///
  /// In pt, this message translates to:
  /// **'A montagem não aconteceu'**
  String get saleCancelReturnIngredients;

  /// No description provided for @saleCancelAssemblyRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe a situação de todas as montagens antes de cancelar.'**
  String get saleCancelAssemblyRequired;

  /// No description provided for @saleAssemblyStockHelp.
  ///
  /// In pt, this message translates to:
  /// **'Usa cestas já montadas e desconta do estoque de cestas prontas.'**
  String get saleAssemblyStockHelp;

  /// No description provided for @saleAssemblyDemandHelp.
  ///
  /// In pt, this message translates to:
  /// **'Consome os produtos da composição e registra a montagem ao confirmar a venda.'**
  String get saleAssemblyDemandHelp;

  /// No description provided for @saleStockSelectBasket.
  ///
  /// In pt, this message translates to:
  /// **'Selecione uma cesta para consultar o saldo.'**
  String get saleStockSelectBasket;

  /// No description provided for @saleStockLoading.
  ///
  /// In pt, this message translates to:
  /// **'Consultando saldo…'**
  String get saleStockLoading;

  /// No description provided for @saleStockQueryFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível consultar o saldo. Tente novamente.'**
  String get saleStockQueryFailed;

  /// No description provided for @basketTypeFormNoStockSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'As cestas são montadas na venda, com baixa dos produtos da composição.'**
  String get basketTypeFormNoStockSubtitle;

  /// No description provided for @saleAssemblyAutomatic.
  ///
  /// In pt, this message translates to:
  /// **'Montar na venda'**
  String get saleAssemblyAutomatic;

  /// No description provided for @basketStockDisabledError.
  ///
  /// In pt, this message translates to:
  /// **'Esta cesta está configurada para montagem na venda. Para usar cestas prontas, ative Estoque de cestas prontas no cadastro.'**
  String get basketStockDisabledError;

  /// No description provided for @basketStockRemainsError.
  ///
  /// In pt, this message translates to:
  /// **'Ainda existem cestas prontas deste tipo em estoque. Resolva esse saldo antes de desativar a opção.'**
  String get basketStockRemainsError;

  /// No description provided for @assemblyRegister.
  ///
  /// In pt, this message translates to:
  /// **'Registrar montagem'**
  String get assemblyRegister;

  /// No description provided for @assemblyRegisterHelp.
  ///
  /// In pt, this message translates to:
  /// **'Informe a quantidade e quando as cestas foram fabricadas. Revise a composição antes de confirmar: os produtos serão consumidos e as cestas prontas entrarão no estoque.'**
  String get assemblyRegisterHelp;

  /// No description provided for @assemblyHistory.
  ///
  /// In pt, this message translates to:
  /// **'Montagens'**
  String get assemblyHistory;

  /// No description provided for @assemblyHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Montagens — {name}'**
  String assemblyHistoryTitle(String name);

  /// No description provided for @assemblyStandardStock.
  ///
  /// In pt, this message translates to:
  /// **'Cestas padrão prontas: {qty}'**
  String assemblyStandardStock(int qty);

  /// No description provided for @assemblyOccurredAt.
  ///
  /// In pt, this message translates to:
  /// **'Data e horário da fabricação'**
  String get assemblyOccurredAt;

  /// No description provided for @assemblyReview.
  ///
  /// In pt, this message translates to:
  /// **'Revisar montagem'**
  String get assemblyReview;

  /// No description provided for @assemblyConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar montagem'**
  String get assemblyConfirm;

  /// No description provided for @assemblyRetry.
  ///
  /// In pt, this message translates to:
  /// **'Retomar confirmação'**
  String get assemblyRetry;

  /// No description provided for @assemblySaved.
  ///
  /// In pt, this message translates to:
  /// **'Montagem registrada e estoque atualizado.'**
  String get assemblySaved;

  /// No description provided for @assemblyComposition.
  ///
  /// In pt, this message translates to:
  /// **'Produtos a consumir'**
  String get assemblyComposition;

  /// No description provided for @assemblyEstimatedCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo total estimado: {value}'**
  String assemblyEstimatedCost(String value);

  /// No description provided for @assemblyRecordedCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo total registrado: {value}'**
  String assemblyRecordedCost(String value);

  /// No description provided for @assemblyRequiredAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Necessário: {required} · Disponível: {available}'**
  String assemblyRequiredAvailable(String required, String available);

  /// No description provided for @assemblyMissing.
  ///
  /// In pt, this message translates to:
  /// **'Faltam: {qty}'**
  String assemblyMissing(String qty);

  /// No description provided for @assemblyInsufficientHelp.
  ///
  /// In pt, this message translates to:
  /// **'Faltam produtos para esta montagem. Reponha o estoque ou altere a quantidade e revise novamente.'**
  String get assemblyInsufficientHelp;

  /// No description provided for @assemblyPendingHelp.
  ///
  /// In pt, this message translates to:
  /// **'Existe uma montagem aguardando confirmação do servidor. Retome a mesma solicitação para verificar o resultado sem registrar as cestas novamente.'**
  String get assemblyPendingHelp;

  /// No description provided for @assemblyRecipeChanged.
  ///
  /// In pt, this message translates to:
  /// **'A receita mudou desde a revisão. Confira a composição novamente antes de confirmar.'**
  String get assemblyRecipeChanged;

  /// No description provided for @assemblyInactiveHelp.
  ///
  /// In pt, this message translates to:
  /// **'Este tipo de cesta está inativo. O histórico continua disponível.'**
  String get assemblyInactiveHelp;

  /// No description provided for @assemblyNoStockHelp.
  ///
  /// In pt, this message translates to:
  /// **'Este tipo está configurado para montar na venda. Ative Estoque de cestas prontas no cadastro para registrar fabricação antecipada.'**
  String get assemblyNoStockHelp;

  /// No description provided for @assemblyNoRecipeHelp.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre uma receita ativa antes de registrar a montagem.'**
  String get assemblyNoRecipeHelp;

  /// No description provided for @assemblyHistoryHelp.
  ///
  /// In pt, this message translates to:
  /// **'Inclui montagens antecipadas e realizadas na venda. A quantidade fabricada é histórica; não representa o saldo atual de cada lote.'**
  String get assemblyHistoryHelp;

  /// No description provided for @assemblyHistoryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma montagem registrada para este tipo de cesta.'**
  String get assemblyHistoryEmpty;

  /// No description provided for @assemblyOriginSale.
  ///
  /// In pt, this message translates to:
  /// **'Montada na venda'**
  String get assemblyOriginSale;

  /// No description provided for @assemblyOriginAdvance.
  ///
  /// In pt, this message translates to:
  /// **'Montagem antecipada'**
  String get assemblyOriginAdvance;

  /// No description provided for @assemblyRecorded.
  ///
  /// In pt, this message translates to:
  /// **'Montagem registrada'**
  String get assemblyRecorded;

  /// No description provided for @assemblyUndone.
  ///
  /// In pt, this message translates to:
  /// **'Montagem desfeita'**
  String get assemblyUndone;

  /// No description provided for @assemblyCustom.
  ///
  /// In pt, this message translates to:
  /// **'Composição personalizada'**
  String get assemblyCustom;

  /// No description provided for @assemblyBatch.
  ///
  /// In pt, this message translates to:
  /// **'Montagem #{number} · {qty} cestas'**
  String assemblyBatch(int number, int qty);

  /// No description provided for @assemblyPage.
  ///
  /// In pt, this message translates to:
  /// **'Página {page} de {total}'**
  String assemblyPage(int page, int total);

  /// No description provided for @assemblyPreviousPage.
  ///
  /// In pt, this message translates to:
  /// **'Página anterior'**
  String get assemblyPreviousPage;

  /// No description provided for @assemblyNextPage.
  ///
  /// In pt, this message translates to:
  /// **'Próxima página'**
  String get assemblyNextPage;

  /// No description provided for @assemblyCustomize.
  ///
  /// In pt, this message translates to:
  /// **'Personalizar esta montagem'**
  String get assemblyCustomize;

  /// No description provided for @assemblyCustomizeHelp.
  ///
  /// In pt, this message translates to:
  /// **'Altere os produtos destas cestas sem mudar a receita cadastrada.'**
  String get assemblyCustomizeHelp;

  /// No description provided for @assemblyCustomDescription.
  ///
  /// In pt, this message translates to:
  /// **'Identificação da montagem personalizada'**
  String get assemblyCustomDescription;

  /// No description provided for @assemblyCustomDescriptionRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe uma identificação para diferenciar estas cestas.'**
  String get assemblyCustomDescriptionRequired;

  /// No description provided for @assemblyCustomItemsHelp.
  ///
  /// In pt, this message translates to:
  /// **'Composição por cesta. Todas as cestas desta montagem terão os mesmos produtos e quantidades.'**
  String get assemblyCustomItemsHelp;

  /// No description provided for @assemblyProduct.
  ///
  /// In pt, this message translates to:
  /// **'Produto'**
  String get assemblyProduct;

  /// No description provided for @assemblyQuantityPerBasket.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade por cesta'**
  String get assemblyQuantityPerBasket;

  /// No description provided for @assemblyBaseUnitsHelp.
  ///
  /// In pt, this message translates to:
  /// **'Use números inteiros na unidade indicada: G = gramas, ML = mililitros e UN = unidades. Ao trocar o produto, informe a quantidade novamente.'**
  String get assemblyBaseUnitsHelp;

  /// No description provided for @assemblyAddProduct.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar produto'**
  String get assemblyAddProduct;

  /// No description provided for @assemblyRemoveProduct.
  ///
  /// In pt, this message translates to:
  /// **'Remover produto'**
  String get assemblyRemoveProduct;

  /// No description provided for @assemblyCustomItemsRequired.
  ///
  /// In pt, this message translates to:
  /// **'Inclua ao menos um produto na montagem personalizada.'**
  String get assemblyCustomItemsRequired;

  /// No description provided for @assemblyCustomizationDisabled.
  ///
  /// In pt, this message translates to:
  /// **'Este tipo de cesta não permite personalização. Confira seu cadastro.'**
  String get assemblyCustomizationDisabled;

  /// No description provided for @assemblyCustomStock.
  ///
  /// In pt, this message translates to:
  /// **'Prontas desta montagem: {quantity}'**
  String assemblyCustomStock(int quantity);

  /// No description provided for @basketDeleteButton.
  ///
  /// In pt, this message translates to:
  /// **'Excluir cesta'**
  String get basketDeleteButton;

  /// No description provided for @basketDeleteBlockedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cesta ainda em uso'**
  String get basketDeleteBlockedTitle;

  /// No description provided for @basketDeleteBlockedHelp.
  ///
  /// In pt, this message translates to:
  /// **'A cesta tem vendas não canceladas, estoque ou operações pendentes. Confira esses registros antes de tentar excluir novamente.'**
  String get basketDeleteBlockedHelp;

  /// No description provided for @basketDeleteActiveSales.
  ///
  /// In pt, this message translates to:
  /// **'Há venda não cancelada com esta cesta. Cancele a operação incorreta antes de excluir o cadastro.'**
  String get basketDeleteActiveSales;

  /// No description provided for @basketDeleteStockRemains.
  ///
  /// In pt, this message translates to:
  /// **'Ainda há cestas em estoque. Cancelar uma venda pode devolver cestas prontas; confira o destino físico antes de excluir o cadastro.'**
  String get basketDeleteStockRemains;

  /// No description provided for @basketDeleteActiveDispatches.
  ///
  /// In pt, this message translates to:
  /// **'Há uma saída/conferência ainda aberta vinculada a esta cesta.'**
  String get basketDeleteActiveDispatches;

  /// No description provided for @basketDeleteUnusedConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir definitivamente “{name}” e suas receitas nunca utilizadas? Os produtos da receita serão preservados.'**
  String basketDeleteUnusedConfirm(String name);

  /// No description provided for @basketDeleteCatalogConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir “{name}” do catálogo? A cesta deixará de aparecer na lista e nas novas operações. Seu cadastro e suas receitas permanecerão no banco para preservar vendas canceladas, montagens e movimentações. Essa ação não apaga o histórico.'**
  String basketDeleteCatalogConfirm(String name);

  /// No description provided for @basketDeletedPermanently.
  ///
  /// In pt, this message translates to:
  /// **'Cesta nunca utilizada excluída definitivamente.'**
  String get basketDeletedPermanently;

  /// No description provided for @basketRemovedFromCatalog.
  ///
  /// In pt, this message translates to:
  /// **'Cesta excluída do catálogo. Histórico preservado.'**
  String get basketRemovedFromCatalog;

  /// No description provided for @basketRemovedError.
  ///
  /// In pt, this message translates to:
  /// **'Esta cesta foi excluída do catálogo e permanece somente no histórico.'**
  String get basketRemovedError;

  /// No description provided for @formDocumentType.
  ///
  /// In pt, this message translates to:
  /// **'Documento'**
  String get formDocumentType;

  /// No description provided for @formSelectColumns.
  ///
  /// In pt, this message translates to:
  /// **'Campos do documento'**
  String get formSelectColumns;

  /// No description provided for @formColumnsHelp.
  ///
  /// In pt, this message translates to:
  /// **'Marque as colunas que devem aparecer no PDF e na planilha. Mantenha pelo menos uma.'**
  String get formColumnsHelp;

  /// No description provided for @formAllColumns.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar todas'**
  String get formAllColumns;

  /// No description provided for @printerDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Impressão e impressoras'**
  String get printerDialogTitle;

  /// No description provided for @printerSettingsEntryHelp.
  ///
  /// In pt, this message translates to:
  /// **'Configurar a impressão e testar uma página A4, mesmo sem conexão com o servidor.'**
  String get printerSettingsEntryHelp;

  /// No description provided for @printerAndroidDiscovery.
  ///
  /// In pt, this message translates to:
  /// **'No Android, a procura e a seleção da impressora acontecem na janela de impressão do sistema, usando os serviços ativados no celular.'**
  String get printerAndroidDiscovery;

  /// No description provided for @printerDesktopDiscovery.
  ///
  /// In pt, this message translates to:
  /// **'Use a janela de impressão do sistema ou uma impressora cadastrada abaixo. Impressoras de rede precisam estar instaladas no computador.'**
  String get printerDesktopDiscovery;

  /// No description provided for @printerSystemPrint.
  ///
  /// In pt, this message translates to:
  /// **'Procurar impressora e imprimir'**
  String get printerSystemPrint;

  /// No description provided for @printerTestAction.
  ///
  /// In pt, this message translates to:
  /// **'Imprimir página de teste A4'**
  String get printerTestAction;

  /// No description provided for @printerOpenSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurar impressão no Android'**
  String get printerOpenSettings;

  /// No description provided for @printerSettingsHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ative um serviço de impressão compatível nas configurações. Ao voltar ao app, tente imprimir novamente.'**
  String get printerSettingsHelp;

  /// No description provided for @printerSettingsUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir as configurações. Procure Impressão nas configurações do Android.'**
  String get printerSettingsUnavailable;

  /// No description provided for @printerInstalledTitle.
  ///
  /// In pt, this message translates to:
  /// **'Impressoras cadastradas no sistema'**
  String get printerInstalledTitle;

  /// No description provided for @printerNoInstalled.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma impressora cadastrada foi retornada. Instale a impressora nas configurações do computador e atualize esta lista.'**
  String get printerNoInstalled;

  /// No description provided for @printerNotAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Indisponível segundo o sistema'**
  String get printerNotAvailable;

  /// No description provided for @printerDiscoveryError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível consultar as impressoras. Você ainda pode tentar a janela de impressão do sistema ou atualizar a consulta.'**
  String get printerDiscoveryError;

  /// No description provided for @printerUnsupported.
  ///
  /// In pt, this message translates to:
  /// **'O serviço de impressão não está disponível neste dispositivo. Você pode salvar o PDF e imprimir em outro dispositivo.'**
  String get printerUnsupported;

  /// No description provided for @printerWaiting.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando retorno do sistema de impressão. Você pode fechar esta janela; acompanhe também a fila de impressão do sistema.'**
  String get printerWaiting;

  /// No description provided for @printerJobBusy.
  ///
  /// In pt, this message translates to:
  /// **'Já existe uma impressão em andamento nesta tela. Acompanhe a fila do sistema antes de tentar novamente.'**
  String get printerJobBusy;

  /// No description provided for @printerJobSubmitted.
  ///
  /// In pt, this message translates to:
  /// **'O sistema retornou a conclusão do trabalho. Confira se a folha saiu corretamente; o app não verifica papel ou tinta.'**
  String get printerJobSubmitted;

  /// No description provided for @printerJobCanceled.
  ///
  /// In pt, this message translates to:
  /// **'Impressão cancelada.'**
  String get printerJobCanceled;

  /// No description provided for @printerJobError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir a impressão. Confira a conexão, a impressora e a fila do sistema. Você também pode salvar o PDF.'**
  String get printerJobError;

  /// No description provided for @printerPreviewError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a prévia deste PDF. Tente gerar o documento novamente.'**
  String get printerPreviewError;

  /// No description provided for @printerHelpTitle.
  ///
  /// In pt, this message translates to:
  /// **'A impressora não apareceu?'**
  String get printerHelpTitle;

  /// No description provided for @printerHelpNetwork.
  ///
  /// In pt, this message translates to:
  /// **'Confira se a impressora está ligada e acessível na mesma rede local do dispositivo. Redes de visitantes, isolamento entre aparelhos e VPN podem impedir a descoberta.'**
  String get printerHelpNetwork;

  /// No description provided for @printerHelpAndroid.
  ///
  /// In pt, this message translates to:
  /// **'No Android, ative o serviço padrão de impressão, Mopria ou um serviço do fabricante compatível com o modelo. A busca de impressoras é feita por esse serviço na janela do sistema.'**
  String get printerHelpAndroid;

  /// No description provided for @printerHelpWindows.
  ///
  /// In pt, this message translates to:
  /// **'No Windows, adicione a impressora em Configurações > Impressoras e scanners e confira o driver do modelo. Depois atualize esta lista.'**
  String get printerHelpWindows;

  /// No description provided for @printerHelpIp.
  ///
  /// In pt, this message translates to:
  /// **'Se a busca automática falhar, verifique se o serviço de impressão ou as configurações do sistema permitem adicionar a impressora pelo endereço IP.'**
  String get printerHelpIp;

  /// No description provided for @printerHelpDirect.
  ///
  /// In pt, this message translates to:
  /// **'Wi-Fi Direct depende do suporte do celular e da impressora. Essa conexão pode interromper o acesso ao servidor da loja; carregue o documento antes de mudar de rede.'**
  String get printerHelpDirect;

  /// No description provided for @printerHelpQueue.
  ///
  /// In pt, this message translates to:
  /// **'Se houver trabalho bloqueado, confira papel, tinta, estado da impressora e fila de impressão. Evite reenviar sem verificar a fila para não duplicar folhas.'**
  String get printerHelpQueue;

  /// No description provided for @printerCompatibility.
  ///
  /// In pt, this message translates to:
  /// **'Ter Wi-Fi não garante compatibilidade. O modelo precisa ser atendido pelo serviço de impressão do Android ou pelo driver do Windows.'**
  String get printerCompatibility;

  /// No description provided for @printerTestTitle.
  ///
  /// In pt, this message translates to:
  /// **'Página de teste de impressão A4'**
  String get printerTestTitle;

  /// No description provided for @printerTestInstructions.
  ///
  /// In pt, this message translates to:
  /// **'Selecione papel A4 e escala de 100% quando disponível. Confira texto, bordas, proporções e alinhamento nesta folha antes de imprimir documentos da loja.'**
  String get printerTestInstructions;

  /// No description provided for @printerTestCharacters.
  ///
  /// In pt, this message translates to:
  /// **'Teste de acentos: ação, quitação, descrição, café, açúcar.'**
  String get printerTestCharacters;

  /// No description provided for @printerTestScale.
  ///
  /// In pt, this message translates to:
  /// **'A referência abaixo deve medir 100 mm de largura e 20 mm de altura, sem redimensionamento.'**
  String get printerTestScale;

  /// No description provided for @printerTestLine.
  ///
  /// In pt, this message translates to:
  /// **'Espaço para escrita: {height} mm'**
  String printerTestLine(int height);

  /// No description provided for @printerTestFooter.
  ///
  /// In pt, this message translates to:
  /// **'Documento de teste sem dados comerciais. Confira também orientação, escala e margens nas configurações da impressora.'**
  String get printerTestFooter;

  /// No description provided for @formColumnOrder.
  ///
  /// In pt, this message translates to:
  /// **'Ordem das colunas'**
  String get formColumnOrder;

  /// No description provided for @formColumnOrderHelp.
  ///
  /// In pt, this message translates to:
  /// **'Use as setas para mover os campos. A lista de cima para baixo define a ordem da esquerda para a direita no PDF e no XLSX.'**
  String get formColumnOrderHelp;

  /// No description provided for @formColumnMoveUp.
  ///
  /// In pt, this message translates to:
  /// **'Mover para cima'**
  String get formColumnMoveUp;

  /// No description provided for @formColumnMoveDown.
  ///
  /// In pt, this message translates to:
  /// **'Mover para baixo'**
  String get formColumnMoveDown;

  /// No description provided for @formColumnOrderReset.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar ordem padrão'**
  String get formColumnOrderReset;

  /// No description provided for @formPrintSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configuração da impressão'**
  String get formPrintSettings;

  /// No description provided for @formOrientation.
  ///
  /// In pt, this message translates to:
  /// **'Orientação da folha'**
  String get formOrientation;

  /// No description provided for @formOrientationAuto.
  ///
  /// In pt, this message translates to:
  /// **'Automática'**
  String get formOrientationAuto;

  /// No description provided for @formPortrait.
  ///
  /// In pt, this message translates to:
  /// **'Vertical (retrato)'**
  String get formPortrait;

  /// No description provided for @formLandscape.
  ///
  /// In pt, this message translates to:
  /// **'Horizontal (paisagem)'**
  String get formLandscape;

  /// No description provided for @formRowHeight.
  ///
  /// In pt, this message translates to:
  /// **'Altura mínima da linha (mm)'**
  String get formRowHeight;

  /// No description provided for @formFontSize.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho da fonte (pt)'**
  String get formFontSize;

  /// No description provided for @formPageMargins.
  ///
  /// In pt, this message translates to:
  /// **'Margens da folha (mm)'**
  String get formPageMargins;

  /// No description provided for @formMarginTop.
  ///
  /// In pt, this message translates to:
  /// **'Superior (mm)'**
  String get formMarginTop;

  /// No description provided for @formMarginBottom.
  ///
  /// In pt, this message translates to:
  /// **'Inferior (mm)'**
  String get formMarginBottom;

  /// No description provided for @formMarginLeft.
  ///
  /// In pt, this message translates to:
  /// **'Esquerda (mm)'**
  String get formMarginLeft;

  /// No description provided for @formMarginRight.
  ///
  /// In pt, this message translates to:
  /// **'Direita (mm)'**
  String get formMarginRight;

  /// No description provided for @formMarginHelp.
  ///
  /// In pt, this message translates to:
  /// **'O padrão usa 15 mm. Margens menores dependem da área imprimível da sua impressora. Confira a prévia.'**
  String get formMarginHelp;

  /// No description provided for @formAutoRows.
  ///
  /// In pt, this message translates to:
  /// **'Ajustar linhas em branco para uma página'**
  String get formAutoRows;

  /// No description provided for @formBlankRows.
  ///
  /// In pt, this message translates to:
  /// **'Total de linhas em branco'**
  String get formBlankRows;

  /// No description provided for @formShowSignatures.
  ///
  /// In pt, this message translates to:
  /// **'Incluir espaços de assinatura no rodapé'**
  String get formShowSignatures;

  /// No description provided for @formColumnWidths.
  ///
  /// In pt, this message translates to:
  /// **'Ajustar larguras das colunas'**
  String get formColumnWidths;

  /// No description provided for @formColumnWidthHelp.
  ///
  /// In pt, this message translates to:
  /// **'Larguras proporcionais: um valor maior reserva mais espaço para a coluna dentro da folha.'**
  String get formColumnWidthHelp;

  /// No description provided for @formResetDefaults.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar padrão automático'**
  String get formResetDefaults;

  /// No description provided for @formNoRecords.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum registro encontrado para este documento.'**
  String get formNoRecords;

  /// No description provided for @formPaperOnly.
  ///
  /// In pt, this message translates to:
  /// **'Anotações no papel e alterações na planilha não atualizam os pagamentos ou o estoque do sistema.'**
  String get formPaperOnly;

  /// No description provided for @formPreparing.
  ///
  /// In pt, this message translates to:
  /// **'Calculando páginas do documento…'**
  String get formPreparing;

  /// No description provided for @formSavePdf.
  ///
  /// In pt, this message translates to:
  /// **'Salvar PDF'**
  String get formSavePdf;

  /// No description provided for @formSaveXlsx.
  ///
  /// In pt, this message translates to:
  /// **'Salvar planilha XLSX'**
  String get formSaveXlsx;

  /// No description provided for @formPreview.
  ///
  /// In pt, this message translates to:
  /// **'Prévia do documento'**
  String get formPreview;

  /// No description provided for @formInvalidNumber.
  ///
  /// In pt, this message translates to:
  /// **'Informe um número dentro do intervalo.'**
  String get formInvalidNumber;

  /// No description provided for @formFileSaved.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo salvo no local escolhido.'**
  String get formFileSaved;

  /// No description provided for @formExportFailure.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível gerar ou salvar o documento. Confira as opções e tente novamente.'**
  String get formExportFailure;

  /// No description provided for @formPaymentsHelp.
  ///
  /// In pt, this message translates to:
  /// **'Conferência de fiados: valor original, total recebido, data do pagamento e saldo restante.'**
  String get formPaymentsHelp;

  /// No description provided for @formPayablesHelp.
  ///
  /// In pt, this message translates to:
  /// **'Conferência de obrigações e pagamentos, com valor pago e saldo em colunas próprias.'**
  String get formPayablesHelp;

  /// No description provided for @formInventoryHelp.
  ///
  /// In pt, this message translates to:
  /// **'Contagem de produtos e cestas da loja, com espaços para quantidade física, diferença e conferência.'**
  String get formInventoryHelp;

  /// No description provided for @formDocumentSummary.
  ///
  /// In pt, this message translates to:
  /// **'{columns} colunas · {rows} linhas · {pages} página(s) no PDF'**
  String formDocumentSummary(int columns, int rows, int pages);

  /// No description provided for @paymentFlowDetail.
  ///
  /// In pt, this message translates to:
  /// **'Conta a pagar'**
  String get paymentFlowDetail;

  /// No description provided for @paymentFlowRegister.
  ///
  /// In pt, this message translates to:
  /// **'Registrar pagamento'**
  String get paymentFlowRegister;

  /// No description provided for @paymentFlowBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo em aberto'**
  String get paymentFlowBalance;

  /// No description provided for @paymentFlowTitleRef.
  ///
  /// In pt, this message translates to:
  /// **'Conta #{number}'**
  String paymentFlowTitleRef(int number);

  /// No description provided for @paymentFlowSituation.
  ///
  /// In pt, this message translates to:
  /// **'Situação'**
  String get paymentFlowSituation;

  /// No description provided for @paymentFlowNoHistory.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum pagamento registrado nesta conta.'**
  String get paymentFlowNoHistory;

  /// No description provided for @paymentFlowNotOpen.
  ///
  /// In pt, this message translates to:
  /// **'Esta conta não está aberta para pagamento.'**
  String get paymentFlowNotOpen;

  /// No description provided for @paymentFlowReversed.
  ///
  /// In pt, this message translates to:
  /// **'Estornado'**
  String get paymentFlowReversed;

  /// No description provided for @paymentFlowKind.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de pagamento'**
  String get paymentFlowKind;

  /// No description provided for @paymentFlowFull.
  ///
  /// In pt, this message translates to:
  /// **'Integral'**
  String get paymentFlowFull;

  /// No description provided for @paymentFlowPartial.
  ///
  /// In pt, this message translates to:
  /// **'Parcial'**
  String get paymentFlowPartial;

  /// No description provided for @paymentFlowAmount.
  ///
  /// In pt, this message translates to:
  /// **'Quanto você pagou?'**
  String get paymentFlowAmount;

  /// No description provided for @paymentFlowAmountLimit.
  ///
  /// In pt, this message translates to:
  /// **'Informe um valor entre R\$ 0,01 e {amount}.'**
  String paymentFlowAmountLimit(String amount);

  /// No description provided for @paymentFlowDate.
  ///
  /// In pt, this message translates to:
  /// **'Data do pagamento'**
  String get paymentFlowDate;

  /// No description provided for @paymentFlowMethod.
  ///
  /// In pt, this message translates to:
  /// **'Como você pagou?'**
  String get paymentFlowMethod;

  /// No description provided for @paymentFlowSelectMethod.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a forma de pagamento'**
  String get paymentFlowSelectMethod;

  /// No description provided for @paymentFlowRemaining.
  ///
  /// In pt, this message translates to:
  /// **'Restará em aberto após este registro'**
  String get paymentFlowRemaining;

  /// No description provided for @paymentFlowReview.
  ///
  /// In pt, this message translates to:
  /// **'Revisar pagamento'**
  String get paymentFlowReview;

  /// No description provided for @paymentFlowSending.
  ///
  /// In pt, this message translates to:
  /// **'Registrando…'**
  String get paymentFlowSending;

  /// No description provided for @paymentFlowRecordedOnly.
  ///
  /// In pt, this message translates to:
  /// **'Registre um pagamento que você já realizou. A confirmação lança o registro no aplicativo.'**
  String get paymentFlowRecordedOnly;

  /// No description provided for @paymentFlowBalanceChanged.
  ///
  /// In pt, this message translates to:
  /// **'O saldo mudou. Confira o valor atualizado e revise novamente.'**
  String get paymentFlowBalanceChanged;

  /// No description provided for @paymentFlowUncertain.
  ///
  /// In pt, this message translates to:
  /// **'Esta tentativa aguarda confirmação.'**
  String get paymentFlowUncertain;

  /// No description provided for @paymentFlowResumeHelp.
  ///
  /// In pt, this message translates to:
  /// **'Retomar usa os mesmos dados e pode concluir o pagamento original. Aguarde a confirmação desta tentativa antes de criar outro registro.'**
  String get paymentFlowResumeHelp;

  /// No description provided for @paymentFlowResume.
  ///
  /// In pt, this message translates to:
  /// **'Retomar registro'**
  String get paymentFlowResume;

  /// No description provided for @paymentFlowConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento registrado'**
  String get paymentFlowConfirmed;

  /// No description provided for @paymentFlowReference.
  ///
  /// In pt, this message translates to:
  /// **'Referência do registro'**
  String get paymentFlowReference;

  /// No description provided for @paymentFlowRefreshing.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento registrado. Atualizando a conta…'**
  String get paymentFlowRefreshing;

  /// No description provided for @paymentFlowConfirmedRefreshFailed.
  ///
  /// In pt, this message translates to:
  /// **'O pagamento está registrado. Falta atualizar a consulta da conta.'**
  String get paymentFlowConfirmedRefreshFailed;

  /// No description provided for @paymentFlowCurrentBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo atual consultado'**
  String get paymentFlowCurrentBalance;

  /// No description provided for @paymentFlowFinish.
  ///
  /// In pt, this message translates to:
  /// **'Voltar às contas'**
  String get paymentFlowFinish;

  /// No description provided for @paymentFlowUnexpected.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir esta etapa. Tente atualizar a consulta.'**
  String get paymentFlowUnexpected;

  /// No description provided for @paymentFlowLocalStorage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conservar os dados da tentativa neste aparelho. Atualize antes de continuar.'**
  String get paymentFlowLocalStorage;

  /// No description provided for @paymentFlowConnectionChanged.
  ///
  /// In pt, this message translates to:
  /// **'A conexão foi alterada. Para retomar este registro, volte à conexão original.'**
  String get paymentFlowConnectionChanged;

  /// No description provided for @paymentFlowInvalidConfirmation.
  ///
  /// In pt, this message translates to:
  /// **'A resposta não permitiu confirmar o registro. Retome a mesma tentativa.'**
  String get paymentFlowInvalidConfirmation;

  /// No description provided for @paymentFlowServerUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Atualize o servidor para usar o pagamento com revisão e recuperação.'**
  String get paymentFlowServerUpdate;

  /// No description provided for @paymentFlowPendingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registros para acompanhar'**
  String get paymentFlowPendingTitle;

  /// No description provided for @paymentFlowPendingItem.
  ///
  /// In pt, this message translates to:
  /// **'{beneficiary} · conta #{number}'**
  String paymentFlowPendingItem(String beneficiary, int number);

  /// No description provided for @paymentFlowPendingReadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível consultar os registros pendentes deste aparelho.'**
  String get paymentFlowPendingReadError;

  /// No description provided for @paymentFlowMore.
  ///
  /// In pt, this message translates to:
  /// **'Carregar mais contas'**
  String get paymentFlowMore;

  /// No description provided for @paymentFlowMoreFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as próximas contas.'**
  String get paymentFlowMoreFailed;

  /// No description provided for @paymentFlowValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor deste registro'**
  String get paymentFlowValue;

  /// No description provided for @paymentFlowRecordedRemaining.
  ///
  /// In pt, this message translates to:
  /// **'Saldo após este registro'**
  String get paymentFlowRecordedRemaining;

  /// No description provided for @receiptFlowDetail.
  ///
  /// In pt, this message translates to:
  /// **'Conta a receber'**
  String get receiptFlowDetail;

  /// No description provided for @receiptFlowRegister.
  ///
  /// In pt, this message translates to:
  /// **'Registrar recebimento'**
  String get receiptFlowRegister;

  /// No description provided for @receiptFlowReview.
  ///
  /// In pt, this message translates to:
  /// **'Revisar recebimento'**
  String get receiptFlowReview;

  /// No description provided for @receiptFlowConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Recebimento registrado'**
  String get receiptFlowConfirmed;

  /// No description provided for @receiptFlowNoHistory.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum recebimento registrado nesta conta.'**
  String get receiptFlowNoHistory;

  /// No description provided for @receiptFlowNotOpen.
  ///
  /// In pt, this message translates to:
  /// **'Esta conta não está aberta para recebimento.'**
  String get receiptFlowNotOpen;

  /// No description provided for @receiptFlowKind.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de recebimento'**
  String get receiptFlowKind;

  /// No description provided for @receiptFlowAmount.
  ///
  /// In pt, this message translates to:
  /// **'Quanto você recebeu?'**
  String get receiptFlowAmount;

  /// No description provided for @receiptFlowDate.
  ///
  /// In pt, this message translates to:
  /// **'Data do recebimento'**
  String get receiptFlowDate;

  /// No description provided for @receiptFlowMethod.
  ///
  /// In pt, this message translates to:
  /// **'Como você recebeu?'**
  String get receiptFlowMethod;

  /// No description provided for @receiptFlowSelectMethod.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a forma de recebimento'**
  String get receiptFlowSelectMethod;

  /// No description provided for @receiptFlowRecordedOnly.
  ///
  /// In pt, this message translates to:
  /// **'Registre um valor que você já recebeu. A confirmação lança o registro no aplicativo.'**
  String get receiptFlowRecordedOnly;

  /// No description provided for @receiptFlowResumeHelp.
  ///
  /// In pt, this message translates to:
  /// **'Retomar usa os mesmos dados e pode concluir o recebimento original. Aguarde a confirmação desta tentativa antes de criar outro registro.'**
  String get receiptFlowResumeHelp;

  /// No description provided for @receiptFlowRefreshing.
  ///
  /// In pt, this message translates to:
  /// **'Recebimento registrado. Atualizando a conta…'**
  String get receiptFlowRefreshing;

  /// No description provided for @receiptFlowConfirmedRefreshFailed.
  ///
  /// In pt, this message translates to:
  /// **'O recebimento está registrado. Falta atualizar a consulta da conta.'**
  String get receiptFlowConfirmedRefreshFailed;

  /// No description provided for @receiptFlowServerUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Atualize o servidor para usar o recebimento com revisão e recuperação.'**
  String get receiptFlowServerUpdate;

  /// No description provided for @receiptFlowCash.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro'**
  String get receiptFlowCash;

  /// No description provided for @receiptFlowReceived.
  ///
  /// In pt, this message translates to:
  /// **'Já recebido'**
  String get receiptFlowReceived;

  /// No description provided for @receiptFlowSaleRef.
  ///
  /// In pt, this message translates to:
  /// **'Venda #{number}'**
  String receiptFlowSaleRef(int number);

  /// No description provided for @receiptFlowPendingItem.
  ///
  /// In pt, this message translates to:
  /// **'{customer} · venda #{number}'**
  String receiptFlowPendingItem(String customer, int number);

  /// No description provided for @receiptFlowOrigin.
  ///
  /// In pt, this message translates to:
  /// **'Ver venda de origem'**
  String get receiptFlowOrigin;

  /// No description provided for @receiptFlowOriginHelp.
  ///
  /// In pt, this message translates to:
  /// **'O recebimento reduz ou quita a dívida desta venda.'**
  String get receiptFlowOriginHelp;

  /// No description provided for @receiptFlowSaleTotal.
  ///
  /// In pt, this message translates to:
  /// **'Valor original da venda'**
  String get receiptFlowSaleTotal;

  /// No description provided for @receiptFlowSaleItem.
  ///
  /// In pt, this message translates to:
  /// **'{quantity} × {name}'**
  String receiptFlowSaleItem(int quantity, String name);

  /// No description provided for @receiptFlowBasketFallback.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de cesta {id}'**
  String receiptFlowBasketFallback(String id);

  /// No description provided for @receiptFlowOriginUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conferir a venda de origem. Atualize a consulta.'**
  String get receiptFlowOriginUnavailable;

  /// No description provided for @receiptFlowSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo das contas exibidas'**
  String get receiptFlowSummary;

  /// No description provided for @receiptFlowFilters.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get receiptFlowFilters;

  /// No description provided for @receiptFlowFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas as situações'**
  String get receiptFlowFilterAll;

  /// No description provided for @receiptFlowFilterOpen.
  ///
  /// In pt, this message translates to:
  /// **'Em aberto, incluindo parciais'**
  String get receiptFlowFilterOpen;

  /// No description provided for @receiptFlowFilterScope.
  ///
  /// In pt, this message translates to:
  /// **'{status} · {overdue}'**
  String receiptFlowFilterScope(String status, String overdue);

  /// No description provided for @receiptFlowFilterAnyDue.
  ///
  /// In pt, this message translates to:
  /// **'Todos os vencimentos'**
  String get receiptFlowFilterAnyDue;

  /// No description provided for @receiptFlowFilterApplied.
  ///
  /// In pt, this message translates to:
  /// **'Filtros adicionais aplicados'**
  String get receiptFlowFilterApplied;

  /// No description provided for @receiptFlowSaleDate.
  ///
  /// In pt, this message translates to:
  /// **'Venda em {date}'**
  String receiptFlowSaleDate(String date);

  /// No description provided for @receiptFlowReversalReason.
  ///
  /// In pt, this message translates to:
  /// **'Motivo do estorno: {reason}'**
  String receiptFlowReversalReason(String reason);

  /// No description provided for @appBrand.
  ///
  /// In pt, this message translates to:
  /// **'ZM Cesta Básica'**
  String get appBrand;

  /// No description provided for @appOverview.
  ///
  /// In pt, this message translates to:
  /// **'Visão geral'**
  String get appOverview;

  /// No description provided for @appHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get appHome;

  /// No description provided for @appFinance.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro'**
  String get appFinance;

  /// No description provided for @appBusiness.
  ///
  /// In pt, this message translates to:
  /// **'Negócio'**
  String get appBusiness;

  /// No description provided for @appInventory.
  ///
  /// In pt, this message translates to:
  /// **'Estoque'**
  String get appInventory;

  /// No description provided for @appMore.
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get appMore;

  /// No description provided for @appDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get appDay;

  /// No description provided for @appWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana'**
  String get appWeek;

  /// No description provided for @appMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get appMonth;

  /// No description provided for @appTodayWhen.
  ///
  /// In pt, this message translates to:
  /// **'hoje'**
  String get appTodayWhen;

  /// No description provided for @appWeekWhen.
  ///
  /// In pt, this message translates to:
  /// **'nesta semana'**
  String get appWeekWhen;

  /// No description provided for @appMonthWhen.
  ///
  /// In pt, this message translates to:
  /// **'neste mês'**
  String get appMonthWhen;

  /// No description provided for @appSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get appSummary;

  /// No description provided for @appPay.
  ///
  /// In pt, this message translates to:
  /// **'A pagar'**
  String get appPay;

  /// No description provided for @appReceive.
  ///
  /// In pt, this message translates to:
  /// **'A receber'**
  String get appReceive;

  /// No description provided for @appPayTab.
  ///
  /// In pt, this message translates to:
  /// **'Pagar'**
  String get appPayTab;

  /// No description provided for @appReceiveTab.
  ///
  /// In pt, this message translates to:
  /// **'Receber'**
  String get appReceiveTab;

  /// No description provided for @appFilter.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar'**
  String get appFilter;

  /// No description provided for @appThisWeek.
  ///
  /// In pt, this message translates to:
  /// **'Nesta semana'**
  String get appThisWeek;

  /// No description provided for @appThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Neste mês'**
  String get appThisMonth;

  /// No description provided for @appDueToday.
  ///
  /// In pt, this message translates to:
  /// **'Vencem hoje'**
  String get appDueToday;

  /// No description provided for @appOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Vencidas'**
  String get appOverdue;

  /// No description provided for @appNextThree.
  ///
  /// In pt, this message translates to:
  /// **'Próximos 3 dias'**
  String get appNextThree;

  /// No description provided for @appAllOpen.
  ///
  /// In pt, this message translates to:
  /// **'Todas em aberto'**
  String get appAllOpen;

  /// No description provided for @appCurrentPosition.
  ///
  /// In pt, this message translates to:
  /// **'Posição atual'**
  String get appCurrentPosition;

  /// No description provided for @appBeforeDate.
  ///
  /// In pt, this message translates to:
  /// **'Vencidas · antes de {date}'**
  String appBeforeDate(String date);

  /// No description provided for @appDueScope.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento das contas'**
  String get appDueScope;

  /// No description provided for @appBalancePay.
  ///
  /// In pt, this message translates to:
  /// **'Saldo a pagar'**
  String get appBalancePay;

  /// No description provided for @appBalanceReceive.
  ///
  /// In pt, this message translates to:
  /// **'Saldo a receber'**
  String get appBalanceReceive;

  /// No description provided for @appOpenCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 conta em aberto} other{{count} contas em aberto}}'**
  String appOpenCount(int count);

  /// No description provided for @appPartialCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 parcial} other{{count} parciais}}'**
  String appPartialCount(int count);

  /// No description provided for @appOriginDue.
  ///
  /// In pt, this message translates to:
  /// **'{origin} · Vence {date}'**
  String appOriginDue(String origin, String date);

  /// No description provided for @appPurchaseOrigin.
  ///
  /// In pt, this message translates to:
  /// **'Compra de produtos'**
  String get appPurchaseOrigin;

  /// No description provided for @appSaleOrigin.
  ///
  /// In pt, this message translates to:
  /// **'Venda de cestas'**
  String get appSaleOrigin;

  /// No description provided for @appPartial.
  ///
  /// In pt, this message translates to:
  /// **'Parcial'**
  String get appPartial;

  /// No description provided for @appOpen.
  ///
  /// In pt, this message translates to:
  /// **'Em aberto'**
  String get appOpen;

  /// No description provided for @appDueTodayShort.
  ///
  /// In pt, this message translates to:
  /// **'Vence hoje'**
  String get appDueTodayShort;

  /// No description provided for @appPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pago'**
  String get appPaid;

  /// No description provided for @appReceived.
  ///
  /// In pt, this message translates to:
  /// **'Recebido'**
  String get appReceived;

  /// No description provided for @appOriginalPaid.
  ///
  /// In pt, this message translates to:
  /// **'Original {original} · {kind} {paid}'**
  String appOriginalPaid(String original, String kind, String paid);

  /// No description provided for @appFinanceContext.
  ///
  /// In pt, this message translates to:
  /// **'Pagar, receber e acompanhar vencimentos'**
  String get appFinanceContext;

  /// No description provided for @appOpenInPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Em aberto · vencimentos do período'**
  String get appOpenInPeriod;

  /// No description provided for @appCurrentDeadlines.
  ///
  /// In pt, this message translates to:
  /// **'Vencimentos atuais'**
  String get appCurrentDeadlines;

  /// No description provided for @appAccountAmount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 conta} other{{count} contas}} · {amount}'**
  String appAccountAmount(int count, String amount);

  /// No description provided for @appPendingNotBank.
  ///
  /// In pt, this message translates to:
  /// **'Pendências cadastradas não são saldo bancário. Próximos três dias são separados de hoje.'**
  String get appPendingNotBank;

  /// No description provided for @appOrganizeFinance.
  ///
  /// In pt, this message translates to:
  /// **'Organizar seu financeiro'**
  String get appOrganizeFinance;

  /// No description provided for @appAccountsCards.
  ///
  /// In pt, this message translates to:
  /// **'Contas e cartões'**
  String get appAccountsCards;

  /// No description provided for @appStatements.
  ///
  /// In pt, this message translates to:
  /// **'Extratos e faturas'**
  String get appStatements;

  /// No description provided for @appFutureFeature.
  ///
  /// In pt, this message translates to:
  /// **'Proposta futura. Esta função ainda não está disponível no aplicativo.'**
  String get appFutureFeature;

  /// No description provided for @appAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get appAccounts;

  /// No description provided for @appResults.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 resultado} other{{count} resultados}}'**
  String appResults(int count);

  /// No description provided for @appNoOpenAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta em aberto neste recorte. Você pode consultar outros vencimentos.'**
  String get appNoOpenAccounts;

  /// No description provided for @appHistoryAndRecords.
  ///
  /// In pt, this message translates to:
  /// **'Histórico e cadastros'**
  String get appHistoryAndRecords;

  /// No description provided for @appYourFinance.
  ///
  /// In pt, this message translates to:
  /// **'Seu financeiro {when}'**
  String appYourFinance(String when);

  /// No description provided for @appYourBusiness.
  ///
  /// In pt, this message translates to:
  /// **'Seu negócio {when}'**
  String appYourBusiness(String when);

  /// No description provided for @appOpenDueInPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Em aberto · vencimentos do período'**
  String get appOpenDueInPeriod;

  /// No description provided for @appOpenFinance.
  ///
  /// In pt, this message translates to:
  /// **'Abrir Financeiro'**
  String get appOpenFinance;

  /// No description provided for @appBasketsSold.
  ///
  /// In pt, this message translates to:
  /// **'Cestas vendidas'**
  String get appBasketsSold;

  /// No description provided for @appSalesValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor das vendas'**
  String get appSalesValue;

  /// No description provided for @appAttention.
  ///
  /// In pt, this message translates to:
  /// **'Precisa da sua atenção'**
  String get appAttention;

  /// No description provided for @appNow.
  ///
  /// In pt, this message translates to:
  /// **'Agora'**
  String get appNow;

  /// No description provided for @appLateAccounts.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 conta atrasada} other{{count} contas atrasadas}}'**
  String appLateAccounts(int count);

  /// No description provided for @appTodayPay.
  ///
  /// In pt, this message translates to:
  /// **'Hoje: {amount} a pagar'**
  String appTodayPay(String amount);

  /// No description provided for @appTodayAmounts.
  ///
  /// In pt, this message translates to:
  /// **'Hoje: pagar {pay} · receber {receive}'**
  String appTodayAmounts(String pay, String receive);

  /// No description provided for @appNoLowStock.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto abaixo do mínimo'**
  String get appNoLowStock;

  /// No description provided for @appCheckInventory.
  ///
  /// In pt, this message translates to:
  /// **'Conferir produtos e reposição'**
  String get appCheckInventory;

  /// No description provided for @appLowStockProduct.
  ///
  /// In pt, this message translates to:
  /// **'{name} abaixo do mínimo'**
  String appLowStockProduct(String name);

  /// No description provided for @appStockMinimum.
  ///
  /// In pt, this message translates to:
  /// **'{current} disponíveis · mínimo cadastrado {minimum}'**
  String appStockMinimum(String current, String minimum);

  /// No description provided for @appBusinessContext.
  ///
  /// In pt, this message translates to:
  /// **'Vendas, clientes e resultado · {range}'**
  String appBusinessContext(String range);

  /// No description provided for @appSalesWhen.
  ///
  /// In pt, this message translates to:
  /// **'Vendas {when}'**
  String appSalesWhen(String when);

  /// No description provided for @appBasketsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 cesta vendida} other{{count} cestas vendidas}}'**
  String appBasketsCount(int count);

  /// No description provided for @appBusinessResult.
  ///
  /// In pt, this message translates to:
  /// **'Resultado do negócio · {range}'**
  String appBusinessResult(String range);

  /// No description provided for @appResultExplanation.
  ///
  /// In pt, this message translates to:
  /// **'Vendas menos custos registrados e outras despesas pagas no período.'**
  String get appResultExplanation;

  /// No description provided for @appIncompleteCost.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 venda com custo incompleto} other{{count} vendas com custo incompleto}}'**
  String appIncompleteCost(int count);

  /// No description provided for @appUnderstandResult.
  ///
  /// In pt, this message translates to:
  /// **'Entender o resultado'**
  String get appUnderstandResult;

  /// No description provided for @appSaleRow.
  ///
  /// In pt, this message translates to:
  /// **'{amount} · Conferir itens, cliente e pagamento'**
  String appSaleRow(String amount);

  /// No description provided for @appSales.
  ///
  /// In pt, this message translates to:
  /// **'Vendas'**
  String get appSales;

  /// No description provided for @appSalesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Registrar e consultar vendas'**
  String get appSalesDescription;

  /// No description provided for @appCustomers.
  ///
  /// In pt, this message translates to:
  /// **'Clientes'**
  String get appCustomers;

  /// No description provided for @appCustomersDescription.
  ///
  /// In pt, this message translates to:
  /// **'Cadastros e histórico'**
  String get appCustomersDescription;

  /// No description provided for @appInventoryContext.
  ///
  /// In pt, this message translates to:
  /// **'Produtos, compras e cestas'**
  String get appInventoryContext;

  /// No description provided for @appProducts.
  ///
  /// In pt, this message translates to:
  /// **'Produtos'**
  String get appProducts;

  /// No description provided for @appProductsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Cadastros e posição de estoque'**
  String get appProductsDescription;

  /// No description provided for @appPurchases.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get appPurchases;

  /// No description provided for @appPurchasesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Entradas e fornecedores'**
  String get appPurchasesDescription;

  /// No description provided for @appBasketsAssembly.
  ///
  /// In pt, this message translates to:
  /// **'Cestas e montagens'**
  String get appBasketsAssembly;

  /// No description provided for @appBasketsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Tipos, composição e histórico de montagem'**
  String get appBasketsDescription;

  /// No description provided for @appMovements.
  ///
  /// In pt, this message translates to:
  /// **'Movimentações'**
  String get appMovements;

  /// No description provided for @appMovementsDescription.
  ///
  /// In pt, this message translates to:
  /// **'O que entrou e saiu do estoque'**
  String get appMovementsDescription;

  /// No description provided for @appStockPosition.
  ///
  /// In pt, this message translates to:
  /// **'Posição do estoque'**
  String get appStockPosition;

  /// No description provided for @appMoreContext.
  ///
  /// In pt, this message translates to:
  /// **'Documentos e ferramentas do aplicativo'**
  String get appMoreContext;

  /// No description provided for @appReports.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get appReports;

  /// No description provided for @appReportsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Consultar e exportar os dados'**
  String get appReportsDescription;

  /// No description provided for @appPrinting.
  ///
  /// In pt, this message translates to:
  /// **'Impressão e formulários'**
  String get appPrinting;

  /// No description provided for @appPrintingDescription.
  ///
  /// In pt, this message translates to:
  /// **'PDF e folhas para preencher à caneta'**
  String get appPrintingDescription;

  /// No description provided for @appSettingsConnection.
  ///
  /// In pt, this message translates to:
  /// **'Configurações e conexão'**
  String get appSettingsConnection;

  /// No description provided for @appSettingsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Aparência, servidor e pareamento'**
  String get appSettingsDescription;

  /// No description provided for @appBackup.
  ///
  /// In pt, this message translates to:
  /// **'Backup'**
  String get appBackup;

  /// No description provided for @appBackupDescription.
  ///
  /// In pt, this message translates to:
  /// **'Cópias de segurança e recuperação'**
  String get appBackupDescription;

  /// No description provided for @appConfirmedSales.
  ///
  /// In pt, this message translates to:
  /// **'Vendas confirmadas'**
  String get appConfirmedSales;

  /// No description provided for @appSoldCosts.
  ///
  /// In pt, this message translates to:
  /// **'Custos registrados nas vendas'**
  String get appSoldCosts;

  /// No description provided for @appGrossProfit.
  ///
  /// In pt, this message translates to:
  /// **'Lucro bruto calculado'**
  String get appGrossProfit;

  /// No description provided for @appPaidExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Outras despesas pagas'**
  String get appPaidExpenses;

  /// No description provided for @appResult.
  ///
  /// In pt, this message translates to:
  /// **'Resultado do negócio'**
  String get appResult;

  /// No description provided for @appResultHow.
  ///
  /// In pt, this message translates to:
  /// **'Como este valor é calculado'**
  String get appResultHow;

  /// No description provided for @appResultNotBank.
  ///
  /// In pt, this message translates to:
  /// **'As vendas podem ainda não ter sido recebidas. Este resultado não representa saldo bancário.'**
  String get appResultNotBank;

  /// No description provided for @appReviewType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get appReviewType;

  /// No description provided for @appReviewFull.
  ///
  /// In pt, this message translates to:
  /// **'Integral do saldo atual'**
  String get appReviewFull;

  /// No description provided for @appReviewNoNote.
  ///
  /// In pt, this message translates to:
  /// **'Não informada'**
  String get appReviewNoNote;

  /// No description provided for @appReviewExpectedBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo esperado após o registro'**
  String get appReviewExpectedBalance;

  /// No description provided for @appReviewHelp.
  ///
  /// In pt, this message translates to:
  /// **'O saldo esperado será confirmado depois do registro.'**
  String get appReviewHelp;

  /// No description provided for @appAppearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get appAppearance;

  /// No description provided for @appAppearanceDescription.
  ///
  /// In pt, this message translates to:
  /// **'Tema, cores e acessibilidade'**
  String get appAppearanceDescription;

  /// No description provided for @appAppearanceContext.
  ///
  /// In pt, this message translates to:
  /// **'Preferências de aparência neste aparelho'**
  String get appAppearanceContext;

  /// No description provided for @appFollowDevice.
  ///
  /// In pt, this message translates to:
  /// **'Seguir o aparelho'**
  String get appFollowDevice;

  /// No description provided for @appLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get appLight;

  /// No description provided for @appDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get appDark;

  /// No description provided for @appAccent.
  ///
  /// In pt, this message translates to:
  /// **'Cor de destaque'**
  String get appAccent;

  /// No description provided for @appChooseColor.
  ///
  /// In pt, this message translates to:
  /// **'Escolher cor'**
  String get appChooseColor;

  /// No description provided for @appAccentHelp.
  ///
  /// In pt, this message translates to:
  /// **'Azul original por padrão. A cor é ajustada para manter a leitura.'**
  String get appAccentHelp;

  /// No description provided for @appColorRed.
  ///
  /// In pt, this message translates to:
  /// **'Vermelho'**
  String get appColorRed;

  /// No description provided for @appColorGreen.
  ///
  /// In pt, this message translates to:
  /// **'Verde'**
  String get appColorGreen;

  /// No description provided for @appColorBlue.
  ///
  /// In pt, this message translates to:
  /// **'Azul'**
  String get appColorBlue;

  /// No description provided for @appBackground.
  ///
  /// In pt, this message translates to:
  /// **'Fundo'**
  String get appBackground;

  /// No description provided for @appSoftBackground.
  ///
  /// In pt, this message translates to:
  /// **'Superfície suave'**
  String get appSoftBackground;

  /// No description provided for @appPureBackground.
  ///
  /// In pt, this message translates to:
  /// **'Branco / preto'**
  String get appPureBackground;

  /// No description provided for @appAppearanceSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar a preferência. Tente novamente.'**
  String get appAppearanceSaveError;

  /// No description provided for @appServerConnection.
  ///
  /// In pt, this message translates to:
  /// **'Conexão com o servidor'**
  String get appServerConnection;

  /// No description provided for @appServerDescription.
  ///
  /// In pt, this message translates to:
  /// **'Disponibilidade e pareamento'**
  String get appServerDescription;

  /// No description provided for @appRangeSameMonth.
  ///
  /// In pt, this message translates to:
  /// **'{first} a {last} de {month}'**
  String appRangeSameMonth(String first, String last, String month);

  /// No description provided for @appRangeDifferentMonth.
  ///
  /// In pt, this message translates to:
  /// **'{first} a {last}'**
  String appRangeDifferentMonth(String first, String last);

  /// No description provided for @pdfImportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Extratos e faturas'**
  String get pdfImportTitle;

  /// No description provided for @pdfImportEntry.
  ///
  /// In pt, this message translates to:
  /// **'Importar PDF e conferir documentos'**
  String get pdfImportEntry;

  /// No description provided for @pdfImportAction.
  ///
  /// In pt, this message translates to:
  /// **'Importar PDF'**
  String get pdfImportAction;

  /// No description provided for @pdfImportChoose.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar PDF'**
  String get pdfImportChoose;

  /// No description provided for @pdfImportRead.
  ///
  /// In pt, this message translates to:
  /// **'Ler documento'**
  String get pdfImportRead;

  /// No description provided for @pdfImportHelp.
  ///
  /// In pt, this message translates to:
  /// **'Envie um PDF com texto, de até 10 MiB. Layouts testados: faturas Nubank/PicPay e extratos Nubank PF/PJ. PDFs escaneados, protegidos por senha ou de outros formatos podem não ser lidos.'**
  String get pdfImportHelp;

  /// No description provided for @pdfImportEffect.
  ///
  /// In pt, this message translates to:
  /// **'A importação guarda o documento e os lançamentos pendentes de revisão. Não cria contas a pagar, pagamentos ou conciliação automática.'**
  String get pdfImportEffect;

  /// No description provided for @pdfImportSource.
  ///
  /// In pt, this message translates to:
  /// **'Conta ou cartão do documento'**
  String get pdfImportSource;

  /// No description provided for @pdfImportSourceCheck.
  ///
  /// In pt, this message translates to:
  /// **'Confira a conta/cartão e a titularidade. O leitor não verifica se o documento pertence à origem escolhida.'**
  String get pdfImportSourceCheck;

  /// No description provided for @pdfImportNewSource.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar conta ou cartão'**
  String get pdfImportNewSource;

  /// No description provided for @pdfImportSourceName.
  ///
  /// In pt, this message translates to:
  /// **'Nome para identificar a conta ou cartão'**
  String get pdfImportSourceName;

  /// No description provided for @pdfImportInstitution.
  ///
  /// In pt, this message translates to:
  /// **'Instituição financeira'**
  String get pdfImportInstitution;

  /// No description provided for @pdfImportBank.
  ///
  /// In pt, this message translates to:
  /// **'Conta bancária'**
  String get pdfImportBank;

  /// No description provided for @pdfImportCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão de crédito'**
  String get pdfImportCard;

  /// No description provided for @pdfImportHolder.
  ///
  /// In pt, this message translates to:
  /// **'Titularidade'**
  String get pdfImportHolder;

  /// No description provided for @pdfImportPF.
  ///
  /// In pt, this message translates to:
  /// **'Pessoa física'**
  String get pdfImportPF;

  /// No description provided for @pdfImportPJ.
  ///
  /// In pt, this message translates to:
  /// **'Pessoa jurídica'**
  String get pdfImportPJ;

  /// No description provided for @pdfImportBankLink.
  ///
  /// In pt, this message translates to:
  /// **'Vincular conta bancária cadastrada'**
  String get pdfImportBankLink;

  /// No description provided for @pdfImportNewBank.
  ///
  /// In pt, this message translates to:
  /// **'Criar cadastro bancário para esta origem'**
  String get pdfImportNewBank;

  /// No description provided for @pdfImportBankHelp.
  ///
  /// In pt, this message translates to:
  /// **'O vínculo identifica a conta do extrato. Um novo cadastro é criado sem saldo de abertura e sem movimentação de dinheiro.'**
  String get pdfImportBankHelp;

  /// No description provided for @pdfImportNoSources.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre a conta ou cartão antes de importar. Use um nome que permita distinguir banco e titularidade.'**
  String get pdfImportNoSources;

  /// No description provided for @pdfImportHistory.
  ///
  /// In pt, this message translates to:
  /// **'Documentos enviados'**
  String get pdfImportHistory;

  /// No description provided for @pdfImportEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum PDF enviado nesta consulta.'**
  String get pdfImportEmpty;

  /// No description provided for @pdfImportMore.
  ///
  /// In pt, this message translates to:
  /// **'Carregar mais'**
  String get pdfImportMore;

  /// No description provided for @pdfImportReady.
  ///
  /// In pt, this message translates to:
  /// **'Leitura concluída · conferir antes de guardar'**
  String get pdfImportReady;

  /// No description provided for @pdfImportBlocked.
  ///
  /// In pt, this message translates to:
  /// **'Leitura bloqueada · confirmação indisponível'**
  String get pdfImportBlocked;

  /// No description provided for @pdfImportConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Documento guardado · revisão pendente'**
  String get pdfImportConfirmed;

  /// No description provided for @pdfImportConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Guardar para revisão'**
  String get pdfImportConfirm;

  /// No description provided for @pdfImportAcknowledged.
  ///
  /// In pt, this message translates to:
  /// **'Conferi a origem, os dados extraídos e os avisos.'**
  String get pdfImportAcknowledged;

  /// No description provided for @pdfImportSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Documento guardado. Os lançamentos continuam pendentes de revisão, sem criar dívidas ou pagamentos.'**
  String get pdfImportSuccess;

  /// No description provided for @pdfImportRetry.
  ///
  /// In pt, this message translates to:
  /// **'Consultar novamente'**
  String get pdfImportRetry;

  /// No description provided for @pdfImportBusy.
  ///
  /// In pt, this message translates to:
  /// **'Enviando e lendo o PDF…'**
  String get pdfImportBusy;

  /// No description provided for @pdfImportReading.
  ///
  /// In pt, this message translates to:
  /// **'Conferência do documento'**
  String get pdfImportReading;

  /// No description provided for @pdfImportItems.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos extraídos'**
  String get pdfImportItems;

  /// No description provided for @pdfImportPages.
  ///
  /// In pt, this message translates to:
  /// **'Texto das páginas'**
  String get pdfImportPages;

  /// No description provided for @pdfImportOriginal.
  ///
  /// In pt, this message translates to:
  /// **'Visualizar PDF original'**
  String get pdfImportOriginal;

  /// No description provided for @pdfImportOriginalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Documento original'**
  String get pdfImportOriginalTitle;

  /// No description provided for @pdfImportWarnings.
  ///
  /// In pt, this message translates to:
  /// **'Avisos e impedimentos'**
  String get pdfImportWarnings;

  /// No description provided for @pdfImportControls.
  ///
  /// In pt, this message translates to:
  /// **'Conferências de totais do documento'**
  String get pdfImportControls;

  /// No description provided for @pdfImportControlOk.
  ///
  /// In pt, this message translates to:
  /// **'Valores correspondentes'**
  String get pdfImportControlOk;

  /// No description provided for @pdfImportControlFail.
  ///
  /// In pt, this message translates to:
  /// **'Valores divergentes'**
  String get pdfImportControlFail;

  /// No description provided for @pdfImportPage.
  ///
  /// In pt, this message translates to:
  /// **'Página {number}'**
  String pdfImportPage(int number);

  /// No description provided for @pdfImportCounts.
  ///
  /// In pt, this message translates to:
  /// **'{items} lançamentos · {pages} páginas'**
  String pdfImportCounts(int items, int pages);

  /// No description provided for @pdfImportCoverage.
  ///
  /// In pt, this message translates to:
  /// **'Exibindo {loaded} de {total} lançamentos extraídos.'**
  String pdfImportCoverage(int loaded, int total);

  /// No description provided for @pdfImportInstallments.
  ///
  /// In pt, this message translates to:
  /// **'Parcela {current} de {total}'**
  String pdfImportInstallments(int current, int total);

  /// No description provided for @pdfImportPartialYear.
  ///
  /// In pt, this message translates to:
  /// **'Algumas datas não trazem o ano. O leitor usou o ciclo da fatura para completá-las; confira no original.'**
  String get pdfImportPartialYear;

  /// No description provided for @pdfImportSignBank.
  ///
  /// In pt, this message translates to:
  /// **'Entradas positivas e saídas negativas, conforme o extrato.'**
  String get pdfImportSignBank;

  /// No description provided for @pdfImportSignCard.
  ///
  /// In pt, this message translates to:
  /// **'Compras positivas e créditos/pagamentos negativos. Pagamento de fatura anterior não quita a atual.'**
  String get pdfImportSignCard;

  /// No description provided for @pdfImportPeriodStart.
  ///
  /// In pt, this message translates to:
  /// **'Início do período'**
  String get pdfImportPeriodStart;

  /// No description provided for @pdfImportPeriodEnd.
  ///
  /// In pt, this message translates to:
  /// **'Fim do período'**
  String get pdfImportPeriodEnd;

  /// No description provided for @pdfImportIssued.
  ///
  /// In pt, this message translates to:
  /// **'Emissão'**
  String get pdfImportIssued;

  /// No description provided for @pdfImportClosing.
  ///
  /// In pt, this message translates to:
  /// **'Fechamento'**
  String get pdfImportClosing;

  /// No description provided for @pdfImportDue.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento'**
  String get pdfImportDue;

  /// No description provided for @pdfImportTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total declarado'**
  String get pdfImportTotal;

  /// No description provided for @pdfImportMinimum.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento mínimo'**
  String get pdfImportMinimum;

  /// No description provided for @pdfImportOpeningBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo inicial declarado'**
  String get pdfImportOpeningBalance;

  /// No description provided for @pdfImportClosingBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo final declarado'**
  String get pdfImportClosingBalance;

  /// No description provided for @pdfImportInflows.
  ///
  /// In pt, this message translates to:
  /// **'Entradas declaradas'**
  String get pdfImportInflows;

  /// No description provided for @pdfImportOutflows.
  ///
  /// In pt, this message translates to:
  /// **'Saídas declaradas'**
  String get pdfImportOutflows;

  /// No description provided for @pdfImportBillEquation.
  ///
  /// In pt, this message translates to:
  /// **'Composição do total da fatura'**
  String get pdfImportBillEquation;

  /// No description provided for @pdfImportDetailsCheck.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes e resumo da fatura'**
  String get pdfImportDetailsCheck;

  /// No description provided for @pdfImportSectionCheck.
  ///
  /// In pt, this message translates to:
  /// **'Subtotal da seção'**
  String get pdfImportSectionCheck;

  /// No description provided for @pdfImportBalanceCheck.
  ///
  /// In pt, this message translates to:
  /// **'Equação dos saldos'**
  String get pdfImportBalanceCheck;

  /// No description provided for @pdfImportInflowsCheck.
  ///
  /// In pt, this message translates to:
  /// **'Total de entradas'**
  String get pdfImportInflowsCheck;

  /// No description provided for @pdfImportOutflowsCheck.
  ///
  /// In pt, this message translates to:
  /// **'Total de saídas'**
  String get pdfImportOutflowsCheck;

  /// No description provided for @pdfImportCandidate.
  ///
  /// In pt, this message translates to:
  /// **'Há registros semelhantes no sistema. Essa semelhança não comprova duplicidade; a revisão é separada.'**
  String get pdfImportCandidate;

  /// No description provided for @pdfImportServerUpdate.
  ///
  /// In pt, this message translates to:
  /// **'O servidor precisa da atualização e da migração financeira antes de receber documentos. Solicite a preparação da instalação.'**
  String get pdfImportServerUpdate;

  /// No description provided for @pdfImportRuntime.
  ///
  /// In pt, this message translates to:
  /// **'O leitor de PDF não está disponível nesta instalação do servidor. É necessário preparar o runtime antes de importar.'**
  String get pdfImportRuntime;

  /// No description provided for @pdfImportProcessing.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir a leitura agora. Tente novamente com o mesmo arquivo e a mesma origem.'**
  String get pdfImportProcessing;

  /// No description provided for @pdfImportSize.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um PDF não vazio, com até 10 MiB.'**
  String get pdfImportSize;

  /// No description provided for @pdfImportInvalidFile.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ler este PDF. Confira se o arquivo está íntegro e é um PDF válido.'**
  String get pdfImportInvalidFile;

  /// No description provided for @pdfImportPassword.
  ///
  /// In pt, this message translates to:
  /// **'Este PDF exige senha. A leitura de arquivos protegidos ainda não está disponível.'**
  String get pdfImportPassword;

  /// No description provided for @pdfImportOcr.
  ///
  /// In pt, this message translates to:
  /// **'Há página sem texto extraível. A leitura de PDFs escaneados ainda não está disponível.'**
  String get pdfImportOcr;

  /// No description provided for @pdfImportUnsupported.
  ///
  /// In pt, this message translates to:
  /// **'O formato deste documento ainda não tem um leitor confirmado. Use um layout testado ou solicite ampliação do leitor.'**
  String get pdfImportUnsupported;

  /// No description provided for @pdfImportMismatch.
  ///
  /// In pt, this message translates to:
  /// **'Os totais do documento não correspondem aos detalhes. A confirmação está bloqueada; confira o original.'**
  String get pdfImportMismatch;

  /// No description provided for @pdfImportUnknownRow.
  ///
  /// In pt, this message translates to:
  /// **'Há linha monetária ou data que não pôde ser interpretada com segurança. Confira a página indicada; a confirmação está bloqueada.'**
  String get pdfImportUnknownRow;

  /// No description provided for @pdfImportWrongSource.
  ///
  /// In pt, this message translates to:
  /// **'O tipo do documento não corresponde à conta ou cartão escolhido. Importe novamente com a origem correta.'**
  String get pdfImportWrongSource;

  /// No description provided for @pdfImportLimit.
  ///
  /// In pt, this message translates to:
  /// **'O PDF ultrapassa os limites de páginas ou conteúdo do leitor. A confirmação está bloqueada.'**
  String get pdfImportLimit;

  /// No description provided for @pdfImportHeader.
  ///
  /// In pt, this message translates to:
  /// **'O cabeçalho, os controles ou os lançamentos estão incompletos ou conflitantes. Confira o original; a confirmação está bloqueada.'**
  String get pdfImportHeader;

  /// No description provided for @pdfImportBlockedHelp.
  ///
  /// In pt, this message translates to:
  /// **'Este documento não pode ser confirmado. Confira os impedimentos e o original.'**
  String get pdfImportBlockedHelp;

  /// No description provided for @pdfImportSourceExists.
  ///
  /// In pt, this message translates to:
  /// **'Esta conta já possui uma origem de importação. Atualize a lista e selecione a origem existente.'**
  String get pdfImportSourceExists;

  /// No description provided for @pdfImportInvalidSource.
  ///
  /// In pt, this message translates to:
  /// **'Confira os dados da origem. O extrato exige uma conta bancária ativa e o leitor atual exige reais.'**
  String get pdfImportInvalidSource;

  /// No description provided for @pdfImportUnknownIssue.
  ///
  /// In pt, this message translates to:
  /// **'A leitura identificou um impedimento. Confira o original e solicite análise do formato.'**
  String get pdfImportUnknownIssue;

  /// No description provided for @pdfImportUncertain.
  ///
  /// In pt, this message translates to:
  /// **'A resposta não foi recebida. Consulte os documentos ou repita com o mesmo PDF e a mesma origem para recuperar o resultado.'**
  String get pdfImportUncertain;

  /// No description provided for @pdfImportNoText.
  ///
  /// In pt, this message translates to:
  /// **'Esta página não contém texto extraível.'**
  String get pdfImportNoText;

  /// No description provided for @pdfImportDocument.
  ///
  /// In pt, this message translates to:
  /// **'Documento financeiro'**
  String get pdfImportDocument;

  /// No description provided for @pdfImportSourceRequired.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a conta ou cartão do documento.'**
  String get pdfImportSourceRequired;

  /// No description provided for @pdfImportRequired.
  ///
  /// In pt, this message translates to:
  /// **'Preencha de 2 a 100 caracteres.'**
  String get pdfImportRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
