import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text.dart';

/// Vùng cắt (components.md `CropFrame`, screen_specs §7): cao 340 (`cropStage`), nền đen; khung vuông 260 (`cropFrame`)
/// giữa vùng — viền 1 ink, ngoài khung phủ đen 60 %, lưới chia ba 1 px ink 35 %, 4 góc chữ L 22 nét 4. Kéo để dời,
/// chụm để phóng; [crop] (pixel ảnh) luôn nằm đúng trong khung.
class CropFrame extends StatefulWidget {
  const CropFrame({
    super.key,
    required this.image,
    required this.crop,
    required this.semanticLabel,
    required this.onPan,
    required this.onZoom,
    this.busy = false,
  });

  /// Null while the picked file is decoding (or in tests).
  final ui.Image? image;

  /// Crop square in image pixels.
  final Rect crop;
  final String semanticLabel;

  /// Delta in screen points, and the frame side it is measured against.
  final void Function(Offset delta, double frame) onPan;

  /// Factor (> 1 = in), focal point from the frame's top-left, frame side.
  final void Function(double factor, Offset focal, double frame) onZoom;

  /// Spinner over the stage (decoding).
  final bool busy;

  @override
  State<CropFrame> createState() => _CropFrameState();
}

class _CropFrameState extends State<CropFrame> {
  double _lastScale = 1;

  /// Frame side: 260, smaller on a very narrow screen (16 each side).
  static double _frame(double width) =>
      (width - 2 * AppSpace.l).clamp(0, AppSize.cropFrame).toDouble();

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.semanticLabel,
        image: true,
        child: SizedBox(
          height: AppSize.cropStage,
          width: double.infinity,
          child: LayoutBuilder(builder: (context, c) {
            final frame = _frame(c.maxWidth);
            final origin = Offset((c.maxWidth - frame) / 2, (AppSize.cropStage - frame) / 2);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (_) => _lastScale = 1,
              onScaleUpdate: (d) {
                widget.onPan(d.focalPointDelta, frame);
                if (d.pointerCount > 1 && d.scale > 0) {
                  widget.onZoom(d.scale / _lastScale, d.localFocalPoint - origin, frame);
                  _lastScale = d.scale;
                }
              },
              child: Stack(fit: StackFit.expand, children: [
                CustomPaint(painter: _CropPainter(widget.image, widget.crop, origin, frame)),
                if (widget.busy) const Center(child: CircularProgressIndicator()),
              ]),
            );
          }),
        ),
      );
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.image, this.crop, this.origin, this.frame);

  final ui.Image? image;
  final Rect crop;
  final Offset origin;
  final double frame;

  static const _veil = 0.6;
  static const _grid = 0.35;
  static const _corner = 22.0, _cornerStroke = 4.0, _cornerOut = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final stage = Offset.zero & size;
    canvas.clipRect(stage);
    canvas.drawRect(stage, Paint()..color = Colors.black);
    final box = origin & Size.square(frame);
    final img = image;
    if (img != null && crop.width > 0) {
      final k = frame / crop.width;
      final dst = Rect.fromLTWH(
          origin.dx - crop.left * k, origin.dy - crop.top * k, img.width * k, img.height * k);
      canvas.drawImageRect(img, Offset.zero & Size(img.width.toDouble(), img.height.toDouble()), dst,
          Paint()..filterQuality = FilterQuality.medium);
    }
    // Outside the frame: black 60 %.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(stage)
        ..addRect(box),
      Paint()..color = Colors.black.withValues(alpha: _veil),
    );
    final grid = Paint()
      ..color = AppColors.ink.withValues(alpha: _grid)
      ..strokeWidth = AppSize.hairline;
    for (var i = 1; i < 3; i++) {
      final x = box.left + box.width * i / 3, y = box.top + box.height * i / 3;
      canvas.drawLine(Offset(x, box.top), Offset(x, box.bottom), grid);
      canvas.drawLine(Offset(box.left, y), Offset(box.right, y), grid);
    }
    canvas.drawRect(
      box.deflate(AppSize.hairline / 2),
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSize.hairline,
    );
    // Four L corners, 22 long, 4 thick, 3 outside the frame.
    final ink = Paint()..color = AppColors.ink;
    final o = box.inflate(_cornerOut);
    for (final (x, y, dx, dy) in [
      (o.left, o.top, 1.0, 1.0),
      (o.right, o.top, -1.0, 1.0),
      (o.left, o.bottom, 1.0, -1.0),
      (o.right, o.bottom, -1.0, -1.0),
    ]) {
      canvas.drawRect(Rect.fromPoints(Offset(x, y), Offset(x + dx * _corner, y + dy * _cornerStroke)), ink);
      canvas.drawRect(Rect.fromPoints(Offset(x, y), Offset(x + dx * _cornerStroke, y + dy * _corner)), ink);
    }
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image || old.crop != crop || old.origin != origin || old.frame != frame;
}
