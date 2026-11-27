// Touches on the device screen (design 2026-11-26.6 / .7, R-DK-8): a point in device pixels (0…240) → what it hits on
// the XP screen. Geometry follows the panel design (P-2026-11-26.14): title bar buttons (`XP::window`, centres x 192 /
// 210 / 228, y 11), taskbar y 214–239 (start x 0–67, one 28-px button per open window from x 71, step 30), desktop
// icons (`DesktopView.icons`: cells 48 tall, labels up to 80 px wide).
import '../models/mirror_frame.dart';
import '../models/touch.dart';
import 'control_rules.dart';

/// Half of the 44 × 44 dp hit box around a small target's centre, in device pixels at the mirror's 1.5 scale.
const touchReach = 44 / 1.5 / 2;

const _titleButtons = [(192, TouchKind.minimize), (210, TouchKind.maximize), (228, TouchKind.close)];
const _titleY = 11;
const _taskbarY = 214;
const _startRight = 68;
const _buttonX0 = 71, _buttonStep = 30, _buttonW = 28, _buttonCy = 227;
const _iconHalfW = 40, _iconCell = 48;
// R-DK-13 (panel P-2026-11-26.15): the tray's weather icon 16×14 at (180, 220), the balloon's × 12×12 at (220, 143).
const _trayIconCx = 188, _closeCx = 226, _closeCy = 149;
// R-DK-14 (panel P-2026-11-26.17): the balloon box 140×62 at (96, 138); the tray clock right of the tray icon (tray
// from x 196 without it); the Weather window's tabs "Hiện tại" x 6–71, "Dự báo" x 72–123 (JBMono-11 width + 10), y 26–41.
const _balloonX = 96, _balloonY = 138, _balloonW = 140, _balloonH = 62;
const _trayX = 196, _trayClockXWithIcon = 203;
const _tabs = [(6, 72, 'Weather'), (72, 124, 'Forecast')];
const _tabCy = 34;

/// Channels drawn as an XP window with the title bar buttons (not the desktop, the night face, cards, setup).
bool hasWindowButtons(String channel) =>
    !const {'Home', 'Night', 'Attention', 'Setup', MirrorFrame.setupScreen}.contains(channel);

/// What the point ([x], [y]) in device pixels hits on [frame].
TouchTarget touchTargetAt(double x, double y, MirrorFrame frame) {
  final ch = frame.channel;
  if (frame.screenOff || ch == 'Night' || ch == MirrorFrame.setupScreen) return TouchTarget.none;

  // The balloon's × (desktop, balloon up) — it lies over the icons.
  final desk = frame.agents.desktop;
  if (ch == 'Home' &&
      desk.balloon &&
      desk.tipBalloon &&
      (x - _closeCx).abs() <= touchReach &&
      (y - _closeCy).abs() <= touchReach) {
    return const TouchTarget(TouchKind.balloonClose);
  }

  final real = xpReal(frame.settings);
  // R-DK-14: the balloon's body opens Thời tiết.
  if (real &&
      ch == 'Home' &&
      desk.balloon &&
      desk.tipBalloon &&
      x >= _balloonX &&
      x < _balloonX + _balloonW &&
      y >= _balloonY &&
      y < _balloonY + _balloonH) {
    return const TouchTarget(TouchKind.balloonBody);
  }

  // Taskbar: start, then the open windows' buttons, then the tray's weather icon and clock.
  if (y >= _buttonCy - touchReach) {
    if (y >= _taskbarY && x < _startRight) return const TouchTarget(TouchKind.start);
    if (frame.taskbar.trayWeather && y >= _taskbarY && (x - _trayIconCx).abs() <= touchReach) {
      return const TouchTarget(TouchKind.tray);
    }
    if (real && y >= _taskbarY && x >= (frame.taskbar.trayWeather ? _trayClockXWithIcon : _trayX)) {
      return const TouchTarget(TouchKind.trayClock);
    }
    final programs = frame.taskbar.programs;
    for (var i = 0; i < programs.length; i++) {
      final cx = _buttonX0 + _buttonStep * i + _buttonW / 2;
      if ((x - cx).abs() <= _buttonStep / 2) return TouchTarget(TouchKind.taskbar, program: programs[i]);
    }
    if (y >= _taskbarY) return TouchTarget.none;
  }

  // Title bar buttons: the nearest centre within reach.
  if (hasWindowButtons(ch) && y <= _titleY + touchReach) {
    TouchKind? best;
    var bestD = touchReach;
    for (final (cx, kind) in _titleButtons) {
      final d = (x - cx).abs();
      if (d <= bestD) {
        bestD = d;
        best = kind;
      }
    }
    if (best != null) return TouchTarget(best);
  }

  // R-DK-14: the Weather window's tabs.
  if (real && (ch == 'Weather' || ch == 'Forecast') && (y - _tabCy).abs() <= touchReach) {
    for (final (x0, x1, p) in _tabs) {
      if (x >= x0 && x < x1) return TouchTarget(TouchKind.tab, program: p);
    }
  }

  // Desktop icons (the trash opens nothing).
  if (ch == 'Home') {
    for (final ic in frame.agents.desktop.icons) {
      if ((x - ic.cx).abs() <= _iconHalfW && y >= ic.y && y < ic.y + _iconCell) {
        return ic.program == null ? TouchTarget.none : TouchTarget(TouchKind.icon, program: ic.program);
      }
    }
  }
  return TouchTarget.none;
}

