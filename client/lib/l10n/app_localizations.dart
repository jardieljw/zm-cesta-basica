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

  /// No description provided for @commonFilter.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar'**
  String get commonFilter;

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

  /// No description provided for @commonNo.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get commonNo;

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

  /// No description provided for @commonUnit.
  ///
  /// In pt, this message translates to:
  /// **'un'**
  String get commonUnit;

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

  /// No description provided for @productCostPrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço de Custo'**
  String get productCostPrice;

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

  /// No description provided for @recipesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ficha Técnica / Receita'**
  String get recipesTitle;

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

  /// No description provided for @recipeQuantityPerBasket.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade por Cesta'**
  String get recipeQuantityPerBasket;

  /// No description provided for @recipeSection.
  ///
  /// In pt, this message translates to:
  /// **'Seção do Insumo'**
  String get recipeSection;

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

  /// No description provided for @productionBatchNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova Montagem de Cestas'**
  String get productionBatchNew;

  /// No description provided for @productionBatchNumber.
  ///
  /// In pt, this message translates to:
  /// **'Lote #{number}'**
  String productionBatchNumber(int number);

  /// No description provided for @productionQuantityProduced.
  ///
  /// In pt, this message translates to:
  /// **'Qtd. Produzida'**
  String get productionQuantityProduced;

  /// No description provided for @productionQuantityDisassembled.
  ///
  /// In pt, this message translates to:
  /// **'Qtd. Desmontada'**
  String get productionQuantityDisassembled;

  /// No description provided for @productionCurrentStock.
  ///
  /// In pt, this message translates to:
  /// **'Saldo em Estoque'**
  String get productionCurrentStock;

  /// No description provided for @productionUnitCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo Unitário'**
  String get productionUnitCost;

  /// No description provided for @productionTotalCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo Total do Lote'**
  String get productionTotalCost;

  /// No description provided for @productionStatusConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Confirmado'**
  String get productionStatusConfirmed;

  /// No description provided for @productionStatusDisassembled.
  ///
  /// In pt, this message translates to:
  /// **'Desmontado'**
  String get productionStatusDisassembled;

  /// No description provided for @productionStatusCanceled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get productionStatusCanceled;

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

  /// No description provided for @productionDisassembleReasonHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Avaria em embalagem, readequação'**
  String get productionDisassembleReasonHint;

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

  /// No description provided for @productionLossReasonLabel.
  ///
  /// In pt, this message translates to:
  /// **'Motivo da Perda'**
  String get productionLossReasonLabel;

  /// No description provided for @productionDisassembleDescription.
  ///
  /// In pt, this message translates to:
  /// **'A desmontagem realiza triagem física: itens intactos retornam ao estoque e avarias são registradas como perda sem inflar o estoque fisicamente.'**
  String get productionDisassembleDescription;

  /// No description provided for @productionDisassembledSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Lote desmontado com sucesso!'**
  String get productionDisassembledSuccess;

  /// No description provided for @productionBatchSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por lote (#1), tipo ou observações...'**
  String get productionBatchSearchHint;

  /// No description provided for @productionBatchFilterAllStatus.
  ///
  /// In pt, this message translates to:
  /// **'Todos os Status'**
  String get productionBatchFilterAllStatus;

  /// No description provided for @productionBatchFilterConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Confirmados'**
  String get productionBatchFilterConfirmed;

  /// No description provided for @productionBatchFilterDisassembled.
  ///
  /// In pt, this message translates to:
  /// **'Desmontados'**
  String get productionBatchFilterDisassembled;

  /// No description provided for @productionBatchFilterAllTypes.
  ///
  /// In pt, this message translates to:
  /// **'Todos os Tipos'**
  String get productionBatchFilterAllTypes;

  /// No description provided for @productionBatchFilterStandard.
  ///
  /// In pt, this message translates to:
  /// **'Cesta Padrão'**
  String get productionBatchFilterStandard;

  /// No description provided for @productionBatchFilterCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizada'**
  String get productionBatchFilterCustom;

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

  /// No description provided for @productionBatchCancelDescription.
  ///
  /// In pt, this message translates to:
  /// **'Esta operação cancela a ordem de produção, deduz o saldo das cestas acabadas e retorna 100% dos insumos consumidos ao estoque fisicamente.\\n\\nRequer que todas as cestas acabadas estejam disponíveis em estoque.'**
  String get productionBatchCancelDescription;

  /// No description provided for @productionBatchCancelReasonLabel.
  ///
  /// In pt, this message translates to:
  /// **'Motivo do Estorno'**
  String get productionBatchCancelReasonLabel;

  /// No description provided for @productionBatchCancelReasonHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Ordem gerada em duplicidade'**
  String get productionBatchCancelReasonHint;

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

  /// No description provided for @productionBatchSnapshotTitle.
  ///
  /// In pt, this message translates to:
  /// **'Snapshot Imutável de Insumos Consumidos'**
  String get productionBatchSnapshotTitle;

  /// No description provided for @productionBatchSectionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Seção: {section} | Custo un: {cost}'**
  String productionBatchSectionLabel(String section, String cost);

  /// No description provided for @productionBatchTotalItemCost.
  ///
  /// In pt, this message translates to:
  /// **'Total: {cost}'**
  String productionBatchTotalItemCost(String cost);

  /// No description provided for @productionBatchDisassembleButton.
  ///
  /// In pt, this message translates to:
  /// **'Desmontar Lote'**
  String get productionBatchDisassembleButton;

  /// No description provided for @productionBatchCancelButton.
  ///
  /// In pt, this message translates to:
  /// **'Estorno Total'**
  String get productionBatchCancelButton;

  /// No description provided for @productionBatchDetailProduced.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade Produzida'**
  String get productionBatchDetailProduced;

  /// No description provided for @productionBatchDetailStock.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Disponível'**
  String get productionBatchDetailStock;

  /// No description provided for @productionBatchDetailDisassembled.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade Desmontada'**
  String get productionBatchDetailDisassembled;

  /// No description provided for @productionBatchDetailUnitCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo Unitário'**
  String get productionBatchDetailUnitCost;

  /// No description provided for @productionBatchDetailTotalCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo Total'**
  String get productionBatchDetailTotalCost;

  /// No description provided for @productionBatchDetailDate.
  ///
  /// In pt, this message translates to:
  /// **'Data: {date}'**
  String productionBatchDetailDate(String date);

  /// No description provided for @productionBatchDetailNotes.
  ///
  /// In pt, this message translates to:
  /// **'Observações: {notes}'**
  String productionBatchDetailNotes(String notes);

  /// No description provided for @productionBatchDetailDisassembledAt.
  ///
  /// In pt, this message translates to:
  /// **'Desmontado em: {date} ({reason})'**
  String productionBatchDetailDisassembledAt(String date, String reason);

  /// No description provided for @productionBatchDescriptionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição: {description}'**
  String productionBatchDescriptionLabel(String description);

  /// No description provided for @productionBatchConsumedTotal.
  ///
  /// In pt, this message translates to:
  /// **'Consumido total: {quantity}'**
  String productionBatchConsumedTotal(String quantity);

  /// No description provided for @validationInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Inválido'**
  String get validationInvalid;

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

  /// No description provided for @validationInsufficientStockForDisassembly.
  ///
  /// In pt, this message translates to:
  /// **'Saldo insuficiente para desmontagem: máximo permitido é de {max} unidade(s).'**
  String validationInsufficientStockForDisassembly(int max);

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

  /// No description provided for @homePhase4Header.
  ///
  /// In pt, this message translates to:
  /// **'Produção e Desmontagem'**
  String get homePhase4Header;

  /// No description provided for @homeProductionBatchesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de ordens, desmontagem com triagem e estorno total.'**
  String get homeProductionBatchesDescription;

  /// No description provided for @homeProductionAssemblyDescription.
  ///
  /// In pt, this message translates to:
  /// **'Simulação de viabilidade com CMPM e baixa atômica.'**
  String get homeProductionAssemblyDescription;

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
  /// **'Deseja inativar o produto \"{name}\"?\n\nA exclusão física é proibida para preservar a integridade das transações anteriores. O produto deixará de aparecer em novas composições.'**
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
  /// **'Embalagens ({count})'**
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
  /// **'Embalagens Comerciais'**
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
  /// **'Quantidade na Unidade Base * ({unit})'**
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
  /// **'Controla Estoque de Cesta Acabada'**
  String get basketTypeFormTracksStock;

  /// No description provided for @basketTypeFormTracksStockSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Mantém saldo da cesta como produto acabado no inventário.'**
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
  /// **'Embalagem'**
  String get purchaseFormPackagingLabel;

  /// No description provided for @purchaseFormBaseUnitPackaging.
  ///
  /// In pt, this message translates to:
  /// **'Unidade Base ({unit})'**
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

  /// No description provided for @assemblyHeaderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Montagem de Cestas (Ordem de Produção)'**
  String get assemblyHeaderTitle;

  /// No description provided for @assemblyTabStandard.
  ///
  /// In pt, this message translates to:
  /// **'Cesta Padrão'**
  String get assemblyTabStandard;

  /// No description provided for @assemblyTabCustom.
  ///
  /// In pt, this message translates to:
  /// **'Cesta Personalizada'**
  String get assemblyTabCustom;

  /// No description provided for @assemblyStandardBasketLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Cesta *'**
  String get assemblyStandardBasketLabel;

  /// No description provided for @assemblyStandardQtyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade a Montar *'**
  String get assemblyStandardQtyLabel;

  /// No description provided for @assemblyStandardQtyValidation.
  ///
  /// In pt, this message translates to:
  /// **'Informe uma quantidade válida maior que zero'**
  String get assemblyStandardQtyValidation;

  /// No description provided for @assemblyStandardDirectSale.
  ///
  /// In pt, this message translates to:
  /// **'Venda Direta (Não adiciona ao estoque acabado)'**
  String get assemblyStandardDirectSale;

  /// No description provided for @assemblyStandardDirectSaleSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Baixa os insumos consumidos sem criar saldo da cesta montada no inventário.'**
  String get assemblyStandardDirectSaleSubtitle;

  /// No description provided for @assemblyStandardNotesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Observações da Ordem'**
  String get assemblyStandardNotesLabel;

  /// No description provided for @assemblyStandardNotesHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Pedido especial cliente XPTO'**
  String get assemblyStandardNotesHint;

  /// No description provided for @assemblyFeasibilityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Simulação de Viabilidade e Custo Médio (CMPM)'**
  String get assemblyFeasibilityTitle;

  /// No description provided for @assemblyFeasibleOk.
  ///
  /// In pt, this message translates to:
  /// **'Estoque Suficiente para Montagem'**
  String get assemblyFeasibleOk;

  /// No description provided for @assemblyFeasibleFail.
  ///
  /// In pt, this message translates to:
  /// **'Estoque Insuficiente para Montagem'**
  String get assemblyFeasibleFail;

  /// No description provided for @assemblyTotalCostPreview.
  ///
  /// In pt, this message translates to:
  /// **'Custo Total do Lote: {cost}'**
  String assemblyTotalCostPreview(String cost);

  /// No description provided for @assemblyUnitCostPreview.
  ///
  /// In pt, this message translates to:
  /// **'Custo Unitário da Cesta: {cost}'**
  String assemblyUnitCostPreview(String cost);

  /// No description provided for @assemblyConfirmDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Montagem de Cestas'**
  String get assemblyConfirmDialogTitle;

  /// No description provided for @assemblyConfirmDialogContent.
  ///
  /// In pt, this message translates to:
  /// **'Deseja confirmar a montagem de {qty} cesta(s) \"{name}\"?\n\nOs insumos serão baixados e o lote de cestas acabadas será adicionado ao estoque imediatamente.'**
  String assemblyConfirmDialogContent(int qty, String name);

  /// No description provided for @assemblyConfirmSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Lote #{number} montado com sucesso! Custo unitário: {cost}'**
  String assemblyConfirmSuccess(int number, String cost);

  /// No description provided for @assemblySubmitStandard.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Montagem da Cesta Padrão'**
  String get assemblySubmitStandard;

  /// No description provided for @assemblySubmitCustom.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Montagem da Cesta Personalizada'**
  String get assemblySubmitCustom;

  /// No description provided for @assemblyCustomBaseBasket.
  ///
  /// In pt, this message translates to:
  /// **'Modelo Base da Cesta'**
  String get assemblyCustomBaseBasket;

  /// No description provided for @assemblyCustomDescLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição da Cesta Personalizada *'**
  String get assemblyCustomDescLabel;

  /// No description provided for @assemblyCustomDescHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Cesta Natalina Especial para Empresa Alpha'**
  String get assemblyCustomDescHint;

  /// No description provided for @assemblyCustomDescRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe a descrição da cesta personalizada'**
  String get assemblyCustomDescRequired;

  /// No description provided for @assemblyCustomItemsHeader.
  ///
  /// In pt, this message translates to:
  /// **'Composição Customizada de Insumos ({count})'**
  String assemblyCustomItemsHeader(int count);

  /// No description provided for @assemblyCustomAddItem.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Insumo'**
  String get assemblyCustomAddItem;

  /// No description provided for @assemblyCustomQtyValidation.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade inválida'**
  String get assemblyCustomQtyValidation;

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
  /// **'Câmera aguardando permissão ou reinicialização.'**
  String get cameraPermissionDenied;

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

  /// No description provided for @categoryHygiene.
  ///
  /// In pt, this message translates to:
  /// **'Higiene'**
  String get categoryHygiene;

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

  /// No description provided for @productionDisassemble.
  ///
  /// In pt, this message translates to:
  /// **'Desmontar'**
  String get productionDisassemble;

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
  /// **'Estoque Acabado'**
  String get saleAssemblyModeStock;

  /// No description provided for @saleAssemblyModeDemand.
  ///
  /// In pt, this message translates to:
  /// **'Montar Imediatamente'**
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
  /// **'Saldo disponível: {qty}'**
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

  /// No description provided for @homeDispatchesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Controle de saídas físicas, conferência e repasses'**
  String get homeDispatchesDescription;

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

  /// No description provided for @responsiblePersonNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo Responsável'**
  String get responsiblePersonNew;

  /// No description provided for @responsiblePersonEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar Responsável'**
  String get responsiblePersonEdit;

  /// No description provided for @responsiblePersonName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get responsiblePersonName;

  /// No description provided for @responsiblePersonPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone / WhatsApp'**
  String get responsiblePersonPhone;

  /// No description provided for @responsiblePersonNotes.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get responsiblePersonNotes;

  /// No description provided for @responsiblePersonActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get responsiblePersonActive;

  /// No description provided for @responsiblePersonInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get responsiblePersonInactive;

  /// No description provided for @responsiblePersonsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma pessoa responsável cadastrada.'**
  String get responsiblePersonsEmpty;

  /// No description provided for @responsiblePersonCustodyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Custódia Atual de Cestas'**
  String get responsiblePersonCustodyTitle;

  /// No description provided for @responsiblePersonTotalInCustody.
  ///
  /// In pt, this message translates to:
  /// **'Total sob custódia: {qty} cestas'**
  String responsiblePersonTotalInCustody(int qty);

  /// No description provided for @responsiblePersonNoCustody.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma cesta sob custódia no momento.'**
  String get responsiblePersonNoCustody;

  /// No description provided for @responsiblePersonSavedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Responsável salvo com sucesso.'**
  String get responsiblePersonSavedSuccess;

  /// No description provided for @dispatchesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Saídas Físicas e Conferência'**
  String get dispatchesTitle;

  /// No description provided for @dispatchNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova Saída de Cestas'**
  String get dispatchNew;

  /// No description provided for @dispatchNumber.
  ///
  /// In pt, this message translates to:
  /// **'Saída #{number}'**
  String dispatchNumber(int number);

  /// No description provided for @dispatchResponsible.
  ///
  /// In pt, this message translates to:
  /// **'Responsável'**
  String get dispatchResponsible;

  /// No description provided for @dispatchDate.
  ///
  /// In pt, this message translates to:
  /// **'Data da Saída'**
  String get dispatchDate;

  /// No description provided for @dispatchTotalBaskets.
  ///
  /// In pt, this message translates to:
  /// **'Total de Cestas'**
  String get dispatchTotalBaskets;

  /// No description provided for @dispatchTotalReference.
  ///
  /// In pt, this message translates to:
  /// **'Valor de Referência'**
  String get dispatchTotalReference;

  /// No description provided for @dispatchStatusOpen.
  ///
  /// In pt, this message translates to:
  /// **'Aberta'**
  String get dispatchStatusOpen;

  /// No description provided for @dispatchStatusConcluded.
  ///
  /// In pt, this message translates to:
  /// **'Concluída'**
  String get dispatchStatusConcluded;

  /// No description provided for @dispatchStatusPendingInvestigation.
  ///
  /// In pt, this message translates to:
  /// **'Sob Investigação'**
  String get dispatchStatusPendingInvestigation;

  /// No description provided for @dispatchStatusCanceled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelada'**
  String get dispatchStatusCanceled;

  /// No description provided for @dispatchStatusResolved.
  ///
  /// In pt, this message translates to:
  /// **'Resolvido'**
  String get dispatchStatusResolved;

  /// No description provided for @dispatchesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma saída física registrada.'**
  String get dispatchesEmpty;

  /// No description provided for @dispatchCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar Saída'**
  String get dispatchCancel;

  /// No description provided for @dispatchCancelConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja realmente cancelar a saída #{number}?'**
  String dispatchCancelConfirm(int number);

  /// No description provided for @dispatchCancelReason.
  ///
  /// In pt, this message translates to:
  /// **'Motivo do cancelamento'**
  String get dispatchCancelReason;

  /// No description provided for @dispatchCancelSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Saída cancelada com sucesso. Cestas retornadas ao estoque da loja.'**
  String get dispatchCancelSuccess;

  /// No description provided for @dispatchCreatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Saída registrada com sucesso.'**
  String get dispatchCreatedSuccess;

  /// No description provided for @dispatchFormTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Saída Física'**
  String get dispatchFormTitle;

  /// No description provided for @dispatchSelectResponsible.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o Responsável'**
  String get dispatchSelectResponsible;

  /// No description provided for @dispatchItemsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cestas a Retirar'**
  String get dispatchItemsTitle;

  /// No description provided for @dispatchAddItem.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Cesta'**
  String get dispatchAddItem;

  /// No description provided for @dispatchItemBasket.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Cesta'**
  String get dispatchItemBasket;

  /// No description provided for @dispatchItemQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get dispatchItemQuantity;

  /// No description provided for @dispatchItemUnitPrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço de Referência'**
  String get dispatchItemUnitPrice;

  /// No description provided for @dispatchItemSubtotal.
  ///
  /// In pt, this message translates to:
  /// **'Subtotal'**
  String get dispatchItemSubtotal;

  /// No description provided for @dispatchItemNotes.
  ///
  /// In pt, this message translates to:
  /// **'Personalizações / Observações'**
  String get dispatchItemNotes;

  /// No description provided for @dispatchAvailableStoreStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque loja: {qty}'**
  String dispatchAvailableStoreStock(int qty);

  /// No description provided for @dispatchInsufficientStoreStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque insuficiente na loja para \"{name}\". Disponível: {stock}, Solicitado: {qty}.'**
  String dispatchInsufficientStoreStock(String name, int stock, int qty);

  /// No description provided for @dispatchDuplicateBasketConsolidatedNotice.
  ///
  /// In pt, this message translates to:
  /// **'Cesta repetida: será consolidada automaticamente no despacho.'**
  String get dispatchDuplicateBasketConsolidatedNotice;

  /// No description provided for @dispatchSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Saída Física'**
  String get dispatchSubmit;

  /// No description provided for @conferenceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conferência da Saída #{number}'**
  String conferenceTitle(int number);

  /// Título genérico da tela de conferência de saída durante carregamento ou erro
  ///
  /// In pt, this message translates to:
  /// **'Conferência de Saída'**
  String get conferenceScreenTitle;

  /// No description provided for @conferenceStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Status da Saída: {status}'**
  String conferenceStatusLabel(String status);

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

  /// No description provided for @conferenceCustodyRemainingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Em Trânsito / Custódia: {qty}'**
  String conferenceCustodyRemainingLabel(int qty);

  /// No description provided for @conferenceDiscrepancyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Divergência Física: {qty} cestas'**
  String conferenceDiscrepancyLabel(int qty);

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

  /// No description provided for @conferenceFinancialTitle.
  ///
  /// In pt, this message translates to:
  /// **'Controle Financeiro de Rota e Repasses'**
  String get conferenceFinancialTitle;

  /// No description provided for @conferenceExpectedCashLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro em Mãos Esperado: {amount}'**
  String conferenceExpectedCashLabel(String amount);

  /// No description provided for @conferenceActualRepaidLabel.
  ///
  /// In pt, this message translates to:
  /// **'Repasses Realizados: {amount}'**
  String conferenceActualRepaidLabel(String amount);

  /// No description provided for @conferencePendingCashLabel.
  ///
  /// In pt, this message translates to:
  /// **'Saldo a Repassar: {amount}'**
  String conferencePendingCashLabel(String amount);

  /// No description provided for @conferenceCashSalesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vendas à Vista (Dinheiro): {amount}'**
  String conferenceCashSalesLabel(String amount);

  /// No description provided for @conferenceDirectCompanyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pix / Cartão Direto à Empresa: {amount}'**
  String conferenceDirectCompanyLabel(String amount);

  /// No description provided for @conferenceCreditSalesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vendas a Prazo (Fiado na rota): {amount}'**
  String conferenceCreditSalesLabel(String amount);

  /// No description provided for @conferenceDebtCollectedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cobrança de Fiados em Rota: {amount}'**
  String conferenceDebtCollectedLabel(String amount);

  /// No description provided for @conferenceExpensesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Despesas Autorizadas Abatidas: {amount}'**
  String conferenceExpensesLabel(String amount);

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

  /// No description provided for @conferenceActionReturn.
  ///
  /// In pt, this message translates to:
  /// **'Devolução Intacta'**
  String get conferenceActionReturn;

  /// No description provided for @conferenceActionLoss.
  ///
  /// In pt, this message translates to:
  /// **'Avaria / Perda'**
  String get conferenceActionLoss;

  /// No description provided for @conferenceActionExpense.
  ///
  /// In pt, this message translates to:
  /// **'Despesa Autorizada'**
  String get conferenceActionExpense;

  /// No description provided for @conferenceActionRepayment.
  ///
  /// In pt, this message translates to:
  /// **'Repasse de Dinheiro'**
  String get conferenceActionRepayment;

  /// No description provided for @conferenceActionSettle.
  ///
  /// In pt, this message translates to:
  /// **'Concluir Acerto / Fechamento'**
  String get conferenceActionSettle;

  /// No description provided for @conferenceActionInvestigation.
  ///
  /// In pt, this message translates to:
  /// **'Documentar Investigação'**
  String get conferenceActionInvestigation;

  /// No description provided for @conferenceSettledSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Conferência registrada com sucesso.'**
  String get conferenceSettledSuccess;

  /// No description provided for @conferenceInvestigationUpdatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Notas de investigação atualizadas com sucesso.'**
  String get conferenceInvestigationUpdatedSuccess;

  /// No description provided for @conferenceReturnsListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Devoluções de Cestas Intactas'**
  String get conferenceReturnsListTitle;

  /// No description provided for @conferenceLossesListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Avarias e Perdas Físicas'**
  String get conferenceLossesListTitle;

  /// No description provided for @conferenceExpensesListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Despesas Autorizadas'**
  String get conferenceExpensesListTitle;

  /// No description provided for @conferenceRepaymentsListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Repasses Financeiros Registrados'**
  String get conferenceRepaymentsListTitle;

  /// No description provided for @conferenceNoReturns.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma devolução intacta registrada.'**
  String get conferenceNoReturns;

  /// No description provided for @conferenceNoLosses.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma avaria ou perda registrada.'**
  String get conferenceNoLosses;

  /// No description provided for @conferenceNoExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma despesa autorizada registrada.'**
  String get conferenceNoExpenses;

  /// No description provided for @conferenceNoRepayments.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum repasse de dinheiro registrado.'**
  String get conferenceNoRepayments;

  /// No description provided for @dialogReturnTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Devolução Intacta'**
  String get dialogReturnTitle;

  /// No description provided for @dialogReturnQty.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade Devolvida'**
  String get dialogReturnQty;

  /// No description provided for @dialogReturnNotes.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get dialogReturnNotes;

  /// No description provided for @dialogLossTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Avaria ou Perda'**
  String get dialogLossTitle;

  /// No description provided for @dialogLossQty.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade Avariada/Perdida'**
  String get dialogLossQty;

  /// No description provided for @dialogLossReason.
  ///
  /// In pt, this message translates to:
  /// **'Justificativa Obrigatória da Perda'**
  String get dialogLossReason;

  /// No description provided for @dialogLossReasonRequired.
  ///
  /// In pt, this message translates to:
  /// **'A justificativa da perda é obrigatória (mínimo 3 caracteres).'**
  String get dialogLossReasonRequired;

  /// No description provided for @dialogExpenseTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Despesa Autorizada'**
  String get dialogExpenseTitle;

  /// No description provided for @dialogExpenseAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor da Despesa'**
  String get dialogExpenseAmount;

  /// No description provided for @dialogExpenseDesc.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (ex: Combustível, Borracharia)'**
  String get dialogExpenseDesc;

  /// No description provided for @dialogExpenseReceipt.
  ///
  /// In pt, this message translates to:
  /// **'Nº do Comprovante / Cupom'**
  String get dialogExpenseReceipt;

  /// No description provided for @dialogExpenseAuthorizedBy.
  ///
  /// In pt, this message translates to:
  /// **'Autorizado por'**
  String get dialogExpenseAuthorizedBy;

  /// No description provided for @dialogRepaymentTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Repasse Financeiro'**
  String get dialogRepaymentTitle;

  /// No description provided for @dialogRepaymentAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor Repassado'**
  String get dialogRepaymentAmount;

  /// No description provided for @dialogRepaymentMethod.
  ///
  /// In pt, this message translates to:
  /// **'Forma do Repasse'**
  String get dialogRepaymentMethod;

  /// No description provided for @dialogRepaymentReceivedBy.
  ///
  /// In pt, this message translates to:
  /// **'Recebido na Empresa por'**
  String get dialogRepaymentReceivedBy;

  /// No description provided for @dialogRepaymentNotes.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get dialogRepaymentNotes;

  /// No description provided for @dialogSettleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fechamento Operacional / Acerto'**
  String get dialogSettleTitle;

  /// No description provided for @dialogSettleAuditedBy.
  ///
  /// In pt, this message translates to:
  /// **'Auditor / Responsável pelo Fechamento'**
  String get dialogSettleAuditedBy;

  /// No description provided for @dialogSettleAuditedByRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome do responsável pelo fechamento.'**
  String get dialogSettleAuditedByRequired;

  /// No description provided for @dialogSettleNotes.
  ///
  /// In pt, this message translates to:
  /// **'Observações do Fechamento'**
  String get dialogSettleNotes;

  /// No description provided for @dialogSettleWarningDivergent.
  ///
  /// In pt, this message translates to:
  /// **'Atenção: Existem divergências físicas ou financeiras. O fechamento será registrado como SOB INVESTIGAÇÃO.'**
  String get dialogSettleWarningDivergent;

  /// No description provided for @dialogSettleInvestigationNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas Iniciais da Investigação'**
  String get dialogSettleInvestigationNotes;

  /// No description provided for @dialogInvestigationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Investigação de Divergências'**
  String get dialogInvestigationTitle;

  /// No description provided for @dialogInvestigationNotes.
  ///
  /// In pt, this message translates to:
  /// **'Parecer da Investigação / Justificativas'**
  String get dialogInvestigationNotes;

  /// No description provided for @dialogInvestigationMarkResolved.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como Resolvido (Divergências apuradas/justificadas)'**
  String get dialogInvestigationMarkResolved;

  /// No description provided for @dialogInvestigationSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Parecer'**
  String get dialogInvestigationSave;

  /// No description provided for @saleModeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Modalidade da Venda'**
  String get saleModeLabel;

  /// No description provided for @saleModeDirectStore.
  ///
  /// In pt, this message translates to:
  /// **'Balcão / Loja'**
  String get saleModeDirectStore;

  /// No description provided for @saleModeCommercialRoute.
  ///
  /// In pt, this message translates to:
  /// **'Rota / Venda Externa'**
  String get saleModeCommercialRoute;

  /// No description provided for @saleRouteSelectDispatch.
  ///
  /// In pt, this message translates to:
  /// **'Vincular à Saída / Rota Ativa'**
  String get saleRouteSelectDispatch;

  /// No description provided for @saleRouteNoDispatches.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma saída aberta disponível para este responsável.'**
  String get saleRouteNoDispatches;

  /// No description provided for @saleRouteResponsibleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Responsável pela Rota'**
  String get saleRouteResponsibleLabel;

  /// No description provided for @saleCustodyStockAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Saldo sob custódia: {qty}'**
  String saleCustodyStockAvailable(int qty);

  /// No description provided for @homePhase7Header.
  ///
  /// In pt, this message translates to:
  /// **'Fase 7: Gestão Financeira & Tesouraria'**
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

  /// No description provided for @moduleTreasury.
  ///
  /// In pt, this message translates to:
  /// **'Tesouraria & Livro-Caixa'**
  String get moduleTreasury;

  /// No description provided for @homeTreasuryDescription.
  ///
  /// In pt, this message translates to:
  /// **'Caixa físico, contas bancárias, transferências e conciliação'**
  String get homeTreasuryDescription;

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

  /// No description provided for @payableSelectAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta Financeira de Saída'**
  String get payableSelectAccount;

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

  /// No description provided for @treasuryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tesouraria & Conciliação'**
  String get treasuryTitle;

  /// No description provided for @treasuryTabAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Saldos & Contas'**
  String get treasuryTabAccounts;

  /// No description provided for @treasuryTabLedger.
  ///
  /// In pt, this message translates to:
  /// **'Livro-Caixa (Extrato)'**
  String get treasuryTabLedger;

  /// No description provided for @treasuryTabSummary.
  ///
  /// In pt, this message translates to:
  /// **'Visão Gerencial'**
  String get treasuryTabSummary;

  /// No description provided for @treasuryTotalAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Disponível (Caixa e Bancos)'**
  String get treasuryTotalAvailable;

  /// No description provided for @treasuryCashBalance.
  ///
  /// In pt, this message translates to:
  /// **'Caixa Físico da Loja'**
  String get treasuryCashBalance;

  /// No description provided for @treasuryBankBalance.
  ///
  /// In pt, this message translates to:
  /// **'Contas Bancárias'**
  String get treasuryBankBalance;

  /// No description provided for @treasuryRouteCashPending.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro em Rota (em trânsito)'**
  String get treasuryRouteCashPending;

  /// No description provided for @treasuryProjectedNet.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Líquido Projetado'**
  String get treasuryProjectedNet;

  /// No description provided for @treasuryOpenReceivables.
  ///
  /// In pt, this message translates to:
  /// **'A Receber (Fiados Pendentes)'**
  String get treasuryOpenReceivables;

  /// No description provided for @treasuryOverdueReceivables.
  ///
  /// In pt, this message translates to:
  /// **'A Receber Vencidos'**
  String get treasuryOverdueReceivables;

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

  /// No description provided for @treasuryBusinessExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Despesas Operacionais (Mês)'**
  String get treasuryBusinessExpenses;

  /// No description provided for @treasuryPersonalWithdrawals.
  ///
  /// In pt, this message translates to:
  /// **'Retiradas de Sócios (Mês)'**
  String get treasuryPersonalWithdrawals;

  /// No description provided for @treasuryNewAccount.
  ///
  /// In pt, this message translates to:
  /// **'Nova Conta Financeira'**
  String get treasuryNewAccount;

  /// No description provided for @treasuryEditAccount.
  ///
  /// In pt, this message translates to:
  /// **'Editar Conta Financeira'**
  String get treasuryEditAccount;

  /// No description provided for @treasuryAccountName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Conta'**
  String get treasuryAccountName;

  /// No description provided for @treasuryAccountType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Conta'**
  String get treasuryAccountType;

  /// No description provided for @treasuryTypeCash.
  ///
  /// In pt, this message translates to:
  /// **'Caixa Físico'**
  String get treasuryTypeCash;

  /// No description provided for @treasuryTypeBank.
  ///
  /// In pt, this message translates to:
  /// **'Conta Bancária'**
  String get treasuryTypeBank;

  /// No description provided for @treasuryTypeOther.
  ///
  /// In pt, this message translates to:
  /// **'Outra Conta / Cofre'**
  String get treasuryTypeOther;

  /// No description provided for @treasuryBankName.
  ///
  /// In pt, this message translates to:
  /// **'Instituição Financeira / Banco'**
  String get treasuryBankName;

  /// No description provided for @treasuryAccountNumber.
  ///
  /// In pt, this message translates to:
  /// **'Agência e Conta'**
  String get treasuryAccountNumber;

  /// No description provided for @treasuryInitialBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Inicial de Abertura'**
  String get treasuryInitialBalance;

  /// No description provided for @treasuryIsDefault.
  ///
  /// In pt, this message translates to:
  /// **'Conta Padrão'**
  String get treasuryIsDefault;

  /// No description provided for @treasuryTransferTitle.
  ///
  /// In pt, this message translates to:
  /// **'Transferência entre Contas'**
  String get treasuryTransferTitle;

  /// No description provided for @treasurySourceAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta de Origem (Saída)'**
  String get treasurySourceAccount;

  /// No description provided for @treasuryDestinationAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta de Destino (Entrada)'**
  String get treasuryDestinationAccount;

  /// No description provided for @treasuryTransferAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor da Transferência'**
  String get treasuryTransferAmount;

  /// No description provided for @treasuryTransferSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Transferência realizada com sucesso'**
  String get treasuryTransferSuccess;

  /// No description provided for @treasuryManualEntryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lançamento no Livro-Caixa'**
  String get treasuryManualEntryTitle;

  /// No description provided for @treasuryEntryType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Lançamento'**
  String get treasuryEntryType;

  /// No description provided for @treasuryEntryCredit.
  ///
  /// In pt, this message translates to:
  /// **'Crédito (Entrada)'**
  String get treasuryEntryCredit;

  /// No description provided for @treasuryEntryDebit.
  ///
  /// In pt, this message translates to:
  /// **'Débito (Saída)'**
  String get treasuryEntryDebit;

  /// No description provided for @treasuryEntryCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get treasuryEntryCategory;

  /// No description provided for @treasuryEntryDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição do Lançamento'**
  String get treasuryEntryDescription;

  /// No description provided for @treasuryEntryAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get treasuryEntryAmount;

  /// No description provided for @treasuryEntrySuccess.
  ///
  /// In pt, this message translates to:
  /// **'Lançamento registrado com sucesso'**
  String get treasuryEntrySuccess;

  /// No description provided for @treasuryNoEntries.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma movimentação registrada no livro-caixa.'**
  String get treasuryNoEntries;

  /// No description provided for @treasuryNoAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta financeira cadastrada.'**
  String get treasuryNoAccounts;

  /// No description provided for @treasuryReversalBadge.
  ///
  /// In pt, this message translates to:
  /// **'ESTORNO'**
  String get treasuryReversalBadge;

  /// No description provided for @treasuryImmutableNote.
  ///
  /// In pt, this message translates to:
  /// **'Livro-Caixa imutável: todas as operações são estritamente append-only.'**
  String get treasuryImmutableNote;

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
  /// **'Visão consolidada operacional, faturamento e livro-caixa'**
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

  /// No description provided for @dashboardSectionFinancial.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro & Tesouraria'**
  String get dashboardSectionFinancial;

  /// No description provided for @dashboardOpenReceivables.
  ///
  /// In pt, this message translates to:
  /// **'A Receber (Em Aberto)'**
  String get dashboardOpenReceivables;

  /// No description provided for @dashboardOverdueReceivables.
  ///
  /// In pt, this message translates to:
  /// **'A Receber Vencidos'**
  String get dashboardOverdueReceivables;

  /// No description provided for @dashboardEffectiveReceived.
  ///
  /// In pt, this message translates to:
  /// **'Recebimentos Efetivos'**
  String get dashboardEffectiveReceived;

  /// No description provided for @dashboardOpenPayables.
  ///
  /// In pt, this message translates to:
  /// **'A Pagar (Em Aberto)'**
  String get dashboardOpenPayables;

  /// No description provided for @dashboardOverduePayables.
  ///
  /// In pt, this message translates to:
  /// **'A Pagar Vencidos'**
  String get dashboardOverduePayables;

  /// No description provided for @dashboardEffectivePaid.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos Efetuados'**
  String get dashboardEffectivePaid;

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

  /// No description provided for @dashboardProjectedCash.
  ///
  /// In pt, this message translates to:
  /// **'Saldo de Caixa Projetado'**
  String get dashboardProjectedCash;

  /// No description provided for @dashboardProjectionNotice.
  ///
  /// In pt, this message translates to:
  /// **'Atenção: Valores projetados são estimativas futuras e NÃO constituem dinheiro disponível em caixa.'**
  String get dashboardProjectionNotice;

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

  /// Forma de repasse: Dinheiro em Mãos
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro em Mãos'**
  String get conferenceMethodCashHand;

  /// Forma de repasse: PIX Repassado
  ///
  /// In pt, this message translates to:
  /// **'PIX Repassado'**
  String get conferenceMethodPixSettled;

  /// Forma de repasse: Transferência Bancária
  ///
  /// In pt, this message translates to:
  /// **'Transferência Bancária'**
  String get conferenceMethodBankTransfer;

  /// Prefixo de observações completas
  ///
  /// In pt, this message translates to:
  /// **'Observações: {notes}'**
  String commonObservationsPrefix(String notes);

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

  /// Alerta de contas insuficientes para transferência
  ///
  /// In pt, this message translates to:
  /// **'São necessárias ao menos 2 contas para realizar transferências.'**
  String get treasuryNeedTwoAccountsForTransfer;

  /// Rótulo do seletor de conta financeira
  ///
  /// In pt, this message translates to:
  /// **'Conta Financeira'**
  String get treasuryAccountLabel;

  /// Filtro de conta
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get treasuryAccountFilterLabel;

  /// Botão de novo lançamento na tesouraria
  ///
  /// In pt, this message translates to:
  /// **'Lançamento'**
  String get treasuryLaunchEntry;

  /// Título do quadro consolidado da tesouraria
  ///
  /// In pt, this message translates to:
  /// **'Posição Consolidada da Empresa'**
  String get treasuryConsolidatedPosition;

  /// Saldo em espécie/caixa físico
  ///
  /// In pt, this message translates to:
  /// **'Caixa Físico: {amount}'**
  String treasuryCashPhysicalLabel(String amount);

  /// Saldo em contas bancárias
  ///
  /// In pt, this message translates to:
  /// **'Bancos: {amount}'**
  String treasuryBankLabel(String amount);

  /// Legenda explicativa do cálculo de previsão
  ///
  /// In pt, this message translates to:
  /// **'Fórmula: Disponível + A Receber - A Pagar'**
  String get treasuryFormulaExplanation;

  /// Título do quadro de compromissos futuros
  ///
  /// In pt, this message translates to:
  /// **'Compromissos Futuros & Fiados'**
  String get treasuryFutureCommitmentsTitle;

  /// Subtítulo de valores em custódia externa
  ///
  /// In pt, this message translates to:
  /// **'Em custódia de entregadores'**
  String get treasuryCustodyCouriers;

  /// Título do quadro de segregação de despesas
  ///
  /// In pt, this message translates to:
  /// **'Segregação de Despesas (Mês)'**
  String get treasuryExpenseSegregationTitle;

  /// Descrição de despesas empresariais
  ///
  /// In pt, this message translates to:
  /// **'Gastos operacionais da atividade'**
  String get treasuryBusinessExpensesDesc;

  /// Descrição de retiradas de sócios
  ///
  /// In pt, this message translates to:
  /// **'Não misturar com contas da empresa'**
  String get treasuryPersonalWithdrawalsDesc;

  /// Categoria: Aporte de Capital
  ///
  /// In pt, this message translates to:
  /// **'Aporte de Capital'**
  String get treasuryCatCapitalContribution;

  /// Categoria: Receita de Vendas
  ///
  /// In pt, this message translates to:
  /// **'Receita de Vendas'**
  String get treasuryCatSalesRevenue;

  /// Categoria: Recebimento de Cliente
  ///
  /// In pt, this message translates to:
  /// **'Recebimento de Cliente'**
  String get treasuryCatCustomerReceipt;

  /// Categoria: Outros Créditos
  ///
  /// In pt, this message translates to:
  /// **'Outros Créditos'**
  String get treasuryCatOtherCredits;

  /// Categoria: Retirada de Sócios / Pró-labore
  ///
  /// In pt, this message translates to:
  /// **'Retirada de Sócios / Pró-labore'**
  String get treasuryCatPartnerWithdrawal;

  /// Categoria: Pagamento Fornecedor
  ///
  /// In pt, this message translates to:
  /// **'Pagamento Fornecedor'**
  String get treasuryCatSupplierPayment;

  /// Categoria: Energia Elétrica
  ///
  /// In pt, this message translates to:
  /// **'Energia Elétrica'**
  String get treasuryCatElectricity;

  /// Categoria: Aluguel
  ///
  /// In pt, this message translates to:
  /// **'Aluguel'**
  String get treasuryCatRent;

  /// Categoria: Frete / Combustível
  ///
  /// In pt, this message translates to:
  /// **'Frete / Combustível'**
  String get treasuryCatFreightFuel;

  /// Categoria: Manutenção
  ///
  /// In pt, this message translates to:
  /// **'Manutenção'**
  String get treasuryCatMaintenance;

  /// Categoria: Outras Despesas
  ///
  /// In pt, this message translates to:
  /// **'Outras Despesas'**
  String get treasuryCatOtherExpenses;

  /// Método de pagamento: PIX
  ///
  /// In pt, this message translates to:
  /// **'PIX'**
  String get treasuryMethodPix;

  /// Método de pagamento: Dinheiro
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro'**
  String get treasuryMethodCash;

  /// Método de pagamento: Transferência
  ///
  /// In pt, this message translates to:
  /// **'Transferência'**
  String get treasuryMethodTransfer;

  /// Método de pagamento: Cartão
  ///
  /// In pt, this message translates to:
  /// **'Cartão'**
  String get treasuryMethodCard;

  /// Método de pagamento: Outro
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get treasuryMethodOther;

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
  /// **'Imprimir / Selecionar Impressora (Epson Wi-Fi)'**
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

  /// Dica de preenchimento para observações de saída física
  ///
  /// In pt, this message translates to:
  /// **'Observações da saída física (opcional)'**
  String get dispatchPhysicalNotesHint;

  /// Dica de personalização de cesta na saída
  ///
  /// In pt, this message translates to:
  /// **'Ex: Cesta personalizada, lote específico'**
  String get dispatchCustomizationHint;

  /// Dica de justificativa para avaria ou perda na conferência
  ///
  /// In pt, this message translates to:
  /// **'Ex: Caixa molhou na chuva durante entrega'**
  String get conferenceLossReasonHint;

  /// Dica do conferente que recebeu o repasse
  ///
  /// In pt, this message translates to:
  /// **'Colaborador que conferiu e recebeu'**
  String get conferenceReceivedByHint;

  /// Dica do nome do auditor na finalização do acerto
  ///
  /// In pt, this message translates to:
  /// **'Nome do conferente / auditor'**
  String get conferenceAuditorNameHint;

  /// Dica para justificativa inicial de pendências
  ///
  /// In pt, this message translates to:
  /// **'Justificativa inicial das divergências'**
  String get conferenceInitialJustificationHint;

  /// Dica para investigação de divergência
  ///
  /// In pt, this message translates to:
  /// **'Descreva a apuração, se foi justificado, perdas aceitas ou ressarcimento'**
  String get conferenceInvestigationHint;

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

  /// No description provided for @purchasePaymentFinancialAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta Financeira de Liquidação'**
  String get purchasePaymentFinancialAccountLabel;

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
      'that was used.');
}
