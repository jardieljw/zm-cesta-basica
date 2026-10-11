import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt', 'BR'),
    Locale('pt'),
  ];

  String get appTitle;
  String get homeHeaderTitle;

  String get commonSave;
  String get commonCancel;
  String get commonConfirm;
  String get commonDelete;
  String get commonEdit;
  String get commonClose;
  String get commonBack;
  String get commonSearch;
  String get commonFilter;
  String get commonClear;
  String get commonLoading;
  String get commonRefresh;
  String get commonStatus;
  String get commonActions;
  String get commonNotes;
  String get commonOptional;
  String get commonRequired;
  String get commonYes;
  String get commonNo;
  String get commonSuccess;
  String get commonError;
  String get commonWarning;
  String get commonUnit;

  String get statusOnline;
  String get statusOffline;
  String get statusPaired;
  String get statusUnpaired;
  String get serverUrlLabel;
  String get fingerprintLabel;

  String get moduleProducts;
  String get moduleBasketTypes;
  String get modulePurchases;
  String get moduleProduction;
  String get moduleAssembly;
  String get moduleInventorySummary;
  String get moduleInventoryMovements;
  String get moduleSettings;
  String get modulePairing;

  String get productsTitle;
  String get productNew;
  String get productEdit;
  String get productName;
  String get productCategory;
  String get productBaseUnit;
  String get productCostPrice;
  String get productMinStock;
  String get productActive;
  String get productInactive;
  String get productPackagings;

  String get packagingNew;
  String get packagingName;
  String get packagingBarcode;
  String get packagingMultiplier;
  String get packagingUnit;

  String get basketTypesTitle;
  String get basketTypeNew;
  String get basketTypeEdit;
  String get basketTypeCode;
  String get basketTypeName;
  String get basketTypeAllowsCustom;
  String get recipesTitle;
  String get recipeVersionLabel;
  String get recipeAddIngredient;
  String get recipeQuantityPerBasket;
  String get recipeSection;

  String get purchasesTitle;
  String get purchaseNew;
  String get purchaseInvoiceNumber;
  String get purchaseSupplier;
  String get purchaseDate;
  String get purchaseItems;
  String get purchasePackagesCount;
  String get purchaseUnitCost;
  String get purchaseTotalCost;

  String get productionBatchesTitle;
  String get productionBatchNew;
  String productionBatchNumber(int number);
  String get productionQuantityProduced;
  String get productionQuantityDisassembled;
  String get productionCurrentStock;
  String get productionUnitCost;
  String get productionTotalCost;
  String get productionStatusConfirmed;
  String get productionStatusDisassembled;
  String get productionStatusCanceled;
  String get productionDirectSale;
  String get productionCustom;
  String productionDisassembleTitle(int number);
  String get productionDisassembleConfirm;
  String get productionDisassembleQtyLabel;
  String get productionDisassembleReasonLabel;
  String get productionDisassembleReasonHint;
  String get productionDisassembleTriageTitle;
  String get productionDisassembleAllIntact;
  String productionIntactQtyLabel(String unit);
  String productionLossQtyLabel(String unit);
  String get productionLossReasonLabel;
  String get productionDisassembleDescription;
  String get productionDisassembledSuccess;
  String get productionBatchSearchHint;
  String get productionBatchFilterAllStatus;
  String get productionBatchFilterConfirmed;
  String get productionBatchFilterDisassembled;
  String get productionBatchFilterAllTypes;
  String get productionBatchFilterStandard;
  String get productionBatchFilterCustom;
  String get productionBatchEmpty;
  String get productionBatchMountFirst;
  String productionBatchCancelTitle(int number);
  String get productionBatchCancelDescription;
  String get productionBatchCancelReasonLabel;
  String get productionBatchCancelReasonHint;
  String get productionBatchCancelConfirm;
  String get productionBatchCancelSuccess;
  String get productionBatchSnapshotTitle;
  String productionBatchSectionLabel(String section, String cost);
  String productionBatchTotalItemCost(String cost);
  String get productionBatchDisassembleButton;
  String get productionBatchCancelButton;
  String get productionBatchDetailProduced;
  String get productionBatchDetailStock;
  String get productionBatchDetailDisassembled;
  String get productionBatchDetailUnitCost;
  String get productionBatchDetailTotalCost;
  String productionBatchDetailDate(String date);
  String productionBatchDetailNotes(String notes);
  String productionBatchDetailDisassembledAt(String date, String reason);
  String productionBatchDescriptionLabel(String description);
  String productionBatchConsumedTotal(String quantity);

  String get validationInvalid;
  String validationMinChars(int min);
  String get validationMustBePositive;
  String validationInsufficientStockForDisassembly(int max);
  String get commonTryAgain;

  String get homePhase2Header;
  String get homeProductsDescription;
  String get homeBasketTypesDescription;
  String get homePhase3Header;
  String get homePurchasesDescription;
  String get homeInventorySummaryDescription;
  String get homeInventoryMovementsDescription;
  String get homePhase4Header;
  String get homeProductionBatchesDescription;
  String get homeProductionAssemblyDescription;
  String get homeServerStatusTitle;
  String get homeCentralServer;
  String get homeCheckConnection;
  String get homePairDevice;

  String get inventorySummaryTitle;
  String get inventoryMovementsTitle;
  String get stockAdjustmentsTitle;
  String get stockAdjustmentNew;
  String get stockAdjustmentTypeIn;
  String get stockAdjustmentTypeOut;
  String get stockAdjustmentReasonLabel;

  String get settingsTitle;
  String get pairingTitle;
  String get pairingPinLabel;
  String get pairingScanQr;
  String get pairingDeviceName;

  String get errorInsufficientStock;
  String get errorIdempotencyMismatch;
  String get errorRequestInProgress;
  String get errorUnauthorized;
  String get errorDeviceRevoked;
  String get errorForbidden;
  String get errorNotFound;
  String get errorConflict;
  String get errorValidationError;
  String get errorServer;
  String get errorConnectionFailed;
  String get errorUnexpected;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Support both 'pt' and 'pt_BR'
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  return AppLocalizationsPt();
}
