import 'package:flutter/material.dart';

/// Reveals information without abrupt vertical layout changes.
/// Hidden content immediately leaves interaction and accessibility traversal.
class AnimatedReveal extends StatelessWidget {
  final bool visible;
  final Widget child;

  const AnimatedReveal({super.key, required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: visible ? 1 : 0, end: visible ? 1 : 0),
          duration:
              reducedMotion ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: child,
          builder: (context, value, child) => ClipRect(
            child: Align(
              alignment: Alignment.topLeft,
              heightFactor: value,
              child: Opacity(opacity: value, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
