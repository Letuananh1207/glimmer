import 'dart:ui';

import '../../../../domain/models/touch.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/themes/xp_colors.dart';
import 'xp_canvas.dart';

/// The device's context menu (`src/channels/xp_menu.cpp`, panel P-2026-11-26.14 XP-Menu), drawn over the mirror:
/// 1-px xpMenuBorder frame, white inside, items 17 tall (JBMono-11 at x+17, item+2; dim = xpMenuBorder), ▸ 4×7 at
/// (x+w−10, item+5), separators 7 tall; window menu glyphs 7×7 at (x+5, item+5), "Đóng" 12B + "Alt+F4" TR.
abstract final class XpMenuPainter {
  // Glyph rects (dx, dy, w, h) from the item's top-left (source XP-Menu-Window.dc.html).
  static const _restore = [
    (7, 5, 5, 2),
    (11, 7, 1, 3),
    (10, 9, 1, 1),
    (5, 7, 5, 2),
    (5, 9, 1, 3),
    (9, 9, 1, 3),
    (5, 11, 5, 1),
  ];
  static const _min = [(6, 10, 5, 2)];
  static const _max = [(5, 5, 7, 2), (5, 7, 1, 5), (11, 7, 1, 5), (5, 11, 7, 1)];
  static const _close = [
    (5, 5, 2, 1), (10, 5, 2, 1), (6, 6, 2, 1), (9, 6, 2, 1), (7, 7, 3, 1), (7, 8, 3, 1), (7, 9, 3, 1), //
    (6, 10, 2, 1), (9, 10, 2, 1), (5, 11, 2, 1), (10, 11, 2, 1),
  ];

  static String _label(AppLocalizations l, MenuItem i) => switch (i) {
    MenuItem.arrange => l.devXpMenuArrange,
    MenuItem.refresh => l.devXpMenuRefresh,
    MenuItem.paste => l.devXpMenuPaste,
    MenuItem.pasteShortcut => l.devXpMenuPasteShortcut,
    MenuItem.newItem => l.devXpMenuNew,
    MenuItem.properties => l.devXpMenuProperties,
    MenuItem.restore => l.devXpMenuRestore,
    MenuItem.move => l.devXpMenuMove,
    MenuItem.size => l.devXpMenuSize,
    MenuItem.minimize => l.devXpMenuMinimize,
    MenuItem.maximize => l.devXpMenuMaximize,
    MenuItem.close => l.devXpMenuClose,
  };

  static List<(int, int, int, int)> _glyph(MenuItem i) => switch (i) {
    MenuItem.restore => _restore,
    MenuItem.minimize => _min,
    MenuItem.maximize => _max,
    MenuItem.close => _close,
    _ => const [],
  };

  static void paint(XpCanvas c, MenuView m, AppLocalizations l) {
    final x = m.x, y = m.y, w = m.width, h = m.height;
    c.fill(x, y, w, h, XpColors.menuBorder);
    c.fill(x + 1, y + 1, w - 2, h - 2, XpColors.white);
    var iy = y + MenuView.pad;
    for (final r in m.rows) {
      if (r == null) {
        c.hLine(x + 2, iy + 3, w - 4, XpColors.menuBorder);
        iy += MenuView.sepH;
        continue;
      }
      final Color col = m.enabled(r) || r == MenuItem.arrange ? XpColors.black : XpColors.menuBorder;
      final bold = r == MenuItem.close;
      c.text(_label(l, r), x + 17, iy + (bold ? 1 : 2), bold ? XpFont.jb12b : XpFont.jb11, col);
      if (r == MenuItem.arrange || r == MenuItem.newItem) {
        for (var k = 0; k < 4; k++) {
          c.vLine(x + w - 10 + k, iy + 5 + k, 7 - 2 * k, col);
        }
      }
      for (final (gx, gy, gw, gh) in _glyph(r)) {
        c.fill(x + gx, iy + gy, gw, gh, col);
      }
      iy += MenuView.itemH;
    }
    if (m.kind == MenuKind.window) {
      c.text(l.devXpMenuAltF4, x + w - 17, y + h - MenuView.itemH, XpFont.jb11, XpColors.black, align: XpAlign.right);
    }
  }
}
