import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Memberi umpan balik "tertekan" pada kartu yang bisa diketuk.
///
/// Memakai Listener (bukan GestureDetector) supaya gesture tap tetap
/// ditangani InkWell di dalamnya.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.scale = 0.97,
    this.enabled = true,
  });

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;
  bool _cancelled = false;
  Offset? _downAt;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }

    setState(() => _pressed = value);
  }

  void _handleDown(PointerDownEvent event) {
    _downAt = event.position;
    _cancelled = false;

    if (widget.enabled) {
      _setPressed(true);
    }
  }

  void _handleMove(PointerMoveEvent event) {
    if (_cancelled || _downAt == null) {
      return;
    }

    // Geser jari > 12 px berarti user sedang scroll, bukan menekan kartu.
    if ((event.position - _downAt!).distance > 12) {
      _cancelled = true;
      _setPressed(false);
    }
  }

  void _handleEnd() {
    _downAt = null;
    _cancelled = false;
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleDown,
      onPointerMove: _handleMove,
      onPointerUp: (_) => _handleEnd(),
      onPointerCancel: (_) => _handleEnd(),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}
