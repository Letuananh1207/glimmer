import 'package:flutter/widgets.dart';

/// Icon tab "Màn hình" của thanh dưới (`assets/icons/nav-home.svg`, lưới 24): khung màn bo 2 nét 2 + ba vạch trái.
/// Vẽ thẳng vì svg có `<path>` (PixelIcon chỉ đọc `<rect>`). Màu theo [color] hoặc IconTheme.
class NavHomeIcon extends StatelessWidget {
  const NavHomeIcon({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _NavHomePainter(color ?? IconTheme.of(context).color ?? const IconThemeData.fallback().color!),
      );
}

class _NavHomePainter extends CustomPainter {
  _NavHomePainter(this.color);

  final Color color;

  // Geometry of nav-home.svg on its 24 grid.
  static const _grid = 24.0;
  static const _outer = Rect.fromLTRB(2, 4, 22, 20);
  static const _inner = Rect.fromLTRB(4, 6, 20, 18);
  static const _radius = Radius.circular(2);
  static const _bars = [Rect.fromLTWH(6, 8, 3, 2), Rect.fromLTWH(6, 11, 3, 2), Rect.fromLTWH(6, 14, 3, 2)];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _grid, size.height / _grid);
    final paint = Paint()..color = color;
    final frame = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(RRect.fromRectAndRadius(_outer, _radius))
      ..addRect(_inner);
    canvas.drawPath(frame, paint);
    for (final r in _bars) {
      canvas.drawRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(_NavHomePainter old) => old.color != color;
}
