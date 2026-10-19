import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zm_design_system_lab/zm_payment_contract.dart';

void main() {
  testWidgets('FE-052 choice is one 60px capsule, not two ChoiceChips', (tester) async {
    var partial = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (context, setState) => Center(child: SizedBox(width: 332,
        child: ZmFullPartialSelector(
          partial: partial,
          onChanged: (value) => setState(() => partial = value),
        ))),
    ))));
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(tester.getSize(find.byType(ZmFullPartialSelector)).height, 60);
    await tester.tap(find.text('Parcial'));
    await tester.pumpAndSettle();
    expect(partial, isTrue);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  });

  testWidgets('FE-052 date field uses trailing calendar and 56px height', (tester) async {
    final day = DateTime(2026, 10, 16);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      Center(child: SizedBox(width: 332, child: ZmPaymentDateField(
        label: 'Data do pagamento', value: day, onChanged: (_) {},
      ))))));
    expect(tester.getSize(find.byType(ZmPaymentDateField)).height, 56);
    final text = tester.getTopLeft(find.text('16/10/2026'));
    final icon = tester.getTopLeft(find.byIcon(Icons.calendar_month_outlined));
    expect(icon.dx, greaterThan(text.dx));
  });

  testWidgets('date field opens calendar without persisting a payment', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ZmPaymentDateField(
      label: 'Data', value: DateTime(2026, 10, 16), onChanged: (_) {},
    ))));
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
