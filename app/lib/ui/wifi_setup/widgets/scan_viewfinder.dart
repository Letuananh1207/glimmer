import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../view_models/wifi_scan_view_model.dart';

/// Khung ngắm của Quét mã (screen_specs §10): 240 × 240, đỉnh y 98, giữa ngang, bo 12; ngoài khung phủ đen 50 %; bốn góc
/// 34 × 34 nét 4 bo ngoài 14 — `scanning` ink + vạch quét ngang 2 `clawd` có quầng, `found` mint + phủ mint 18 % + vòng 72
/// mint dấu check 44 màu `bg`, `wrongCode` coral.
class ScanViewfinder extends StatefulWidget {
  const ScanViewfinder({super.key, required this.state});

  final ScanState state;

  static const side = 240.0, top = 98.0;

  @override
  State<ScanViewfinder> createState() => _ScanViewfinderState();
}

class _ScanViewfinderState extends State<ScanViewfinder> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(vsync: this, duration: _period);

  static const _period = Duration(milliseconds: 2200);
  static const _ring = 72.0, _check = 44.0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void didUpdateWidget(ScanViewfinder old) {
    super.didUpdateWidget(old);
    _run();
  }

  void _run() {
    if (widget.state == ScanState.scanning) {
      if (!_sweep.isAnimating) _sweep.repeat(reverse: true);
    } else {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final found = widget.state == ScanState.found;
    return LayoutBuilder(builder: (context, box) {
      final frame = Rect.fromLTWH(
          (box.maxWidth - ScanViewfinder.side) / 2, ScanViewfinder.top, ScanViewfinder.side, ScanViewfinder.side);
      return Stack(children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _sweep,
            builder: (_, _) => CustomPaint(
              painter: _FramePainter(
                frame: frame,
                state: widget.state,
                sweep: widget.state == ScanState.scanning ? _sweep.value : null,
              ),
            ),
          ),
        ),
        if (found)
          Positioned.fromRect(
            rect: frame,
            child: Center(
              child: Container(
                width: _ring,
                height: _ring,
                decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: _check, color: AppColors.bg),
              ),
            ),
          ),
      ]);
    });
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.frame, required this.state, required this.sweep});

  final Rect frame;
  final ScanState state;

  /// 0…1 down the frame while scanning, else null.
  final double? sweep;

  static const _radius = 12.0;
  static const _dim = 0.5, _foundTint = 0.18;
  static const _corner = 34.0, _stroke = 4.0, _cornerRadius = 14.0;
  static const _line = 2.0, _glow = 6.0, _glowAlpha = 0.6;

  Color get _cornerColor => switch (state) {
        ScanState.found => AppColors.mint,
        ScanState.wrongCode => AppColors.coral,
        _ => AppColors.ink,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(frame, const Radius.circular(_radius));
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(hole)),
      Paint()..color = Colors.black.withValues(alpha: _dim),
    );
    if (state == ScanState.found) canvas.drawRRect(hole, Paint()..color = AppColors.mint.withValues(alpha: _foundTint));

    // Corners: the outer edge of a 34 × 34 rounded square, stroke 4 drawn inside it.
    final outer = frame.inflate(_stroke);
    final paint = Paint()
      ..color = _cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.butt;
    final r = outer.deflate(_stroke / 2);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(_cornerRadius - _stroke / 2));
    final path = Path()..addRRect(rr);
    canvas.save();
    for (final c in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
      canvas.save();
      canvas.clipRect(Rect.fromCenter(center: c, width: _corner * 2, height: _corner * 2));
      canvas.drawPath(path, paint);
      canvas.restore();
    }
    canvas.restore();

    final s = sweep;
    if (s != null) {
      final y = frame.top + _radius + (frame.height - 2 * _radius) * s;
      canvas.drawRect(
        Rect.fromLTWH(frame.left + _stroke, y - _glow, frame.width - 2 * _stroke, _glow * 2),
        Paint()
          ..color = AppColors.clawd.withValues(alpha: _glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _glow),
      );
      canvas.drawRect(
        Rect.fromLTWH(frame.left + _stroke, y - _line / 2, frame.width - 2 * _stroke, _line),
        Paint()..color = AppColors.clawd,
      );
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.frame != frame || old.state != state || old.sweep != sweep;
}
