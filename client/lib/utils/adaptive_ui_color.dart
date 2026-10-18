import 'package:flutter/material.dart';

/// Keeps existing operational-page colors readable under the shared dark theme.
/// The approved main composition uses its own explicit design tokens.
Color adaptiveUiSurface(BuildContext context, Color light) {
  final theme = Theme.of(context);
  if (theme.brightness != Brightness.dark) return light;
  final tone = HSLColor.fromColor(light).withLightness(.5).toColor();
  return Color.alphaBlend(
    tone.withValues(alpha: .16),
    theme.colorScheme.surface,
  );
}

Color adaptiveUiText(BuildContext context, Color light) {
  final theme = Theme.of(context);
  if (theme.brightness != Brightness.dark) return light;
  final backdrop = theme.colorScheme.surfaceContainerHighest;
  double contrast(Color color) {
    final a = color.computeLuminance(), b = backdrop.computeLuminance();
    return a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
  }

  var tone = HSLColor.fromColor(light);
  while (contrast(tone.toColor()) < 4.5 && tone.lightness < 1) {
    tone = tone.withLightness((tone.lightness + .02).clamp(0.0, 1.0));
  }
  return tone.toColor();
}
