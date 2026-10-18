import 'package:flutter/material.dart';
import 'approved_app_style.dart';

/// Compatibility adapters for the financial journeys; the approved app owns
/// the actual tokens, backdrop and material so no second design is maintained.
class FinancialJourneyTheme extends StatelessWidget {
  final Widget child;
  const FinancialJourneyTheme({super.key, required this.child});
  @override
  Widget build(BuildContext context) =>
      Theme.of(context).extension<ApprovedAppearance>() != null
      ? child
      : Theme(
          data: approvedAppTheme(
            Theme.of(context).brightness,
          ).copyWith(platform: Theme.of(context).platform),
          child: child,
        );
}

class FinancialSurface extends StatelessWidget {
  final Widget child;
  const FinancialSurface({super.key, required this.child});
  @override
  Widget build(BuildContext context) => ApprovedSurface(child: child);
}

class FinancialBackdrop extends StatelessWidget {
  final Widget child;
  const FinancialBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) => ApprovedBackdrop(child: child);
}
