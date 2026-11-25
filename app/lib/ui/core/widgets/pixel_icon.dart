import 'package:flutter/widgets.dart';

/// Icon pixel của dock thiết bị (`assets/icons/dock-*.svg`: chỉ gồm `<rect>` trên lưới viewBox), vẽ sắc cạnh với
/// mỗi pixel = [scale] điểm (components.md `SkillRow`: Clawd ×1.75, khác ×1.5).
class PixelIcon extends StatefulWidget {
  const PixelIcon(this.asset, {super.key, required this.scale, required this.color, this.semanticLabel});

  final String asset;
  final double scale;
  final Color color;
  final String? semanticLabel;

  @override
  State<PixelIcon> createState() => _PixelIconState();
}

class _PixelIconState extends State<PixelIcon> {
  PixelArt? _art;
  String? _loaded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(PixelIcon old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset) _load();
  }

  Future<void> _load() async {
    final asset = widget.asset;
    if (_loaded == asset) return;
    _loaded = asset;
    final svg = await DefaultAssetBundle.of(context).loadString(asset);
    if (!mounted || _loaded != asset) return;
    setState(() => _art = PixelArt.parse(svg));
  }

  @override
  Widget build(BuildContext context) {
    final art = _art;
    final size = art == null ? Size.zero : Size(art.width * widget.scale, art.height * widget.scale);
    return Semantics(
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel == null,
      child: CustomPaint(size: size, painter: art == null ? null : _PixelPainter(art, widget.color)),
    );
  }
}

/// Rects of a pixel SVG on its viewBox grid.
class PixelArt {
  const PixelArt(this.width, this.height, this.rects);

  /// Reads `viewBox="0 0 w h"` and every `<rect x y width height>`; anything else is ignored.
  factory PixelArt.parse(String svg) {
    final box = RegExp(r'viewBox="0 0 ([\d.]+) ([\d.]+)"').firstMatch(svg);
    double attr(String tag, String name) =>
        double.tryParse(RegExp(r'\b' '$name' r'="([\d.]+)"').firstMatch(tag)?[1] ?? '') ?? 0;
    return PixelArt(
      double.tryParse(box?[1] ?? '') ?? 0,
      double.tryParse(box?[2] ?? '') ?? 0,
      [
        for (final m in RegExp(r'<rect\b[^>]*>').allMatches(svg))
          Rect.fromLTWH(attr(m[0]!, 'x'), attr(m[0]!, 'y'), attr(m[0]!, 'width'), attr(m[0]!, 'height')),
      ],
    );
  }

  final double width, height;
  final List<Rect> rects;
}

class _PixelPainter extends CustomPainter {
  _PixelPainter(this.art, this.color);

  final PixelArt art;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (art.width == 0 || art.height == 0) return;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    canvas.scale(size.width / art.width, size.height / art.height);
    for (final r in art.rects) {
      canvas.drawRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(_PixelPainter old) => old.art != art || old.color != color;
}
