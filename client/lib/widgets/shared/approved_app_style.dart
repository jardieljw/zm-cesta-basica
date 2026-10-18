import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../l10n/l10n_extension.dart';
import 'approved_icon.dart';

/// Direct native mapping of FE-052 product tokens. Navigation keeps its own
/// radius and geometry; the panel radius must never leak into the sidebar.
class ApprovedAppearance extends ThemeExtension<ApprovedAppearance> {
  final Color accent;
  final bool pure;
  final bool solid;
  final bool reducedMotion;
  const ApprovedAppearance({
    required this.accent,
    required this.pure,
    this.solid = false,
    this.reducedMotion = false,
  });
  @override
  ApprovedAppearance copyWith({
    Color? accent,
    bool? pure,
    bool? solid,
    bool? reducedMotion,
  }) =>
      ApprovedAppearance(
        accent: accent ?? this.accent,
        pure: pure ?? this.pure,
        solid: solid ?? this.solid,
        reducedMotion: reducedMotion ?? this.reducedMotion,
      );
  @override
  ApprovedAppearance lerp(covariant ApprovedAppearance? other, double t) =>
      other == null
      ? this
      : ApprovedAppearance(
          accent: Color.lerp(accent, other.accent, t)!,
          pure: t < .5 ? pure : other.pure,
          solid: t < .5 ? solid : other.solid,
          reducedMotion: t < .5 ? reducedMotion : other.reducedMotion,
        );
}

class AppPalette {
  final bool dark;
  final bool pure;
  final Color originalAccent;
  final bool solid;
  final bool reducedMotion;
  const AppPalette(
    this.dark, {
    this.pure = false,
    this.originalAccent = const Color(0xff2866ae),
    this.solid = false,
    this.reducedMotion = false,
  });
  static AppPalette of(BuildContext context) {
    final theme = Theme.of(context),
        appearance = Theme.of(context).extension<ApprovedAppearance>();
    return AppPalette(
      theme.brightness == Brightness.dark,
      pure: appearance?.pure ?? false,
      originalAccent: appearance?.accent ?? const Color(0xff2866ae),
      solid: appearance?.solid ?? false,
      reducedMotion: appearance?.reducedMotion ?? false,
    );
  }

  Color get page => pure
      ? (dark ? Colors.black : Colors.white)
      : Color(dark ? 0xff141518 : 0xfff6f7f9);
  Color get surface => Color(dark ? 0xff24262b : 0xffffffff);
  Color get ink => Color(dark ? 0xffeef0f5 : 0xff222730);
  Color get sub => Color(dark ? 0xffb6becb : 0xff5c6472);
  Color get line => Color(dark ? 0xff454b57 : 0xffe0e4eb);
  bool get _original => originalAccent.toARGB32() == 0xff2866ae;
  Color get accent {
    if (_original) return Color(dark ? 0xffa7caff : 0xff2866ae);
    var hsl = HSLColor.fromColor(originalAccent);
    var result = originalAccent;
    for (var i = 0; i < 100; i++) {
      if ([surface, page, soft].every((bg) => contrast(result, bg) >= 4.5)) {
        return result;
      }
      hsl = hsl.withLightness(
        (hsl.lightness + (dark ? .01 : -.01)).clamp(0.0, 1.0),
      );
      result = hsl.toColor();
    }
    return dark ? Colors.white : Colors.black;
  }

  static double contrast(Color a, Color b) {
    final first = a.computeLuminance(), second = b.computeLuminance();
    return first > second
        ? (first + .05) / (second + .05)
        : (second + .05) / (first + .05);
  }

  Color get accentInk => _original
      ? Color(dark ? 0xff142947 : 0xffffffff)
      : (contrast(accent, Colors.white) >= 4.5 ? Colors.white : Colors.black);
  Color get soft => _original
      ? Color(dark ? 0xff2b3e57 : 0xffedf4fd)
      : Color.alphaBlend(
          originalAccent.withValues(alpha: dark ? .23 : .08),
          dark ? const Color(0xff141518) : Colors.white,
        );
  Color get warn => Color(dark ? 0xfff2c78d : 0xff80501a);
  Color get warnFill => Color(dark ? 0xff4b3b29 : 0xfffff2df);
  Color get panel => Color(dark ? 0xe6252b35 : 0xb8ffffff);
  Color get shadow => Color(dark ? 0x52000000 : 0x20304b6c);
}