/// A menu at ([x], [y]) kept inside the screen above the taskbar (x ≤ 240 − w, y ≤ 214 − h), as the firmware does.
MenuView placeMenu(MenuKind kind, int x, int y, {String? program, bool minimized = false}) {
  final probe = MenuView(kind, 0, 0);
  return MenuView(
    kind,
    x.clamp(0, 240 - probe.width),
    y.clamp(0, 214 - probe.height),
    program: program,
    minimized: minimized,
  );
}

/// R-DK-11: the menu a hold at ([x], [y]) opens (XP right-click), or null: a taskbar button → that window's menu
/// rising from the button (bottom-left at (button x, 213)); a window's title bar → its menu at the point; an empty
/// spot of the desktop → the desktop menu at the point. Icons, the window body, start, the tray: none.
MenuView? holdMenuAt(double x, double y, MirrorFrame frame, {Set<String> minimized = const {}}) {
  final ch = frame.channel;
  final t = touchTargetAt(x, y, frame);
  if (t.kind == TouchKind.taskbar) {
    final i = frame.taskbar.programs.indexOf(t.program!);
    final probe = const MenuView(MenuKind.window, 0, 0);
    return placeMenu(
      MenuKind.window,
      _buttonX0 + _buttonStep * i,
      213 - probe.height,
      program: t.program,
      minimized: minimized.contains(t.program),
    );
  }
  if (t.kind != TouchKind.none || y >= _taskbarY || frame.screenOff) return null;
  if (hasWindowButtons(ch) && y < 22 && programOf(ch) != null) {
    return placeMenu(MenuKind.window, x.round(), y.round(), program: ch);
  }
  if (ch == 'Home') return placeMenu(MenuKind.desktop, x.round(), y.round());
  return null;
}

/// The window programs (the channels that open as a window).
String? programOf(String channel) =>
    const {
      'Claude',
      'Codex',
      'AI',
      'Trend',
      'Agents',
      'Photo',
      'Weather',
      'Forecast',
      'Clock',
      'Info',
      'Mines', //
    }.contains(channel)
    ? channel
    : null;

/// R-DK-11: the item of [menu] at ([x], [y]); null on a separator, the border or outside (see [menuContains]).
MenuItem? menuItemAt(MenuView menu, double x, double y) {
  if (!menuContains(menu, x, y)) return null;
  var top = menu.y + MenuView.pad;
  for (final r in menu.rows) {
    final h = r == null ? MenuView.sepH : MenuView.itemH;
    if (y >= top && y < top + h) return r;
    top += h;
  }
  return null;
}

bool menuContains(MenuView menu, double x, double y) =>
    x >= menu.x && x < menu.x + menu.width && y >= menu.y && y < menu.y + menu.height;
