import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      // Safe fallback for testing or non-localized contexts
      return lookupAppLocalizations(const Locale('pt', 'BR'));
    }
    return localizations;
  }
}
