import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/cursor.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/models/mirror_frame.dart';
import 'package:glimmer_app/domain/models/touch.dart';
import 'package:glimmer_app/domain/models/windows.dart';
import 'package:glimmer_app/domain/rules/cursor_rules.dart';
import 'package:glimmer_app/domain/rules/mirror_rules.dart';

MirrorFrame _frame(String channel) => mirrorFrameOf(
  DeviceState.fromJson({
    'fw': '1.0',
    'wifi': 'connected',
    'active_channel': channel,
    'skills_on': ['agent', 'weather', 'clock'],
  }),
  now: DateTime(2026, 11, 27),
  windows: WindowStack.empty,
);

void main() {
  group('R-DK-17 pointer moves', () {
    test('a fresh app puts it in the middle', () {
      expect(Cursor.home.px, 120);
      expect(Cursor.home.py, 120);
      expect(Cursor.home.shape, CursorShape.arrow);
    });

    test('kept on the screen: (230, 100) + 40 to the right → (239, 100)', () {
      final c = moveCursor(const Cursor(x: 230, y: 100), 40, 0, const Duration(milliseconds: 16));
      expect(c.px, 239);
      expect(c.py, 100);
      final d = moveCursor(const Cursor(x: 3, y: 3), -50, -50, const Duration(milliseconds: 16));
      expect((d.px, d.py), (0, 0));
    });

    test('a quick swipe goes further than the same distance slowly', () {
      final slow = moveCursor(Cursor.home, 10, 0, const Duration(milliseconds: 100));
      final fast = moveCursor(Cursor.home, 10, 0, const Duration(milliseconds: 5));
      expect(fast.x - 120, greaterThan(slow.x - 120));
      expect(slow.x - 120, closeTo(10 * cursorGain, 0.7)); // slow ≈ the resting gain
    });

    test('slow moves add up as fractions', () {
      var c = Cursor.home;
      for (var i = 0; i < 4; i++) {
        c = moveCursor(c, 0.6, 0, const Duration(milliseconds: 50));
      }
      expect(c.px, 121);
    });
  });

  group('R-DK-17 pointer shape', () {
    test('hand over the × of a window, arrow over its body, hourglass while waiting', () {
      final f = _frame('Claude');
      expect(cursorShapeAt(const Cursor(x: 228, y: 11), f), CursorShape.hand);
      expect(cursorShapeAt(const Cursor(x: 120, y: 120), f), CursorShape.arrow);
      expect(cursorShapeAt(const Cursor(x: 228, y: 11), f, waiting: true), CursorShape.wait);
      expect(cursorShapeAt(const Cursor(x: 120, y: 120), f, overTarget: true), CursorShape.hand);
    });

    test('in a menu: hand on a lit item, arrow on a dim one', () {
      const m = MenuView(MenuKind.window, 71, 100, program: 'Claude');
      // Rows from y 102: Khôi phục (dim unless minimized) 102–118, …, Đóng after the separator.
      expect(cursorShapeAt(const Cursor(x: 100, y: 108), null, menu: m), CursorShape.arrow);
      expect(cursorShapeAt(const Cursor(x: 100, y: 102 + 5 * 17 + 7 + 5), null, menu: m), CursorShape.hand);
    });
  });

  group('R-DK-18 menu hover index', () {
    test('items counted without separators, as the firmware', () {
      const desk = MenuView(MenuKind.desktop, 10, 10);
      expect(menuHoverIndex(desk, MenuItem.properties), 5);
      expect(menuHoverIndex(desk, MenuItem.paste), 2);
      const win = MenuView(MenuKind.window, 10, 10, program: 'Claude');
      expect(menuHoverIndex(win, MenuItem.close), 5);
      expect(menuHoverIndex(win, null), -1);
    });
  });

  group('R-DK-17 datagram', () {
    test("'G' 'C' 1 shape seq16 x y, as firmware cursor_core.h", () {
      final p = cursorPacket(0xBEEF, const Cursor(x: 239.7, y: 0.2, shape: CursorShape.hand));
      expect(p, [0x47, 0x43, 1, 2, 0xBE, 0xEF, 239, 0]);
      expect(cursorPacket(0x10005, Cursor.home)[4], 0x00); // 16 bits
    });
  });
}
