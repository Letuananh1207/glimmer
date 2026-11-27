// R-DK-22: a left click while XP's Start menu is open on the device — what it picks. Geometry of the firmware's
// rows (src/data/pointer_core.h `startLayout`, panel P-2026-11-27.25): Start covers (0, 0)–(239, 213) over the screen.
import '../models/start_pick.dart';

export '../models/start_pick.dart';

/// Programs of the left column under the pinned two, filled in this order (firmware `XPCore::recentRows`).
const _fill = ['Photo', 'Weather', 'Clock', 'Mines', 'AI', 'Trend', 'Agents'];

/// All Programs order (firmware `PointerCore::SubItem`).
const _subOrder = ['Claude', 'Codex', 'AI', 'Trend', 'Agents', 'Photo', 'Weather', 'Clock', 'Mines'];

/// [program] is installed: its skill is on (Agents also needs `showAgents`).
bool _installed(String program, List<String> skillsOn, bool showAgents) => switch (program) {
  'Claude' || 'Codex' || 'AI' || 'Trend' => skillsOn.contains('agent'),
  'Agents' => skillsOn.contains('agent') && showAgents,
  'Photo' => skillsOn.contains('photo'),
  'Weather' => skillsOn.contains('weather'),
  'Clock' => skillsOn.contains('clock'),
  'Mines' => skillsOn.contains('fun'),
  _ => false,
};

/// The 3 rows of "most frequently used": [recent] (the device's `start_recent`, newest first) that are installed,
/// then [_fill] (P-2026-11-27.25).
List<String> startRecentRows(List<String> recent, List<String> skillsOn, {bool showAgents = false}) {
  final rows = <String>[];
  for (final p in [...recent.where((p) => p != 'Claude' && p != 'Codex' && p != 'Info'), ..._fill]) {
    if (rows.length < 3 && _installed(p, skillsOn, showAgents) && !rows.contains(p)) rows.add(p);
  }
  return rows;
}

bool _in(int x, int y, int rx, int ry, int rw, int rh) => x >= rx && x < rx + rw && y >= ry && y < ry + rh;

/// What a click at device pixel ([x], [y]) picks while Start is open (rows of firmware `PointerCore::startLayout`);
/// [all] = the Tất cả chương trình sub-menu is open, [recent] = the device's `start_recent`.
StartPick startPickAt(
  int x,
  int y, {
  required List<String> skillsOn,
  bool all = false,
  bool showAgents = false,
  List<String> recent = const [],
}) {
  if (y > 213) return const StartPick(StartPickKind.close); // the taskbar: start button or elsewhere, Start goes
  final agent = skillsOn.contains('agent');

  // The sub-menu (144, top, 96 wide) lies over the right column and x 144..151 of the left one.
  if (all) {
    final subs = [for (final p in _subOrder) if (_installed(p, skillsOn, showAgents)) p];
    final h = 4 + 20 * subs.length + 7 + 20;
    final top = 213 - h < 62 ? 213 - h : 62;
    if (_in(x, y, 144, top, 96, h)) {
      for (final (i, p) in subs.indexed) {
        if (_in(x, y, 145, top + 2 + 20 * i, 94, 20)) return StartPick(StartPickKind.program, program: p);
      }
      if (_in(x, y, 145, top + 2 + 20 * subs.length + 7, 94, 20)) {
        return const StartPick(StartPickKind.appScreen, screen: AppScreen.skills);
      }
      return StartPick.none;
    }
  }

  // Left column.
  if (agent && _in(x, y, 2, 36, 149, 28)) return const StartPick(StartPickKind.program, program: 'Claude');
  if (agent && _in(x, y, 2, 64, 149, 28)) return const StartPick(StartPickKind.program, program: 'Codex');
  final rows = startRecentRows(recent, skillsOn, showAgents: showAgents);
  for (final (i, p) in rows.indexed) {
    if (_in(x, y, 2, (agent ? 99 : 38) + 20 * i, 149, 20)) return StartPick(StartPickKind.program, program: p);
  }
  if (_in(x, y, 2, 167, 149, 20)) return const StartPick(StartPickKind.toggleAll);

  // Right column (hidden under the open sub-menu: handled above).
  if (_in(x, y, 154, 38, 84, 21)) return const StartPick(StartPickKind.desktop);
  if (_in(x, y, 154, 59, 84, 21)) return const StartPick(StartPickKind.appScreen, screen: AppScreen.details);
  if (_in(x, y, 154, 88, 84, 21)) return const StartPick(StartPickKind.appScreen, screen: AppScreen.settings);
  if (_in(x, y, 154, 109, 84, 21)) return const StartPick(StartPickKind.appScreen, screen: AppScreen.skills);
  if (_in(x, y, 154, 130, 84, 21)) return const StartPick(StartPickKind.appScreen, screen: AppScreen.device);

  // Bottom band: Khởi động lại · Tắt máy.
  if (_in(x, y, 4, 192, 116, 20)) return const StartPick(StartPickKind.restart);
  if (_in(x, y, 161, 192, 76, 20)) return const StartPick(StartPickKind.turnOff);
  return StartPick.none;
}
