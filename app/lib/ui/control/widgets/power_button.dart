import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/cursor.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// `PowerButton` (§8, design 2026-11-27.10, R-DK-20): tròn 48 viền 2, icon ⏻ 24. Bật = viền mint, icon ink, nền `panel`
/// (`powerOff`); tắt = viền + icon coral, nền coral 12 % (`powerOn`); đang tắt / đang khởi động = vòng cung 3 px amber /
/// mint quay quanh nút (`powerShutting` / `powerBooting`). [onPressed] null = mờ 35 %, không bấm được.
class PowerButton extends StatefulWidget {
  const PowerButton({super.key, required this.power, required this.onPressed});

  final PowerState power;
  final VoidCallback? onPressed;

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  static const _icon = 24.0;
  static const _border = 2.0;
  static const _offWash = 0.12;
  static const _dim = 0.35;

  bool get _moving => widget.power == PowerState.shutting || widget.power == PowerState.booting;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    if (_moving) _spin.repeat();
  }

  @override
  void didUpdateWidget(PowerButton old) {
    super.didUpdateWidget(old);
    if (_moving && !_spin.isAnimating) _spin.repeat();
    if (!_moving && _spin.isAnimating) _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = widget.power;
    final off = p == PowerState.off;
    final label = switch (p) {
      PowerState.on => l.powerOff,
      PowerState.off => l.powerOn,
      PowerState.shutting => l.powerShutting,
      PowerState.booting => l.powerBooting,
    };
    final ring = switch (p) {
      PowerState.on => AppColors.mint,
      PowerState.off => AppColors.coral,
      _ => Colors.transparent,
    };
    final button = Container(
      width: AppSize.powerButton,
      height: AppSize.powerButton,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: _border),
        color: off ? AppColors.coral.withValues(alpha: _offWash) : AppColors.panel,
      ),
      child: Icon(Icons.power_settings_new, size: _icon, color: off ? AppColors.coral : AppColors.ink),
    );
    return Semantics(
      button: true,
      label: label,
      child: Opacity(
        opacity: widget.onPressed == null ? _dim : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  widget.onPressed!();
                },
          child: SizedBox.square(
            dimension: AppSize.powerButton,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                button,
                if (_moving)
                  Positioned.fill(
                    child: RotationTransition(
                      turns: _spin,
                      child: CustomPaint(
                        painter: _ArcPainter(p == PowerState.shutting ? AppColors.amber : AppColors.mint),
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

/// A 3-px arc a quarter round, over the button's edge.
class _ArcPainter extends CustomPainter {
  _ArcPainter(this.color);

  final Color color;
  static const _stroke = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(-_stroke / 2, -_stroke / 2, size.width + _stroke, size.height + _stroke);
    canvas.drawArc(
      r.deflate(_stroke / 2),
      -math.pi / 2,
      math.pi * 0.6,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
