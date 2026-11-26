import 'dart:ui';

import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../xp_bits.dart';
import '../xp_canvas.dart';

/// Pieces shared by the Attention and Agents painters (`ch_attention.cpp`).
abstract final class AgentBits {
  /// XP kind colour on the beige body (`xpKindColor`).
  static Color kindColor(CardKind k) => switch (k) {
    CardKind.approval || CardKind.warning => XpColors.amber,
    CardKind.error => XpColors.red,
    CardKind.input => XpColors.sky,
    CardKind.progress => XpColors.lilac,
    CardKind.success => XpColors.green,
    CardKind.info => XpColors.black,
  };

  /// "45P" / "6G" / "2NG" (`TimeUtil::shortDuration`).
  static String shortDuration(AppLocalizations l, (int, DurUnit) d) => l.devXpShortDur(d.$1, d.$2.name);

  /// [s] cut by whole characters with "..." until it fits [maxW] (`fitLine`).
  static String fitDots(XpCanvas c, String s, XpFont f, double maxW) {
    if (c.textWidth(s, f) <= maxW) return s;
    var r = s.runes.toList();
    while (r.length > 1) {
      r = r.sublist(0, r.length - 1);
      final t = '${String.fromCharCodes(r)}...';
      if (c.textWidth(t, f) <= maxW) return t;
    }
    return String.fromCharCodes(r);
  }

  /// Clawd grid 18×10 with [eyes] (`drawClawd`, tools/screens.py `clawd_grid`).
  static List<String> clawdGrid(ClawdEyes eyes) {
    final g = [for (final r in XpBits.clawd) r.split('')];
    switch (eyes) {
      case ClawdEyes.wide:
        g[1][5] = g[1][12] = '.';
      case ClawdEyes.happy:
        g[2][5] = g[2][12] = g[3][5] = g[3][12] = '#';
      case ClawdEyes.sad:
        g[2][5] = g[2][12] = '#';
        g[2][6] = g[2][11] = '.';
        g[3][5] = g[3][12] = '.';
      case ClawdEyes.open:
        break;
    }
    return [for (final r in g) r.join()];
  }

  static const _happyHoles = [
    (10, 5),
    (9, 6),
    (11, 6),
    (25, 5),
    (24, 6),
    (26, 6),
    (16, 9),
    (19, 9),
    (17, 10),
    (18, 10),
  ];

  /// Big Clawd at (x, y) in cells of [scale] px: body [color], eye holes (rows 1–3, columns 3–14) black.
  static void clawd(XpCanvas c, int x, int y, int scale, Color color, ClawdEyes eyes) {
    final g = clawdGrid(eyes);
    c.bits(g, x, y, color, scale: scale);
    for (var j = 1; j <= 3; j++) {
      for (var i = 3; i <= 14; i++) {
        if (g[j][i] != '#') c.fill(x + i * scale, y + j * scale, scale, scale, XpColors.black);
      }
    }
    if (eyes == ClawdEyes.happy) {
      final h = scale ~/ 2 < 1 ? 1 : scale ~/ 2;
      for (final (hx, hy) in _happyHoles) {
        c.fill(x + hx * scale ~/ 2, y + hy * scale ~/ 2, h, h, XpColors.black);
      }
    }
  }
}
