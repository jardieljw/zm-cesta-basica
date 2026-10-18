import 'package:flutter/material.dart';

/// Extra space at the end of a scrollable page with an extended FAB.
/// This scrolls with the content; it does not reserve a fixed screen area.
EdgeInsets fabScrollPadding(BuildContext context,
    {double horizontal = 16, double top = 16, bool extended = true}) {
  final theme = Theme.of(context);
  final themedHeight = extended
      ? theme.floatingActionButtonTheme.extendedSizeConstraints?.maxHeight
      : theme.floatingActionButtonTheme.sizeConstraints?.maxHeight;
  final height = themedHeight != null && themedHeight.isFinite
      ? themedHeight
      : (!extended || theme.useMaterial3 ? 56.0 : 48.0);
  const buttonMargin = 16.0;
  const contentGap = 16.0;
  return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      height +
          buttonMargin +
          contentGap +
          MediaQuery.paddingOf(context).bottom);
}
