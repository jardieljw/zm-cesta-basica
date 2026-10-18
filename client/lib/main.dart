import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'utils/formatters.dart';
import 'views/home_view.dart';
import 'widgets/shared/approved_app_style.dart';
import 'services/app_appearance_controller.dart';
import 'package:flutter/foundation.dart';
import 'widgets/shared/approved_icon_license.dart';

Future<void> _loadWindowsReferenceFonts() async {
  if (kIsWeb || !Platform.isWindows) return;
  const fonts = {
    'Segoe UI': 'C:/Windows/Fonts/segoeui.ttf',
    'Segoe UI Semibold': 'C:/Windows/Fonts/seguisb.ttf',
  };
  for (final entry in fonts.entries) {
    try {
      final file = File(entry.value);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final loader = FontLoader(entry.key)
          ..addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
      }
    } catch (_) {}
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadWindowsReferenceFonts();
  await AppFormatters.initialize();
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks([
      'Lucide / Feather',
    ], approvedIconLicense);
  });
  runApp(const ZmCestaBasicaApp());
}

class ZmCestaBasicaApp extends StatefulWidget {
  const ZmCestaBasicaApp({super.key});

  @override
  State<ZmCestaBasicaApp> createState() => _ZmCestaBasicaAppState();
}

class _ZmCestaBasicaAppState extends State<ZmCestaBasicaApp> {
  final appearance = AppAppearanceController();
  @override
  void initState() {
    super.initState();
    appearance.load();
  }

  @override
  void dispose() {
    appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppAppearanceScope(
    controller: appearance,
    child: ListenableBuilder(
      listenable: appearance,
      builder: (context, _) => MaterialApp(
        title: 'ZM Cesta Básica',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('pt', 'BR'), Locale('pt')],
        locale: const Locale('pt', 'BR'),
        theme: approvedAppTheme(
          Brightness.light,
          accent: appearance.accent,
          pure: appearance.pureBackground,
          solid: appearance.material == AppMaterialMode.solid,
          reducedMotion: appearance.motion == AppMotionMode.reduced,
        ),
        darkTheme: approvedAppTheme(
          Brightness.dark,
          accent: appearance.accent,
          pure: appearance.pureBackground,
          solid: appearance.material == AppMaterialMode.solid,
          reducedMotion: appearance.motion == AppMotionMode.reduced,
        ),
        themeMode: appearance.mode,
        home: const HomeView(),
      ),
    ),
  );
}
