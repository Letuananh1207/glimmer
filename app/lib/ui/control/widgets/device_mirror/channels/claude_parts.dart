import 'dart:ui';

import '../../../../../domain/models/usage_mirror.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../xp_canvas.dart';

/// Big Clawd with moods (`Display::drawClawd`), the sleeping "Zz" (`paintZzFrame`) and the project rows
/// (`paintProjectRow`) of the Claude window.
abstract final class ClaudeParts {
  // 18×10 grid, bit 17 = leftmost column (src/core/display.cpp kClawd).
  static const _rows = [0x07FF8, 0x07FF8, 0x06FD8, 0x06FD8, 0x1FFFE, 0x1FFFE, 0x07FF8, 0x07FF8, 0x02850, 0x02850];
  static const _eyes = (1 << 12) | (1 << 5);
  static const _inner = (1 << 11) | (1 << 6);
  static const _walkLegs = 0x04848;
  static const _sleepSlits = (1 << 13) | (1 << 12) | (1 << 5) | (1 << 4);
  static const _happyHoles = [
    [10, 5], [9, 6], [11, 6], [25, 5], [24, 6], [26, 6], // eyes
    [16, 9], [19, 9], [17, 10], [18, 10], // mouth
  ];

  /// Clawd at (x, y), cells of [s] px, on [bg]; eye holes always black.
  static void clawd(XpCanvas c, int x, int y, int s, ClawdMood mood, {bool walk = false, Color bg = XpColors.body}) {
    final rows = [..._rows];
    switch (mood) {
      case ClawdMood.wide:
        rows[1] &= ~_eyes;
      case ClawdMood.happy:
        rows[2] |= _eyes;
        rows[3] |= _eyes;
      case ClawdMood.sad:
        rows[2] = (rows[2] | _eyes) & ~_inner;
      case ClawdMood.sleep:
        rows[2] |= _eyes;
        rows[3] = (rows[3] | _eyes) & ~_sleepSlits;
      case ClawdMood.open:
        break;
    }
    if (walk) rows[8] = rows[9] = _walkLegs;
    for (var j = 0; j < 10; j++) {
      for (var i = 0; i < 18; i++) {
        final bit = 1 << (17 - i);
        final Color col;
        if (rows[j] & bit != 0) {
          col = PanelColors.clawd;
        } else if (j >= 1 && j <= 3 && (_rows[0] & bit) != 0) {
          col = XpColors.black;
        } else {
          col = bg;
        }
        c.fill(x + i * s, y + j * s, s, s, col);
      }
    }
    if (mood == ClawdMood.happy) {
      final h = s ~/ 2 > 0 ? s ~/ 2 : 1;
      for (final p in _happyHoles) {
        c.fill(x + p[0] * s ~/ 2, y + p[1] * s ~/ 2, h, h, XpColors.black);
      }
    }
  }

  // Zz frames (glyph 0 = z3, 1 = z4, 2 = Z5; x, y before the (−6, −6) shift; faint).
  static const _zz = [
    (0, 198, 52, true),
    (0, 200, 50, false),
    (0, 202, 48, false),
    (0, 203, 45, false),
    (1, 202, 42, false),
    (1, 202, 40, false),
    (1, 202, 38, false),
    (1, 203, 36, false),
    (2, 204, 32, false),
    (2, 206, 30, false),
    (2, 208, 28, true),
    (2, 209, 26, true),
  ];
  static const _glyphs = [
    [0x07, 0x02, 0x07],
    [0x0F, 0x02, 0x04, 0x0F],
    [0x1F, 0x02, 0x04, 0x08, 0x1F],
  ];

  /// Number of Zz frames; frame [frames] is the blank pause.
  static const frames = 12;

  /// Zz frame [k] (0…11, 12 = pause) in its box x 190–219, y 22–51; never into the title bar.
  static void zz(XpCanvas c, int k) {
    c.fill(190, 22, 30, 30, XpColors.body);
    if (k < 0 || k >= frames) return;
    final (g, fx, fy, faint) = _zz[k];
    final rows = _glyphs[g];
    final n = rows.length;
    final x = fx - 6, y = fy - 6;
    for (var j = 0; j < n; j++) {
      if (y + j * 2 < 22) continue;
      for (var i = 0; i < n; i++) {
        if (rows[j] & (1 << (n - 1 - i)) != 0) {
          c.fill(x + i * 2, y + j * 2, 2, 2, faint ? XpColors.dim : XpColors.muted);
        }
      }
    }
  }

  static Color stateColor(String state) => switch (state) {
    'approval' => XpColors.amber,
    'input' => XpColors.sky,
    'error' => XpColors.red,
    'working' => XpColors.lilac,
    _ => XpColors.green,
  };

  /// `■ glimmer Cần duyệt · Bash      2P` at row top [y]: square + status in the state colour, the detail dropped
  /// when it doesn't fit; [dim] (stale) greys square, name and status.
  static void row(XpCanvas c, AppLocalizations l, BoardRow r, int y, String age, {bool dim = false}) {
    final sc = dim ? XpColors.dim : stateColor(r.state);
    c.fill(14, y + 4, 5, 5, sc);
    c.text(age, 225, y, XpFont.jb11, XpColors.muted, align: XpAlign.right);
    final right = 225 - c.textWidth(age, XpFont.jb11).round() - 7;
    final proj = c.fit(r.project, XpFont.jb11, 84);
    c.text(proj, 23, y, XpFont.jb11, dim ? XpColors.dim : XpColors.black);
    final sx = 23 + c.textWidth(proj, XpFont.jb11).round() + 7;
    final label = l.devXpProjState(r.state);
    var st = r.detail.isEmpty ? label : '$label · ${r.detail}';
    if (r.detail.isNotEmpty && c.textWidth(st, XpFont.jb11) > right - sx) st = label;
    c.text(st, sx, y, XpFont.jb11, sc, maxWidth: (right - sx).toDouble());
  }
}