ThemeData approvedAppTheme(
  Brightness brightness, {
  Color accent = const Color(0xff2866ae),
  bool pure = false,
  bool solid = false,
  bool reducedMotion = false,
}) {
  final p = AppPalette(
    brightness == Brightness.dark,
    originalAccent: accent,
    pure: pure,
    solid: solid,
    reducedMotion: reducedMotion,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Segoe UI',
  );
  TextStyle text(double size, {bool medium = false, bool secondary = false}) =>
      TextStyle(
        fontFamily: medium ? 'Segoe UI Semibold' : 'Segoe UI',
        fontFamilyFallback: const ['Segoe UI', 'Roboto', '.SF UI Text'],
        fontSize: size,
        letterSpacing: 0,
        height: 1.45,
        fontWeight: medium ? FontWeight.w500 : FontWeight.w400,
        color: secondary ? p.sub : p.ink,
      );
  return base.copyWith(
    extensions: [
      ApprovedAppearance(
        accent: accent,
        pure: pure,
        solid: solid,
        reducedMotion: reducedMotion,
      ),
    ],
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: p.accent,
          brightness: brightness,
        ).copyWith(
          primary: p.accent,
          onPrimary: p.accentInk,
          surface: p.surface,
          onSurface: p.ink,
          onSurfaceVariant: p.sub,
          outline: p.line,
        ),
    scaffoldBackgroundColor: p.page,
    textTheme: base.textTheme.copyWith(
      bodyMedium: text(15),
      bodyLarge: text(16),
      bodySmall: text(12, secondary: true),
      titleSmall: text(15, medium: true),
      titleMedium: text(16, medium: true).copyWith(height: 1.5555556),
      titleLarge: text(23, medium: true),
      headlineSmall: text(26, medium: true),
      headlineMedium: text(32, medium: true),
      labelLarge: text(15, medium: true),
      labelMedium: text(12, secondary: true),
      labelSmall: text(11),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.page,
      foregroundColor: p.ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: text(23, medium: true),
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) =>
          const ApprovedIcon('arrow-left', size: 18),
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(p.dark ? 0xff191f28 : 0xfff9fbff),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        backgroundColor: p.accent,
        foregroundColor: p.accentInk,
        textStyle: text(15, medium: true),
        minimumSize: const Size(44, 52),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        side: BorderSide(color: p.line),
        minimumSize: const Size(44, 48),
        shape: const StadiumBorder(),
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: p.accentInk,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

class ApprovedBackdrop extends StatelessWidget {
  final Widget child;
  const ApprovedBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final solid =
        MediaQuery.highContrastOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return ColoredBox(
      color: p.page,
      child: CustomPaint(
        painter: solid ? null : _ApprovedGlow(p.dark),
        child: _ApprovedBackdropScope(child: child),
      ),
    );
  }
}

class _ApprovedGlow extends CustomPainter {
  final bool dark;
  const _ApprovedGlow(this.dark);
  @override
  void paint(Canvas canvas, Size size) {
    void ellipse(double x, double y, double stop, Color color) {
      final center = Offset(size.width * x, size.height * y);
      final rx = math.max(x, 1 - x) * size.width * math.sqrt2 * stop;
      final ry = math.max(y, 1 - y) * size.height * math.sqrt2 * stop;
      if (rx == 0 || ry == 0) return;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(rx, ry);
      canvas.drawRect(
        Rect.fromLTRB(
          -center.dx / rx,
          -center.dy / ry,
          (size.width - center.dx) / rx,
          (size.height - center.dy) / ry,
        ),
        Paint()
          ..shader = ui.Gradient.radial(Offset.zero, 1, [
            color,
            color.withValues(alpha: 0),
          ]),
      );
      canvas.restore();
    }

    // CSS paints the first listed background above the following one.
    ellipse(.98, .64, .48, Color(dark ? 0x2ead8664 : 0x6bd9c4a6));
    ellipse(.04, .35, .57, Color(dark ? 0x3d486b96 : 0x80b9cde4));
  }

