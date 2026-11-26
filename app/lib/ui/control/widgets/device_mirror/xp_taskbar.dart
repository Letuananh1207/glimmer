import 'dart:ui';

import '../../../core/themes/xp_colors.dart';
import '../../../../domain/models/mirror_frame.dart';
import 'xp_bits.dart';
import 'xp_canvas.dart';
import 'xp_paint.dart';

/// The device taskbar, y 214–239 (`src/channels/taskbar.cpp`, token themeXP.taskbar, design pages XP-*): start
/// button with flag + italic "start", one 28-px button per enabled skill from x 71 (step 30), pressed = active
/// channel with slide progress, amber badge, orange Claude button on a card that needs the user, tray clock.
abstract final class XpTaskbar {
  static const y = 214, h = 26;

  static void _bands(XpCanvas c, num x, num w, int r0, int r1) {
    const bands = [
      (0, 0, XpColors.taskHi),
      (1, 2, XpColors.taskLight),
      (3, 22, XpColors.task),
      (23, 25, XpColors.taskDark),
    ];
    for (final (a0, a1, col) in bands) {
      final a = a0 > r0 ? a0 : r0, z = a1 < r1 ? a1 : r1;
      if (a <= z) c.fill(x, y + a, w, z - a + 1, col);
    }
  }

  /// Rounded right edge of the start button: inset per row (`XPCore::startInset`).
  static const _inset = [5, 3, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 3, 5];

  static Color accentColor(TaskAccent a) => switch (a) {
    TaskAccent.coral => PanelColors.coral,
    TaskAccent.mint => PanelColors.mint,
    TaskAccent.sky => PanelColors.sky,
    TaskAccent.amber => PanelColors.amber,
    TaskAccent.lilac => PanelColors.lilac,
  };

  /// Whole taskbar.
  static void paint(XpCanvas c, TaskbarModel m, String clock) {
    _bands(c, 0, 240, 0, 25);
    _start(c);
    for (var slot = 0; slot < m.buttons.length; slot++) {
      _button(c, m.buttons[slot], 71 + 30 * slot, m);
    }
    _tray(c, clock);
  }

  static void _start(XpCanvas c) {
    for (var r = 0; r < h; r++) {
      final col = r <= 1 ? XpColors.startHi : (r <= 22 ? XpColors.start : XpColors.startDark);
      c.fill(0, y + r, 68 - _inset[r], 1, col);
    }
    Xp.flag(c, 7, 221);
    c.bits(XpBits.start, 26, 222, XpColors.startShadow);
    c.bits(XpBits.start, 25, 221, XpColors.white);
  }

  static XpIcon _icon(TaskButton b) => switch (b) {
    TaskButton.claude => XpIcon.clawd,
    TaskButton.photo => XpIcon.photo,
    TaskButton.weather => XpIcon.weather,
    TaskButton.clock => XpIcon.clock,
  };

  static void _button(XpCanvas c, TaskButton b, int x, TaskbarModel m) {
    final flash = b == TaskButton.claude && m.flash;
    final pressed = !flash && b == m.active;
    final edge = flash ? XpColors.flashEdge : (pressed ? XpColors.btnPressedEdge : XpColors.btnEdge);
    final fill = flash ? XpColors.flash : (pressed ? XpColors.btnPressed : XpColors.btn);
    c.fill(x, 217, 28, 20, edge);
    c.fill(x + 1, 218, 26, 18, fill);
    final icon = _icon(b);
    if (icon == XpIcon.clawd) {
      Xp.clawd(c, x + 5, 222, color: flash ? XpColors.white : PanelColors.clawd);
    } else {
      final (w, ih) = Xp.iconSize(icon);
      Xp.drawIcon(c, icon, x + 14 - w ~/ 2, 227 - ih ~/ 2, XpColors.white);
    }
    final len = pressed ? (26 * m.progress.clamp(0.0, 1.0)).floor() : 0;
    if (len > 0) c.fill(x + 1, 234, len, 2, accentColor(m.accent));
    if (b == TaskButton.claude && !flash && m.badge > 0) {
      c.fill(x + 19, 215, 7, 9, PanelColors.amber);
      c.fill(x + 18, 216, 9, 7, PanelColors.amber);
      c.bits(XpBits.digits[m.badge > 9 ? 10 : m.badge], x + 21, 217, PanelColors.bg);
    }
  }

  static void _tray(XpCanvas c, String clock) {
    c.fill(196, y, 44, h, XpColors.tray);
    c.vLine(196, y, h, XpColors.trayEdge);
    c.hLine(197, y, 43, XpColors.trayHi);
    c.text(clock, 218, 221, XpFont.jb11, XpColors.white, align: XpAlign.center);
  }
}
