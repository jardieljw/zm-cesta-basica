import 'package:flutter/material.dart';
import '../../utils/formatters.dart';
import '../../utils/adaptive_ui_color.dart';

/// Displays already calculated values; it does not contain financial rules.
class FinancialSummaryMetric {
  final String label;
  final int cents;
  final Color color;
  const FinancialSummaryMetric(this.label, this.cents, this.color);
}

class FinancialSummaryPanel extends StatelessWidget {
  final String caption;
  final List<FinancialSummaryMetric> metrics;
  const FinancialSummaryPanel({
    super.key,
    required this.caption,
    required this.metrics,
  });
  Widget _metric(
    BuildContext context,
    FinancialSummaryMetric metric,
    bool primary,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(metric.label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      Text(
        AppFormatters.formatCurrency(metric.cents),
        style: TextStyle(
          fontSize: primary ? 24 : 18,
          fontWeight: FontWeight.bold,
          color: adaptiveUiText(context, metric.color),
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 620 &&
              MediaQuery.textScalerOf(context).scale(16) <= 24;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(caption, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < metrics.length; i++)
                      Expanded(child: _metric(context, metrics[i], i == 0)),
                  ],
                )
              else if (metrics.isNotEmpty) ...[
                _metric(context, metrics.first, true),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 32,
                  runSpacing: 12,
                  children: [
                    for (final metric in metrics.skip(1))
                      _metric(context, metric, false),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}
