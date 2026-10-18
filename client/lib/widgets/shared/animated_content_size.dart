import 'package:flutter/material.dart';

/// Smooth layout changes, with a direct layout when reduced motion is requested.
class AnimatedContentSize extends StatelessWidget {
  final Widget child;
  const AnimatedContentSize({super.key, required this.child});
  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? child
      : AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: child,
        );
}
