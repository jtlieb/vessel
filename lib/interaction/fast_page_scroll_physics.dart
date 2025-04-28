import 'package:flutter/material.dart';

/// Custom page scroll physics that makes animations 2/3 the default duration
class FastPageScrollPhysics extends PageScrollPhysics {
  /// Creates physics for a faster [PageView].
  const FastPageScrollPhysics({super.parent});

  @override
  FastPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 100 * 1, // Reduce mass to 2/3 of default to speed up
    stiffness: 100 * 1, // Increase stiffness by 50% to speed up
    damping: 0.5, // Reduce damping for slightly faster animation
  );
}
