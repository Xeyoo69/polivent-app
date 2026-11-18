import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Efek kilau untuk placeholder loading.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFE7EDF5),
                Color(0xFFF7FAFE),
                Color(0xFFE7EDF5),
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlideTransform(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.progress);

  final double progress;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
  }
}

/// Kotak placeholder.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder berbentuk kartu event (dipakai Home, Explore, My Event).
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key, this.imageSize = 104});

  final double imageSize;

  @override
  Widget build(BuildContext context) {
    final showCategory = imageSize >= 80;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Shimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              width: imageSize,
              height: imageSize,
              radius: AppRadius.md,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: imageSize,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showCategory) ...[
                      const SkeletonBox(width: 72, height: 10, radius: 999),
                      const SizedBox(height: 8),
                    ],
                    const SkeletonBox(height: 14),
                    const SizedBox(height: 6),
                    FractionallySizedBox(
                      widthFactor: 0.7,
                      child: const SkeletonBox(height: 14),
                    ),
                    const Spacer(),
                    FractionallySizedBox(
                      widthFactor: 0.55,
                      child: const SkeletonBox(height: 10),
                    ),
                    const SizedBox(height: 6),
                    FractionallySizedBox(
                      widthFactor: 0.8,
                      child: const SkeletonBox(height: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Beberapa kartu placeholder sekaligus.
class EventListSkeleton extends StatelessWidget {
  const EventListSkeleton({
    super.key,
    this.itemCount = 4,
    this.imageSize = 104,
  });

  final int itemCount;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < itemCount; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == itemCount - 1 ? 0 : AppSpacing.md,
            ),
            child: EventCardSkeleton(imageSize: imageSize),
          ),
      ],
    );
  }
}
