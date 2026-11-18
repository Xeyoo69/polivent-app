import 'package:flutter/material.dart';

/// Ornamen lingkaran lembut untuk banner/header bergradien.
///
/// Sengaja memakai CustomPainter supaya tidak menambah widget berat dan
/// tetap tajam di semua ukuran layar.
class DecorativePattern extends StatelessWidget {
  const DecorativePattern({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.14,
  });

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _PatternPainter(color: color, opacity: opacity),
        size: Size.infinite,
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter({required this.color, required this.opacity});

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final fill = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final ring = Paint()
      ..color = color.withValues(alpha: opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Lingkaran besar di kanan atas.
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.04),
      size.width * 0.34,
      fill,
    );

    // Lingkaran di kiri bawah.
    canvas.drawCircle(
      Offset(size.width * 0.06, size.height * 0.98),
      size.width * 0.26,
      fill,
    );

    // Aksen kecil.
    canvas.drawCircle(
      Offset(size.width * 0.66, size.height * 1.02),
      size.width * 0.09,
      fill,
    );

    // Cincin tipis agar terasa lebih hidup.
    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.86),
      size.width * 0.2,
      ring,
    );
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.18),
      size.width * 0.075,
      ring,
    );
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}