  @override
  bool shouldRepaint(_ApprovedGlow oldDelegate) => dark != oldDelegate.dark;
}

class _ApprovedBackdropScope extends InheritedWidget {
  const _ApprovedBackdropScope({required super.child});
  @override
  bool updateShouldNotify(_ApprovedBackdropScope oldWidget) => false;
}

class ApprovedSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Gradient? gradient;
  const ApprovedSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 32,
    this.gradient,
  });
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final solid =
        MediaQuery.highContrastOf(context) ||
        MediaQuery.accessibleNavigationOf(context) ||
        p.solid;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: solid
            ? const []
            : [
                BoxShadow(
                  color: p.shadow,
                  offset: const Offset(0, 7),
                  blurRadius: 24,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          enabled: !solid,
          filter: ImageFilter.compose(
            outer: const ColorFilter.matrix([
              1.11805,
              -.10725,
              -.0108,
              0,
              0,
              -.03195,
              1.04275,
              -.0108,
              0,
              0,
              -.03195,
              -.10725,
              1.1392,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            inner: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: gradient == null ? (solid ? p.surface : p.panel) : null,
              gradient: solid ? null : gradient,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: CustomPaint(
              foregroundPainter: solid
                  ? null
                  : _InsetTopEdge(
                      radius,
                      Color(p.dark ? 0x38a7b9d5 : 0xebffffff),
                    ),
              child: Material(
                type: MaterialType.transparency,
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsetTopEdge extends CustomPainter {
  final double radius;
  final Color color;
  const _InsetTopEdge(this.radius, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final original = Path()..addRRect(shape);
    final shifted = Path()..addRRect(shape.shift(const Offset(0, 1)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, original, shifted),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_InsetTopEdge oldDelegate) =>
      radius != oldDelegate.radius || color != oldDelegate.color;
}

class ApprovedHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool compact;
  final List<Widget> actions;
  const ApprovedHeader({
    super.key,
    required this.title,
    this.compact = false,
    this.actions = const [],
  });
  @override
  Size get preferredSize => Size.fromHeight(compact ? 82 : 94);
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final back = Navigator.of(context).canPop();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width > 550 ? 22 : 18,
          compact
              ? 14
              : MediaQuery.sizeOf(context).width > 550
              ? 24
              : 20,
          MediaQuery.sizeOf(context).width > 550 ? 22 : 18,
          compact ? 10 : 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (back) ...[
              SizedBox(
                width: 44,
                child: BackButton(
                  style: IconButton.styleFrom(
                    backgroundColor: p.surface,
                    minimumSize: const Size(44, 44),
                    fixedSize: const Size(44, 44),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.appBrand,
                    style: TextStyle(fontSize: 12, height: 1.45, color: p.sub),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 23,
                      height: 1.4,
                      letterSpacing: -.6,
                      fontWeight: FontWeight.w500,
                      color: p.ink,
                    ),
                  ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class ApprovedPage extends StatelessWidget {
  final String title;
  final Widget body;
  final bool compact;
  final Widget? floatingActionButton;
  final List<Widget> actions;
  const ApprovedPage({
    super.key,
    required this.title,
    required this.body,
    this.compact = false,
    this.actions = const [],
    this.floatingActionButton,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width =
          (box.maxWidth -
                  (MediaQuery.sizeOf(context).width > 550 ? 44 : 36) -
                  (Navigator.of(context).canPop() ? 54 : 0) -
                  actions.length * 48)
              .clamp(44.0, double.infinity);
      double height(String text, double size, double lineHeight) {
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontFamily: size == 23
                  ? Theme.of(context).textTheme.titleLarge?.fontFamily
                  : Theme.of(context).textTheme.bodyMedium?.fontFamily,
              fontWeight: size == 23 ? FontWeight.w500 : FontWeight.w400,
              letterSpacing: size == 23 ? -.6 : 0,
              fontSize: size,
              height: lineHeight,
            ),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: width);
        final result = painter.height;
        painter.dispose();
        return result;
      }

      final page = Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            (compact
                    ? 24
                    : MediaQuery.sizeOf(context).width > 550
                    ? 36
                    : 32) +
                3 +
                height(context.l10n.appBrand, 12, 1.45) +
                height(title, 23, 1.4),
          ),
          child: ApprovedHeader(
            title: title,
            compact: compact,
            actions: actions,
          ),
        ),
        body: body,
        floatingActionButton: floatingActionButton,
      );
      return context
                  .dependOnInheritedWidgetOfExactType<
                    _ApprovedBackdropScope
                  >() !=
              null
          ? page
          : ApprovedBackdrop(child: page);
    },
  );
}

class ApprovedSectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const ApprovedSectionHeader(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (trailing != null)
          Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class ApprovedRow extends StatelessWidget {
  final String title, subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool compact;
  const ApprovedRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.onTap,
    this.compact = false,
  });
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact
                ? 10
                : MediaQuery.sizeOf(context).width > 550
                ? 16
                : 14,
            horizontal: compact || MediaQuery.sizeOf(context).width > 550
                ? 12
                : 10,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: compact ? 40 : 48),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: p.soft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: approvedRoleIcon(icon!, size: 19, color: p.accent),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  ApprovedIcon('chevron-right', size: 16, color: p.sub),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// FE-052 Segmented pill choice selector (.rec-choice)
class ApprovedChoiceOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Key? key;
  const ApprovedChoiceOption({
    required this.value,
    required this.label,
    this.icon,
    this.key,
  });
}

class ApprovedChoice<T> extends StatelessWidget {
  final T value;
  final List<ApprovedChoiceOption<T>> options;
  final ValueChanged<T> onChanged;
  final bool enabled;

  const ApprovedChoice({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.page,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.line),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          for (final opt in options)
            Expanded(
              child: Semantics(
                selected: opt.value == value,
                button: true,
                child: Material(
                  color: opt.value == value ? p.soft : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    key: opt.key,
                    borderRadius: BorderRadius.circular(999),
                    onTap: enabled ? () => onChanged(opt.value) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (opt.icon != null) ...[
                            Icon(
                              opt.icon,
                              size: 16,
                              color: opt.value == value ? p.accent : p.sub,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              opt.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: opt.value == value
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: opt.value == value ? p.accent : p.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// FE-052 Warning box (.rec-warning)
class ApprovedWarningBox extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double radius;

  const ApprovedWarningBox({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.warnFill,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: p.warn),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: p.warn,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// FE-052 Total and balance box (.rec-total)
class ApprovedTotalBox extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Widget? trailing;

  const ApprovedTotalBox({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: p.page,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: p.ink,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// FE-052 Hero banner card (.hero)
class ApprovedHeroCard extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double radius;

  const ApprovedHeroCard({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
    this.children = const [],
    this.padding = const EdgeInsets.all(22),
    this.radius = 32,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ApprovedSurface(
      padding: padding,
      radius: radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: p.sub,
                  ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: p.ink,
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: p.sub,
                  ),
            ),
          ],
          if (children.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...children,
          ],
        ],
      ),
    );
  }
}

/// FE-052 Primary pill button (.rec-primary, .btn)
class ApprovedPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final Key? buttonKey;
  final double minHeight;

  const ApprovedPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.busy = false,
    this.buttonKey,
    this.minHeight = 52,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return FilledButton(
      key: buttonKey,
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.accentInk,
        minimumSize: Size(44, minHeight),
        shape: const StadiumBorder(),
      ),
      child: busy
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: p.accentInk,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
    );
  }
}

/// FE-052 Secondary pill button (.rec-secondary)
class ApprovedSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final Key? buttonKey;
  final double minHeight;

  const ApprovedSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.buttonKey,
    this.minHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return OutlinedButton(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        side: BorderSide(color: p.line),
        minimumSize: Size(44, minHeight),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(trailingIcon, size: 18),
          ],
        ],
      ),
    );
  }
}

/// FE-052 Collapsible filter bar (.finish-filter)
class ApprovedCollapsibleFilter extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final String label;
  final String summary;
  final Widget content;
  final Key? toggleKey;

  const ApprovedCollapsibleFilter({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.label,
    required this.summary,
    required this.content,
    this.toggleKey,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: expanded ? p.accent : p.line),
          ),
          child: InkWell(
            key: toggleKey ?? const ValueKey('approved-filter-toggle'),
            borderRadius: BorderRadius.circular(24),
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ApprovedIcon('sliders-horizontal', size: 18, color: p.sub),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        summary,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 13, color: p.sub),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RotatedBox(
                      quarterTurns: expanded ? 2 : 0,
                      child: ApprovedIcon(
                        'chevron-down',
                        size: 18,
                        color: p.sub,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
            child: content,
          ),
      ],
    );
  }
}

