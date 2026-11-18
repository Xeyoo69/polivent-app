import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Logo + wordmark PoliVent.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 52,
    this.showWordmark = true,
    this.onDark = false,
    this.center = false,
  });

  final double size;
  final bool showWordmark;
  final bool onDark;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final wordmarkColor = onDark ? Colors.white : AppColors.textPrimary;
    final taglineColor = onDark
        ? Colors.white.withValues(alpha: 0.72)
        : AppColors.textSecondary;

    final logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: onDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Icon(
        Icons.event_available_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );

    if (!showWordmark) {
      return logo;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        logo,
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment:
              center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'POLIVENT',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: wordmarkColor,
              ),
            ),
            Text(
              'Temukan. Daftar. Hadiri.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: taglineColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
