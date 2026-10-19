import 'package:flutter/material.dart';

/// FE-052 reference extraction: mobile 430 px preview, DPR=1.
/// These constants are an audited HTML reference, NOT a Flutter golden.
abstract final class ZmPaymentMetrics {
  static const panelRadius = 32.0;
  static const fieldRadius = 24.0;
  static const selectorHeight = 60.0;
  static const selectorOptionHeight = 48.0;
  static const fieldHeight = 56.0;
  static const reviewButtonHeight = 52.0;
  static const Color primary = Color(0xFF2866AE);
  static const Color selectorBackground = Color(0xFFF6F7F9);
  static const Color selectedOptionBackground = Color(0xFFEDF4FD);
  static const Color fieldBackground = Color(0xFFF9FBFF);
}

/// A single, unified capsule with visible circular selection markers.
/// Replaces the audited incorrect choice of two independent ChoiceChips.
class ZmFullPartialSelector extends StatelessWidget {
  const ZmFullPartialSelector({
    super.key,
    required this.partial,
    required this.onChanged,
  });

  final bool partial;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ZmPaymentMetrics.selectorHeight,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: ZmPaymentMetrics.selectorBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE0E4EB)),
      ),
      child: Row(
        children: [
          Expanded(child: _option(context, 'Integral', !partial, false)),
          Expanded(child: _option(context, 'Parcial', partial, true)),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, String label, bool selected, bool value) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? ZmPaymentMetrics.selectedOptionBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(value),
          child: SizedBox(
            height: ZmPaymentMetrics.selectorOptionHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 17,
                  color: selected ? ZmPaymentMetrics.primary : const Color(0xFF7D8796),
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: selected ? ZmPaymentMetrics.primary : const Color(0xFF222730)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Date picker entry with trailing calendar, unlike the discarded leading-icon candidate.
/// Locale/long date formatting still requires approval and localization integration.
class ZmPaymentDateField extends StatelessWidget {
  const ZmPaymentDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final shown = value == null
      ? label
      : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: ZmPaymentMetrics.fieldBackground,
        borderRadius: BorderRadius.circular(ZmPaymentMetrics.fieldRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(ZmPaymentMetrics.fieldRadius),
          onTap: () async {
            final now = DateTime.now();
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) onChanged(date);
          },
          child: Container(
            height: ZmPaymentMetrics.fieldHeight,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF7D8796)),
              borderRadius: BorderRadius.circular(ZmPaymentMetrics.fieldRadius),
            ),
            child: Row(
              children: [
                Expanded(child: Text(shown, maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 10),
                const Icon(Icons.calendar_month_outlined, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
