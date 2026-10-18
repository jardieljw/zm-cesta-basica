import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zm_cesta_basica_client/l10n/app_localizations.dart';
import 'package:zm_cesta_basica_client/utils/formatters.dart';
import 'package:zm_cesta_basica_client/views/home_view.dart';
import 'package:zm_cesta_basica_client/widgets/shared/approved_app_style.dart';
import 'package:zm_cesta_basica_client/widgets/shared/uniform_navigation_grid.dart';
import 'helpers/approved_overview_fake.dart';

void checkNavigation(WidgetTester tester, double width) {
  final horizontal = width <= 550;
  final first = tester.getRect(find.byKey(const ValueKey('area-0')));
  for (var i = 0; i < 5; i++) {
    final item = find.byKey(ValueKey('area-$i'));
    expect(item.hitTestable(), findsOneWidget);
    final bounds = tester.getRect(item);
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(width));
    expect(bounds.height, greaterThanOrEqualTo(48));
    expect(
      horizontal ? bounds.top : bounds.left,
      horizontal ? first.top : first.left,
    );
    for (final text
        in find
            .descendant(of: item, matching: find.byType(RichText))
            .evaluate()) {
      expect(
        (text.renderObject! as RenderParagraph).didExceedMaxLines,
        isFalse,
      );
    }
  }
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(AppFormatters.initialize);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 360.0, 390.0, 412.0, 600.0, 1200.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      testWidgets(
        'five approved destinations stay reachable at $width / $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            MaterialApp(
              theme: approvedAppTheme(Brightness.light),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('pt', 'BR'),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  boldText: scale == 1.6,
                ),
                child: child!,
              ),
              home: HomeView(apiClient: ApprovedOverviewApi()),
            ),
          );
          await tester.pumpAndSettle();
          checkNavigation(tester, width);
          for (var i = 1; i < 5; i++) {
            await tester.tap(find.byKey(ValueKey('area-$i')));
            await tester.pumpAndSettle();
            checkNavigation(tester, width);
          }
        },
      );
    }
  }
  testWidgets('navigation changes between sidebar and footer after resizing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: approvedAppTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt', 'BR'),
        home: HomeView(apiClient: ApprovedOverviewApi()),
      ),
    );
    await tester.pumpAndSettle();
    for (final width in [1200.0, 390.0, 320.0, 900.0]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpAndSettle();
      checkNavigation(tester, width);
    }
  });

  testWidgets('uniform cards retain their individual actions', (tester) async {
    var selected = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UniformNavigationGrid(
              sections: [
                NavigationCardSection(
                  title: 'Section',
                  items: [
                    NavigationCardItem(
                      title: 'First',
                      description: 'Short',
                      icon: Icons.inventory,
                      color: Colors.blue,
                      onTap: () => selected = 'first',
                    ),
                    NavigationCardItem(
                      title: 'Second',
                      description: 'Longer description',
                      icon: Icons.print,
                      color: Colors.orange,
                      onTap: () => selected = 'second',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Second'));
    expect(selected, 'second');
    await tester.tap(find.text('First'));
    expect(selected, 'first');
  });
}
