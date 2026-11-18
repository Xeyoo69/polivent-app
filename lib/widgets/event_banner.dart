import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../utils/category_style.dart';
import 'decorative_pattern.dart';

/// Banner event dengan placeholder aman jika gambar gagal dimuat.
class EventBanner extends StatelessWidget {
  const EventBanner({
    super.key,
    this.imageUrl,
    this.categoryName,
    this.height = 160,
    this.borderRadius = BorderRadius.zero,
    this.iconSize = 40,
  });

  final String? imageUrl;

  /// Nama kategori dipakai untuk memilih warna & ikon placeholder.
  final String? categoryName;
  final double height;
  final BorderRadius borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.forName(categoryName);

    final placeholder = Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecorativePattern(opacity: 0.16),
          Center(
            child: Container(
              width: iconSize * 1.9,
              height: iconSize * 1.9,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Icon(
                style.icon,
                size: iconSize * 0.85,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );

    final url = imageUrl;

    if (url == null || url.isEmpty) {
      return ClipRRect(borderRadius: borderRadius, child: placeholder);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url,
        headers: ApiConfig.mediaHeaders,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }

          return Container(
            height: height,
            width: double.infinity,
            color: AppColors.primarySoft,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          );
        },
      ),
    );
  }
}
