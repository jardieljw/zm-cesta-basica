import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_cesta_basica_client/utils/scroll_layout.dart';

void main() {
  for (final scenario in [
    (
      name: 'mobile',
      size: const Size(360, 740),
      scale: 1.0,
      safe: 24.0,
      keyboard: 0.0,
      tall: false
    ),
    (
      name: 'desktop',
      size: const Size(1280, 800),
      scale: 1.0,
      safe: 0.0,
      keyboard: 0.0,
      tall: false
    ),
    (
      name: 'large text',
      size: const Size(360, 800),
      scale: 1.6,
      safe: 34.0,
      keyboard: 0.0,
      tall: false
    ),
    (
      name: 'keyboard',
      size: const Size(360, 900),
      scale: 1.0,
      safe: 0.0,
      keyboard: 280.0,
      tall: false
    ),
    (
      name: 'taller action',
      size: const Size(360, 800),
      scale: 1.0,
      safe: 24.0,
      keyboard: 0.0,
      tall: true
    ),
  ]) {
    testWidgets(
        'last item and action remain separately reachable: ${scenario.name}',
        (tester) async {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var actionTaps = 0;
      int? itemTapped;
      final action = FloatingActionButton.extended(
        key: const ValueKey('action'),
        onPressed: () => actionTaps++,
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      );
      await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
                data: MediaQueryData(
                    size: scenario.size,
                    padding: EdgeInsets.only(bottom: scenario.safe),
                    viewPadding: EdgeInsets.only(bottom: scenario.safe),
                    viewInsets: EdgeInsets.only(bottom: scenario.keyboard),
                    textScaler: TextScaler.linear(scenario.scale)),
                child: child!,
              ),
          theme: ThemeData(
              useMaterial3: true,
              floatingActionButtonTheme: scenario.tall
                  ? const FloatingActionButtonThemeData(
                      extendedSizeConstraints:
                          BoxConstraints.tightFor(height: 96))
                  : const FloatingActionButtonThemeData()),
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Lista')),
              floatingActionButton: action,
              body: ListView.builder(
                key: const ValueKey('items'),
                padding: fabScrollPadding(context),
                itemExtent: 96,
                itemCount: 15,
                itemBuilder: (_, index) => Card(
                    child: Row(children: [
                  Expanded(child: Text('Item $index')),
                  IconButton(
                      key: ValueKey('item-$index'),
                      onPressed: () => itemTapped = index,
                      icon: const Icon(Icons.edit)),
                ])),
              ),
            ),
          )));
      await tester.pumpAndSettle();
      final list = find.byKey(const ValueKey('items'));
      final button = find.byKey(const ValueKey('action'));
      final viewport = tester.getRect(list);
      final actionRect = tester.getRect(button);
      expect(viewport.bottom, greaterThan(actionRect.bottom));
      expect(viewport.overlaps(actionRect), isTrue);
      expect(
          actionRect.bottom,
          lessThanOrEqualTo(
              scenario.size.height - scenario.keyboard - scenario.safe));
      if (scenario.tall) expect(actionRect.height, 96);

      await tester.drag(list, const Offset(0, -2400));
      await tester.pumpAndSettle();
      final lastItem = find.byKey(const ValueKey('item-14'));
      expect(
          tester.getRect(lastItem).bottom, lessThanOrEqualTo(viewport.bottom));
      expect(tester.getRect(lastItem).overlaps(actionRect), isFalse);
      await tester.tap(lastItem);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(itemTapped, 14);
      expect(actionTaps, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
