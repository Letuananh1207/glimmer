import 'dart:ui';

import '../../../core/themes/xp_colors.dart';
import 'xp_bits.dart';
import 'xp_canvas.dart';

/// Title-bar / taskbar icons (`XPCore::Icon`).
enum XpIcon { none, clawd, photo, weather, clock, info }

/// Message-box icon (`XP::Dialog`).
enum XpDialog { error, warn, info }

/// The XP window chrome and components of the firmware (`src/channels/xp.cpp`, panel screen_specs §17, token
/// themeXP), at device pixels. Text positions are the design pages' (`top` = firmware y, +1 for JBMono-12B).
/// Zones: title bar y 0–21, frame x 0–1 / 238–239, body x 2–237 y 22–213 (content x 10–229), status bar y 196–213,
/// taskbar y 214–239 ([XpTaskbar]).
abstract final class Xp {
  /// Body fill rectangle.
  static const bodyX = 2, bodyY = 22, bodyW = 236, bodyH = 192;

  /// Content column (`Layout::XP_L` / `XP_R`) and the status bar top.
  static const left = 10, right = 229, statusY = 196;

  static void _titleBands(XpCanvas c, num x, num w) {
    c.fill(x, 0, w, 1, XpColors.titleHi);
    c.fill(x, 1, w, 2, XpColors.titleLight);
    c.fill(x, 3, w, 16, XpColors.title);
    c.fill(x, 19, w, 2, XpColors.titleDark);
    c.fill(x, 21, w, 1, XpColors.titleEdge);
  }

  /// Full window: title bar, frame, body; [statusBar] adds the empty status bar (fill it with [Xp.statusBar]).
  static void window(XpCanvas c, String title, {XpIcon icon = XpIcon.clawd, String meta = '', bool statusBar = false}) {
    titleBar(c, title, icon: icon, meta: meta);
    c.fill(0, bodyY, 2, bodyH, XpColors.frame);
    c.fill(238, bodyY, 2, bodyH, XpColors.frame);
    c.fill(bodyX, bodyY, bodyW, bodyH, XpColors.body);
    if (statusBar) Xp.statusBar(c, '', '');
  }

  /// Title bar (y 0–21): bands, icon, "title · meta" (12B white, shadow +1, ≤ 156 px), min / max / close buttons.
  static void titleBar(XpCanvas c, String title, {XpIcon icon = XpIcon.clawd, String meta = ''}) {
    _titleBands(c, 0, XpCanvas.side);
    switch (icon) {
      case XpIcon.none:
        break;
      case XpIcon.clawd:
        clawd(c, 4, 6);
      case XpIcon.info:
        c.bits(XpBits.info, 8, 6, XpColors.white);
      default:
        final (w, h) = iconSize(icon);
        drawIcon(c, icon, 13 - w ~/ 2, 11 - h ~/ 2, XpColors.white);
    }
    final t = meta.isEmpty ? title : '$title · $meta';
    c.text(t, 24, 5, XpFont.jb12b, XpColors.white, maxWidth: 156, shadow: XpColors.titleShadow);
    _caption(c, 184, XpColors.titleLight, '_');
    _caption(c, 202, XpColors.titleLight, 'o');
    _caption(c, 220, XpColors.close, 'x');
  }

  static void _caption(XpCanvas c, int x, Color fill, String kind) {
    const y = 3;
    c.fill(x, y, 16, 16, XpColors.white);
    c.fill(x + 1, y + 1, 14, 14, fill);
    switch (kind) {
      case '_':
        c.fill(x + 4, y + 10, 6, 2, XpColors.white);
      case 'o':
        c.outline(x + 4, y + 3, 8, 8, XpColors.white);
        c.hLine(x + 4, y + 4, 8, XpColors.white);
      default:
        for (var r = 0; r < 7; r++) {
          c.fill(x + 4 + r, y + 4 + r, 2, 1, XpColors.white);
          c.fill(x + 10 - r, y + 4 + r, 2, 1, XpColors.white);
        }
    }
  }

