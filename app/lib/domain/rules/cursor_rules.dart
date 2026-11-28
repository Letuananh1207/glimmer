// The mouse pointer (R-DK-17, R-DK-18): moving it from the trackpad, its shape over what is under it, and the UDP
// datagram the device draws it from (firmware src/data/cursor_core.h — keep the two in step).
import 'dart:math' as math;
import 'dart:typed_data';

import '../models/cursor.dart';
import '../models/mirror_frame.dart';
import '../models/touch.dart';
import 'touch_rules.dart';

/// Last device pixel each way.
const cursorMax = 239.0;

/// Device pixels per dp of finger travel at rest, how much a quick swipe adds, and the speed (dp per ms) past which
/// it adds no more: a slow drag aims, a flick crosses the screen (R-DK-17).
const cursorGain = 0.5, cursorAccel = 1.2, cursorFastDpPerMs = 2.0;

/// The pointer after the finger moved ([dx], [dy]) dp in [dt]; kept on the screen.
Cursor moveCursor(Cursor c, double dx, double dy, Duration dt) {
  final ms = math.max(dt.inMicroseconds / 1000, 1.0);
  final speed = math.min(math.sqrt(dx * dx + dy * dy) / ms, cursorFastDpPerMs);
  final gain = cursorGain * (1 + cursorAccel * speed);
  return c.copyWith(x: (c.x + dx * gain).clamp(0.0, cursorMax), y: (c.y + dy * gain).clamp(0.0, cursorMax));
}

/// R-DK-17: the hourglass while a window is opening ([waiting]); the hand over something that does something when
/// clicked — a lit item of the open [menu], or a target of [frame] ([overTarget] adds targets the caller knows, e.g.
/// the Clock window's); the arrow elsewhere.
CursorShape cursorShapeAt(
  Cursor c,
  MirrorFrame? frame, {
  MenuView? menu,
  bool waiting = false,
  bool overTarget = false,
}) {
  if (waiting) return CursorShape.wait;
  if (overTarget) return CursorShape.hand;
  final x = c.px.toDouble(), y = c.py.toDouble();
  if (menu != null) {
    final item = menuContains(menu, x, y) ? menuItemAt(menu, x, y) : null;
    return item != null && menu.enabled(item) ? CursorShape.hand : CursorShape.arrow;
  }
  if (frame == null) return CursorShape.arrow;
  return touchTargetAt(x, y, frame).kind == TouchKind.none ? CursorShape.arrow : CursorShape.hand;
}

/// R-DK-18: index of [item] among [menu]'s items, separators not counted (the firmware's `hover`); -1 = none.
int menuHoverIndex(MenuView menu, MenuItem? item) =>
    item == null ? -1 : menu.rows.whereType<MenuItem>().toList().indexOf(item);

/// The datagram: 'G' 'C' version 1, shape, sequence (16 bits, big-endian), x, y.
Uint8List cursorPacket(int seq, Cursor c) =>
    Uint8List.fromList([0x47, 0x43, 1, c.shape.index, (seq >> 8) & 0xFF, seq & 0xFF, c.px, c.py]);
