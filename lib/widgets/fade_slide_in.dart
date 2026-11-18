import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Animasi masuk satu kali: fade + geser naik sedikit.
///
/// [index] dipakai untuk stagger ringan antar item list.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 18,
    this.duration = AppMotion.slow,
  });

  final Widget child;
  final int index;
  final double offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final delayMs = index.clamp(0, 6) * 45;
    final total = duration + Duration(milliseconds: delayMs);
    final start = total.inMilliseconds == 0
        ? 0.0
        : delayMs / total.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: AppMotion.curve),
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }
}