  /// Status bar (y 196–213): line, white highlight, body; [left] at (8, 199), [right] right-aligned to 231 with a
  /// divider before it. JBMono-11, black unless coloured.
  static void statusBar(
    XpCanvas c,
    String left,
    String right, {
    Color leftColor = XpColors.black,
    Color rightColor = XpColors.black,
  }) {
    const y = statusY;
    c.fill(bodyX, y, bodyW, 1, XpColors.statusLine);
    c.fill(bodyX, y + 1, bodyW, 1, XpColors.white);
    c.fill(bodyX, y + 2, bodyW, 214 - y - 2, XpColors.body);
    var leftMax = 231.0 - 8;
    final leftW = c.textWidth(left, XpFont.jb11);
    if (right.isNotEmpty) {
      final all = (231 - 0 - 8) - 8.0;
      final room = left.isEmpty ? all : (all - leftW - 4 > 120 ? all - leftW - 4 : 120.0);
      final r = c.fit(right, XpFont.jb11, room);
      final dx = 231 - c.textWidth(r, XpFont.jb11).round() - 8;
      c.fill(dx, y + 2, 1, 15, XpColors.statusLine);
      c.text(r, 231, y + 3, XpFont.jb11, rightColor, align: XpAlign.right);
      leftMax = dx - 4.0 - 8;
    }
    c.text(left, 8, y + 3, XpFont.jb11, leftColor, maxWidth: leftMax);
  }

  /// Block progress bar: field border, white field, 9 blocks of [on] lit when pct > i·11.11 (no partial blocks).
  /// [padY] −1 = 1 (blocks from y+2); the Claude weekly bar passes 2.
  static void progress(XpCanvas c, int x, int y, int w, int h, double pct, {Color on = XpColors.bar, int padY = -1}) {
    c.outline(x, y, w, h, XpColors.fieldBorder);
    c.fill(x + 1, y + 1, w - 2, h - 2, XpColors.white);
    final b = blocks(x, y, w, h, padY: padY);
    var bx = b.x0;
    for (var i = 0; i < 9; i++) {
      final bw = i == 8 ? b.lastW : b.w;
      if (pct > i * (100 / 9)) c.fill(bx, b.y0, bw, b.h, on);
      bx += b.w + b.gap;
    }
  }

  /// Geometry of the 9 blocks (`XPCore::blocks`).
  static ({int x0, int y0, int w, int h, int gap, int lastW}) blocks(int x, int y, int w, int h, {int padY = -1}) {
    final iw = w - 2, ih = h - 2;
    final gap = ih > 6 ? 2 : 1;
    final py = padY >= 0 ? padY : 1;
    final avail = iw - 2 * gap - 8 * gap;
    final bw = avail ~/ 9;
    return (x0: x + 1 + gap, y0: y + 1 + py, w: bw, h: ih - 2 * py, gap: gap, lastW: bw + avail % 9);
  }

  /// Group box: 1-px outline (inside not filled) + caption JBMono-11 at (x+7, y−6) on a body patch.
  static void groupBox(XpCanvas c, int x, int y, int w, int h, String label) {
    c.outline(x, y, w, h, XpColors.group);
    if (label.isEmpty) return;
    c.fill(x + 4, y - 6, c.textWidth(label, XpFont.jb11).round() + 6, 13, XpColors.body);
    c.text(label, x + 7, y - 6, XpFont.jb11, XpColors.groupLabel);
  }

  /// White field / list box: border + white fill.
  static void field(XpCanvas c, int x, int y, int w, int h) {
    c.outline(x, y, w, h, XpColors.fieldBorder);
    c.fill(x + 1, y + 1, w - 2, h - 2, XpColors.white);
  }

  static const _circle = [-1, 7, 6, 4, 3, 3, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3, 4, 6, 7, -1];
  static const _triangle = [-1, -1, 11, 11, 10, 10, 9, 9, 8, 8, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 0, -1];

  static void _inset(XpCanvas c, List<int> rows, int x, int y, Color col) {
    for (var r = 0; r < 24; r++) {
      if (rows[r] >= 0) c.fill(x + rows[r], y + r, 24 - 2 * rows[r], 1, col);
    }
  }

  /// Message-box icon 24×24 (round red X / yellow triangle ! / round blue i) at (x, y).
  static void dialogIcon(XpCanvas c, XpDialog kind, int x, int y) {
    c.fill(x, y, 24, 24, XpColors.body);
    switch (kind) {
      case XpDialog.error:
        _inset(c, _circle, x, y, XpColors.iconError);
        for (var r = 0; r < 10; r++) {
          c.fill(x + 7 + r, y + 7 + r, 2, 2, XpColors.white);
          c.fill(x + 15 - r, y + 7 + r, 2, 2, XpColors.white);
        }
      case XpDialog.warn:
        _inset(c, _triangle, x, y, XpColors.iconWarn);
        c.fill(x + 11, y + 8, 3, 8, XpColors.black);
        c.fill(x + 11, y + 18, 3, 3, XpColors.black);
      case XpDialog.info:
        _inset(c, _circle, x, y, XpColors.iconInfo);
        c.fill(x + 10, y + 5, 4, 3, XpColors.white);
        c.fill(x + 10, y + 10, 4, 9, XpColors.white);
    }
  }

