import 'package:flutter/material.dart';

/// Keeps every filter accessible when the available width changes.
class ResponsiveFilterBar extends StatelessWidget {
  final List<Widget> children;
  final WrapAlignment alignment;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final double runSpacing;

  const ResponsiveFilterBar({
    super.key,
    required this.children,
    this.alignment = WrapAlignment.start,
    this.padding = EdgeInsets.zero,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            alignment: alignment,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        ),
      );
}
