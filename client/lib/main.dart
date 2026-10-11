import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'utils/formatters.dart';
import 'views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppFormatters.initialize();
  runApp(const ZmCestaBasicaApp());
}

class ZmCestaBasicaApp extends StatelessWidget {
  const ZmCestaBasicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZM Cesta Básica',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'BR'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const HomeView(),
    );
  }
}
