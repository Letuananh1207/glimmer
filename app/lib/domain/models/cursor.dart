// The app as the computer's hardware (plan docs/tasks/2026-11-27-app-la-chuot-ban-phim-nguon.md): the mouse pointer,
// the control keys and the power button. R-DK-17…20. Worked out by domain/rules/cursor_rules.dart and
// keyboard_rules.dart.

/// Shape of the pointer, drawn by the device (firmware `CursorCore::Shape`, same numbers).
enum CursorShape { none, arrow, hand, wait }

/// The pointer: hotspot in device pixels (0…239 each way, kept as a fraction so slow moves still add up) + shape.
class Cursor {
  const Cursor({this.x = 120, this.y = 120, this.shape = CursorShape.arrow});

  /// Where a fresh app puts it: the middle of the screen (R-DK-17).
  static const home = Cursor();

  final double x, y;
  final CursorShape shape;

  /// Device pixel under the hotspot.
  int get px => x.floor().clamp(0, 239);
  int get py => y.floor().clamp(0, 239);

  Cursor copyWith({double? x, double? y, CursorShape? shape}) =>
      Cursor(x: x ?? this.x, y: y ?? this.y, shape: shape ?? this.shape);

  @override
  bool operator ==(Object other) => other is Cursor && other.x == x && other.y == y && other.shape == shape;

  @override
  int get hashCode => Object.hash(x, y, shape);

  @override
  String toString() => 'Cursor($x, $y, ${shape.name})';
}

/// The control keys (R-DK-19). Typing text comes later.
enum ControlKey { windows, altTab, altF4, up, down, left, right, enter, escape, tab }

/// The "computer" (R-DK-20), from `/api/state` `power`.
enum PowerState {
  on,
  shutting,
  off,
  booting;

  static PowerState? fromName(Object? v) => switch (v) {
    'on' => on,
    'shutting' => shutting,
    'off' => off,
    'booting' => booting,
    _ => null,
  };

  /// Pointer and keys do something only while the computer is on.
  bool get running => this == on;
}
