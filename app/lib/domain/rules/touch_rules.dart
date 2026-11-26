// Touches on the device screen (design 2026-11-26.6, R-DK-8): a point in device pixels (0…240) → what it hits on the
// XP screen the device shows. Geometry follows the firmware: window title bar buttons (`XP::window`, centres x 192 /
// 207 / 228, y 11), taskbar y 214–239 (`taskbar.cpp`: start x 0–67, one 28-px button per enabled skill from x 71,
// step 30), desktop icon column (`ch_home.cpp`: centre x 40, cells 48 tall from y 8).
import '../models/mirror_frame.dart';
import '../models/touch.dart';
import 'skill_rules.dart';

/// Half of the 44 × 44 dp hit box around a small target's centre, in device pixels at the mirror's 1.5 scale.
const touchReach = 44 / 1.5 / 2;

const _titleButtons = [(192, TouchKind.minimize), (207, TouchKind.maximize), (228, TouchKind.close)];
const _titleY = 11;
const _taskbarY = 214;
const _startRight = 68;
const _buttonX0 = 71, _buttonStep = 30, _buttonW = 28, _buttonCy = 227;
const _iconCx = 40, _iconHalfW = 40, _iconY0 = 8, _iconCell = 48;

/// Channels drawn as an XP window with the title bar buttons (not the desktop, the night face, cards, setup).
bool hasWindowButtons(String channel) =>
    !const {'Home', 'Night', 'Attention', 'Setup', MirrorFrame.setupScreen}.contains(channel);

/// What the point ([x], [y]) in device pixels hits on [frame].
TouchTarget touchTargetAt(double x, double y, MirrorFrame frame) {
  final ch = frame.channel;
  if (frame.screenOff || ch == 'Night' || ch == MirrorFrame.setupScreen) return TouchTarget.none;

  // Taskbar.
  if (y >= _buttonCy - touchReach) {
    if (y >= _taskbarY && x < _startRight) return const TouchTarget(TouchKind.start);
    final buttons = frame.taskbar.buttons;
    for (var i = 0; i < buttons.length; i++) {
      final cx = _buttonX0 + _buttonStep * i + _buttonW / 2;
      if ((x - cx).abs() <= _buttonStep / 2) {
        return TouchTarget(TouchKind.taskbar, skill: _skillOf(buttons[i]));
      }
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

  // Desktop icons.
  if (ch == 'Home' && (x - _iconCx).abs() <= _iconHalfW && y >= _iconY0) {
    final i = (y - _iconY0) ~/ _iconCell;
    final on = frame.state.skillsOn.isEmpty ? const [SkillIds.agent] : frame.state.skillsOn;
    final program = switch (i) {
      0 when on.contains(SkillIds.agent) => 'Claude',
      1 when on.contains(SkillIds.agent) => 'Codex',
      2 when on.contains(SkillIds.photo) => 'Photo',
      _ => null, // 3 = Thùng rác: nothing to open
    };
    if (program != null) return TouchTarget(TouchKind.icon, program: program);
  }
  return TouchTarget.none;
}

String _skillOf(TaskButton b) => switch (b) {
  TaskButton.claude => SkillIds.agent,
  TaskButton.photo => SkillIds.photo,
  TaskButton.weather => SkillIds.weather,
  TaskButton.clock => SkillIds.clock,
};
