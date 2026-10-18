import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/services/app_appearance_controller.dart';
import 'package:zm_cesta_basica_client/views/app_appearance_view.dart';
import 'package:zm_cesta_basica_client/widgets/shared/approved_app_style.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('appearance persists ordered device preferences', () async {
    final c = AppAppearanceController();
    await Future.wait([
      c.save(theme: ThemeMode.dark),
      c.save(color: Colors.deepPurple),
      c.save(pure: true),
    ]);
    final restored = AppAppearanceController();
    await restored.load();
    expect(restored.mode, ThemeMode.dark);
    expect(restored.accent.toARGB32(), Colors.deepPurple.toARGB32());
    expect(restored.pureBackground, isTrue);
    expect((await SharedPreferences.getInstance()).getKeys(), {
      AppAppearanceController.storageKey,
    });
    c.dispose();
    restored.dispose();
  });
  test('invalid preferences preserve approved defaults', () async {
    SharedPreferences.setMockInitialValues({
      AppAppearanceController.storageKey: 'invalid',
    });
    final c = AppAppearanceController();
    await c.load();
    expect(c.mode, ThemeMode.system);
    expect(c.accent, const Color(0xff2866ae));
    expect(c.pureBackground, isFalse);
    c.dispose();
  });
  test('custom accents keep text and action contrast in both appearances', () {
    for (final dark in [false, true]) {
      for (final pure in [false, true]) {
        for (final color in [
          Colors.yellow,
          Colors.pink,
          Colors.deepPurple,
          Colors.white,
          Colors.black,
          Colors.green,
        ]) {
          final p = AppPalette(dark, pure: pure, originalAccent: color);
          for (final bg in [p.surface, p.page, p.soft]) {
            expect(
              AppPalette.contrast(p.accent, bg),
              greaterThanOrEqualTo(4.5),
            );
          }
          expect(
            AppPalette.contrast(p.accent, p.accentInk),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    }
  });
  testWidgets('appearance controls remain usable with enlarged text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = AppAppearanceController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        theme: approvedAppTheme(Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: AppAppearanceView(controller: c),
      ),
    );
    await tester.pumpAndSettle();
    final dropdown = find.byType(DropdownButtonFormField<ThemeMode>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escuro').last);
    await tester.pumpAndSettle();
    expect(c.mode, ThemeMode.dark);
    await tester.ensureVisible(find.text('Escolher cor'));
    await tester.tap(find.text('Escolher cor'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNWidgets(3));
    await tester.tap(find.text('Confirmar').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