/// FE-052 Form field container (.rec-field)
class ApprovedField extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final double radius;
  final Color? borderColor;
  final Color? backgroundColor;

  const ApprovedField({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    this.minHeight = 56,
    this.radius = 24,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final border = borderColor ?? Color(p.dark ? 0xff7a8495 : 0xff7d8796);
    final bg = backgroundColor ?? Color(p.dark ? 0xff191f28 : 0xfff9fbff);
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      padding: padding,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

/// FE-052 Custom modal calendar dialog (.rec-calendar)
class ApprovedCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const ApprovedCalendarDialog({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<ApprovedCalendarDialog> createState() => _ApprovedCalendarDialogState();
}

class _ApprovedCalendarDialogState extends State<ApprovedCalendarDialog> {
  late DateTime _selected;
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _selected = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _viewMonth = DateTime(_selected.year, _selected.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
    });
  }

  void _selectToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Navigator.of(context).pop(today);
  }

  static const _monthNames = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  static const _weekdays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final daysInMonth = DateTime(
      _viewMonth.year,
      _viewMonth.month + 1,
      0,
    ).day;
    final firstWeekday = _viewMonth.weekday % 7;
    final totalCells = firstWeekday + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ApprovedSurface(
          padding: const EdgeInsets.all(16),
          radius: 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _prevMonth,
                    icon: const ApprovedIcon('chevron-left', size: 18),
                    tooltip: 'Mês anterior',
                  ),
                  Text(
                    '${_monthNames[_viewMonth.month - 1]} ${_viewMonth.year}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: p.ink,
                        ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const ApprovedIcon('chevron-right', size: 18),
                    tooltip: 'Próximo mês',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final w in _weekdays)
                    Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.sub,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              for (var row = 0; row < totalRows; row++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      for (var col = 0; col < 7; col++) ...[
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final cellIndex = row * 7 + col;
                              final dayNum = cellIndex - firstWeekday + 1;
                              if (dayNum < 1 || dayNum > daysInMonth) {
                                return const SizedBox(height: 38);
                              }
                              final cellDate = DateTime(
                                _viewMonth.year,
                                _viewMonth.month,
                                dayNum,
                              );
                              final isSelected = cellDate == _selected;
                              final isToday = cellDate == today;

                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).pop(cellDate);
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? p.accent
                                        : Colors.transparent,
                                    border: isToday && !isSelected
                                        ? Border.all(
                                            color: p.accent,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$dayNum',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? p.accentInk
                                          : p.ink,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ApprovedSecondaryButton(
                      text: 'Hoje',
                      onPressed: _selectToday,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: p.sub,
                        minimumSize: const Size(44, 48),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// FE-052 Date picker button (button.rec-date)
class ApprovedDateButton extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;
  final String label;
  final bool enabled;
  final Key? buttonKey;

  const ApprovedDateButton({
    super.key,
    required this.date,
    required this.onDateSelected,
    this.label = 'Data',
    this.enabled = true,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Material(
      color: Color(p.dark ? 0xff191f28 : 0xfff9fbff),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Color(p.dark ? 0xff7a8495 : 0xff7d8796),
        ),
      ),
      child: InkWell(
        key: buttonKey,
        borderRadius: BorderRadius.circular(24),
        onTap: enabled
            ? () async {
                final picked = await showDialog<DateTime>(
                  context: context,
                  builder: (context) =>
                      ApprovedCalendarDialog(initialDate: date),
                );
                if (picked != null) {
                  onDateSelected(picked);
                }
              }
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: p.sub),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$label: $formatted',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: p.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

