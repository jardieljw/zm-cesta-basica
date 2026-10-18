import 'package:flutter/material.dart';
import '../../l10n/l10n_extension.dart';
import '../../services/app_overview_controller.dart';
import 'approved_app_style.dart';

class AppPeriodSelector extends StatelessWidget {
  final OverviewPeriod value;
  final ValueChanged<OverviewPeriod> onChanged;
  const AppPeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final l = context.l10n, p = AppPalette.of(context);
    final labels = [l.appDay, l.appWeek, l.appMonth];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: p.solid
            ? const []
            : [
                BoxShadow(
                  color: p.shadow,
                  offset: const Offset(0, 2),
                  blurRadius: 10,
                ),
              ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final item in OverviewPeriod.values)
              Expanded(
                child: Semantics(
                  selected: value == item,
                  child: TextButton(
                    key: ValueKey('period-${item.name}'),
                    onPressed: () => onChanged(item),
                    style: TextButton.styleFrom(
                      textStyle: value == item
                          ? Theme.of(context).textTheme.titleSmall
                          : Theme.of(context).textTheme.bodyMedium,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.standard,
                      foregroundColor: value == item ? p.accent : p.ink,
                      backgroundColor: value == item
                          ? p.soft
                          : Colors.transparent,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(labels[item.index]),
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}

class AppTwoColumns extends StatelessWidget {
  final List<Widget> children;
  final double gap, minimum;
  const AppTwoColumns({
    super.key,
    required this.children,
    this.gap = 12,
    this.minimum = 120,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - gap) / 2;
      final fits =
          width >= minimum * MediaQuery.textScalerOf(context).scale(15) / 15;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children)
            SizedBox(width: fits ? width : constraints.maxWidth, child: child),
        ],
      );
    },
  );
}
