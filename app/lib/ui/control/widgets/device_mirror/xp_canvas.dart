import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../../core/themes/app_text.dart';
import '../../../core/themes/xp_colors.dart';

/// The device's VLW fonts (`data/fonts/`, panel token `font`) as app fonts at the same pixel sizes. Line box and
/// letter spacing as in `design/panel/source/XP-*.dc.html` (the mirror copies those pages).
enum XpFont {
  /// JBMono-11: secondary text, meta, rows, status bar, tray clock.
  jb11(AppFonts.family, 11, FontWeight.w400, 13, 0.4),

  /// JBMono-12B: title bar, labels, dialog heads.
  jb12b(AppFonts.family, 12, FontWeight.w700, 15, -0.2),

  /// JBMono-13: Clock greeting, Weather description.
  jb13(AppFonts.family, 13, FontWeight.w400, 14, 0.2),

  /// JBMono-16B: card titles, centred notices.
  jb16b(AppFonts.family, 16, FontWeight.w700, 20, 0.4),

  /// VT323-32: medium numbers (temperature, %, countdown).
  vt32(XpCanvas.vt323, 32, FontWeight.w400, 26, 0.2),

  /// VT323-44: the % sign, OTA numbers.
  vt44(XpCanvas.vt323, 44, FontWeight.w400, 36, 0.4),

  /// VT323-86: hero numbers (digits and ':' only on the device).
  vt86(XpCanvas.vt323, 86, FontWeight.w400, 70, -0.4);

  const XpFont(this.family, this.size, this.weight, this.line, this.spacing);

  final String family;

  /// Pixel size of the VLW file.
  final double size;
  final FontWeight weight;

  /// Line box height (CSS `line-height` of the design pages).
  final double line;

  /// CSS `letter-spacing`.
  final double spacing;

  TextStyle style(Color color, {FontStyle? fontStyle}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    fontStyle: fontStyle,
    letterSpacing: spacing,
    height: line / size,
    leadingDistribution: TextLeadingDistribution.even,
    color: color,
  );
}

/// Horizontal anchor of [XpCanvas.text]: the left edge, the right edge or the centre at x.
enum XpAlign { left, right, center }

/// Drawing at **device pixels** (0…239 × 0…239): the caller has already scaled the canvas (×1.2 in the mirror), so
/// every number is copied as-is from the panel design (`left` / `top` / `width` / `height` of each div). Rects are
/// whole pixels, like the panel's `fillRect`; text is laid out like the design pages.
class XpCanvas {
  XpCanvas(this.canvas);

  /// Font family of the bundled VT323 (`assets/fonts/VT323-Regular.ttf`).
  static const vt323 = 'VT323';

  /// Device screen side in pixels.
  static const side = 240.0;

  final Canvas canvas;
  final Paint _paint = Paint()..isAntiAlias = false;

  /// `fillRect(x, y, w, h)`.
  void fill(num x, num y, num w, num h, Color c) {
    if (w <= 0 || h <= 0) return;
    canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()), _paint..color = c);
  }

  void pixel(num x, num y, Color c) => fill(x, y, 1, 1, c);
  void hLine(num x, num y, num w, Color c) => fill(x, y, w, 1, c);
  void vLine(num x, num y, num h, Color c) => fill(x, y, 1, h, c);

  /// `drawRect`: 1-px outline, inside not painted.
  void outline(num x, num y, num w, num h, Color c) {
    hLine(x, y, w, c);
    hLine(x, y + h - 1, w, c);
    vLine(x, y, h, c);
    vLine(x + w - 1, y, h, c);
  }

  TextPainter _layout(String s, XpFont f, Color c, FontStyle? fontStyle) => TextPainter(
    text: TextSpan(
      text: s,
      style: f.style(c, fontStyle: fontStyle),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  /// Width of [s] in [f] (for right-aligned meta, dividers, fitting).
  double textWidth(String s, XpFont f) => s.isEmpty ? 0 : _layout(s, f, XpColors.black, null).width;

  /// [s] shortened by whole characters from the end until it fits [maxWidth] (the firmware's `XP::fitText`).
  String fit(String s, XpFont f, double maxWidth) {
    var r = s.runes.toList();
    while (r.isNotEmpty && textWidth(String.fromCharCodes(r), f) > maxWidth) {
      r = r.sublist(0, r.length - 1);
    }
    return String.fromCharCodes(r);
  }

  /// Text with its line box top at [y] (the design's `top`) and [x] = left / right edge / centre per [align]
  /// (`right: 11px` in the design → x = 240 − 11 = 229). [maxWidth] trims like the firmware; [shadow] repeats the
  /// text at (+1, +1) underneath (title bar, desktop labels).
  void text(
    String s,
    num x,
    num y,
    XpFont f,
    Color color, {
    XpAlign align = XpAlign.left,
    double? maxWidth,
    Color? shadow,
    FontStyle? fontStyle,
  }) {
    if (s.isEmpty) return;
    final t = maxWidth == null ? s : fit(s, f, maxWidth);
    if (shadow != null) {
      _draw(_layout(t, f, shadow, fontStyle), x + 1, y + 1, align);
    }
    _draw(_layout(t, f, color, fontStyle), x, y, align);
  }

  void _draw(TextPainter p, num x, num y, XpAlign align) {
    final left = switch (align) {
      XpAlign.left => x.toDouble(),
      XpAlign.right => x - p.width,
      XpAlign.center => x - p.width / 2,
    };
    p.paint(canvas, Offset(left, y.toDouble()));
    p.dispose();
  }

  /// 1-bit pixel art: [rows] of equal length, [on] characters lit in [color], cells of [scale] px, top-left (x, y).
  void bits(List<String> rows, num x, num y, Color color, {int scale = 1, String on = '#'}) {
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      var i = 0;
      while (i < row.length) {
        if (row[i] != on) {
          i++;
          continue;
        }
        var run = 1;
        while (i + run < row.length && row[i + run] == on) {
          run++;
        }
        fill(x + i * scale, y + r * scale, run * scale, scale, color);
        i += run;
      }
    }
  }

  /// Several-colour pixel art: each character of [rows] found in [colors] is painted in that colour ('.' = none).
  void colorBits(List<String> rows, num x, num y, Map<String, Color> colors, {int scale = 1}) {
    for (final e in colors.entries) {
      bits(rows, x, y, e.value, scale: scale, on: e.key);
    }
  }

  /// A decoded image (photo, wallpaper) at (x, y) in [w] × [h] device pixels.
  void image(ui.Image img, num x, num y, num w, num h) => canvas.drawImageRect(
    img,
    Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
    Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
    Paint()..filterQuality = FilterQuality.medium,
  );
}