  /// Message box on the body (no buttons): icon (14, 36), head 12B, lines JBMono-11 every 16 px from y 58 ('' =
  /// blank row), optional underlined [link] 22 px under the last line and a muted [sub] line under it.
  static void dialog(XpCanvas c, XpDialog kind, String head, List<String> lines, {String link = '', String sub = ''}) {
    dialogIcon(c, kind, 14, 36);
    c.text(head, 48, 39, XpFont.jb12b, XpColors.black);
    var y = 58;
    for (final l in lines) {
      c.text(l, 48, y, XpFont.jb11, XpColors.label);
      y += 16;
    }
    final ly = lines.isEmpty ? 58 : y - 16 + 22;
    if (link.isEmpty) return;
    c.text(link, 48, ly + 1, XpFont.jb12b, XpColors.link);
    c.hLine(48, ly + 14, c.textWidth(link, XpFont.jb12b).round(), XpColors.link);
    c.text(sub, 48, ly + 20, XpFont.jb11, XpColors.muted);
  }

  /// Marquee box (loading): field + 3 lit cells of 9 at [step] (one step per 200 ms on the device).
  static void marquee(XpCanvas c, int x, int y, int w, int h, int step) {
    field(c, x, y, w, h);
    final b = blocks(x, y, w, h, padY: 2);
    final p = step % 11;
    for (var i = 0; i < 9; i++) {
      if (i <= p && i > p - 3) c.fill(b.x0 + i * (b.w + b.gap), b.y0, b.w, b.h, XpColors.bar);
    }
  }

  /// "Đang tải" body: label 12B centred at (120, 92) + the 140×14 marquee at (50, 116).
  static void loading(XpCanvas c, String label, {int step = 0}) {
    c.text(label, 120, 93, XpFont.jb12b, XpColors.black, align: XpAlign.center);
    marquee(c, 50, 116, 140, 14, step);
  }

  /// Yellow notification strip (x, y, w × 14): amber "!" + JBMono-11 text (red by default), trimmed.
  static void infoStrip(XpCanvas c, int x, int y, int w, String text, {Color textColor = XpColors.red}) {
    c.fill(x, y, w, 14, XpColors.infoBar);
    c.bits(XpBits.bang, x + 4, y + 3, XpColors.amber);
    c.text(text, x + 13, y + 1, XpFont.jb11, textColor, maxWidth: w - 15.0);
  }

  /// Icon size in cells (w, h).
  static (int, int) iconSize(XpIcon i) => switch (i) {
    XpIcon.clawd => (18, 10),
    XpIcon.photo => (16, 11),
    XpIcon.weather || XpIcon.clock => (16, 14),
    XpIcon.info => (6, 9),
    XpIcon.none => (0, 0),
  };

  /// Icon at (x, y) in [color], cells of [scale] px. Clawd's eye holes are always black.
  static void drawIcon(XpCanvas c, XpIcon i, num x, num y, Color color, {int scale = 1}) {
    switch (i) {
      case XpIcon.clawd:
        clawd(c, x, y, color: color, scale: scale);
      case XpIcon.photo:
        c.bits(XpBits.photo, x, y, color, scale: scale);
      case XpIcon.weather:
        c.bits(XpBits.weather, x, y, color, scale: scale);
      case XpIcon.clock:
        c.bits(XpBits.clock, x, y, color, scale: scale);
      case XpIcon.info:
        c.bits(XpBits.info, x, y, color, scale: scale);
      case XpIcon.none:
        break;
    }
  }

  /// Clawd 18×10 (default orange) with black eye holes, cells of [scale] px.
  static void clawd(XpCanvas c, num x, num y, {Color color = PanelColors.clawd, int scale = 1}) {
    c.bits(XpBits.clawd, x, y, color, scale: scale);
    for (final ex in [5, 12]) {
      c.fill(x + ex * scale, y + 2 * scale, scale, 2 * scale, XpColors.black);
    }
  }

  /// The four-colour flag 14×12, cells of [scale] px (taskbar ×1, setup ×2, boot ×3).
  static void flag(XpCanvas c, num x, num y, {int scale = 1}) => c.colorBits(XpBits.flag, x, y, const {
    'R': XpColors.flagRed,
    'G': XpColors.flagGreen,
    'B': XpColors.flagBlue,
    'Y': XpColors.flagYellow,
  }, scale: scale);
}
