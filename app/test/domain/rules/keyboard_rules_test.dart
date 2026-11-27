import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/cursor.dart';
import 'package:glimmer_app/domain/models/touch.dart';
import 'package:glimmer_app/domain/models/windows.dart';
import 'package:glimmer_app/domain/rules/keyboard_rules.dart';

const _icons = ['Claude', 'Codex', 'Photo'];

KeyAction _k(
  ControlKey key, {
  WindowStack windows = WindowStack.empty,
  String channel = 'Home',
  String? shown,
  MenuView? menu,
  MenuItem? lit,
  bool start = false,
}) => keyAction(
  key,
  windows: windows,
  channel: channel,
  shownWindow: shown,
  menu: menu,
  lit: lit,
  startOpen: start,
  deskPrograms: _icons,
);

void main() {
  group('R-DK-19 desktop', () {
    test('Claude selected, ↓ → Codex; Enter → opens it', () {
      final w = WindowStack.empty.select('Claude');
      expect(_k(ControlKey.down, windows: w), const KeyAction(KeyActionKind.select, program: 'Codex'));
      expect(
        _k(ControlKey.enter, windows: w.select('Codex')),
        const KeyAction(KeyActionKind.open, program: 'Codex'),
      );
    });

    test('nothing selected → the first icon; the ends stop (XP)', () {
      expect(_k(ControlKey.down), const KeyAction(KeyActionKind.select, program: 'Claude'));
      expect(_k(ControlKey.up), const KeyAction(KeyActionKind.select, program: 'Claude'));
      final last = WindowStack.empty.select('Photo');
      expect(_k(ControlKey.down, windows: last), const KeyAction(KeyActionKind.select, program: 'Photo'));
      expect(_k(ControlKey.tab, windows: last), const KeyAction(KeyActionKind.select, program: 'Photo'));
      expect(_k(ControlKey.enter), KeyAction.none);
    });
  });

  group('R-DK-19 windows', () {
    final two = WindowStack.empty.opened('Claude').opened('Weather');

    test('Alt+Tab → the next open window, round', () {
      expect(
        _k(ControlKey.altTab, windows: two, channel: 'Weather', shown: 'Weather'),
        const KeyAction(KeyActionKind.open, program: 'Claude'),
      );
      expect(
        _k(ControlKey.altTab, windows: two, channel: 'Claude', shown: 'Claude'),
        const KeyAction(KeyActionKind.open, program: 'Weather'),
      );
      // From the desktop (all minimized): the first one.
      expect(_k(ControlKey.altTab, windows: two.minimizeAll()), const KeyAction(KeyActionKind.open, program: 'Claude'));
      // The only window already on screen: nothing.
      final one = WindowStack.empty.opened('Claude');
      expect(_k(ControlKey.altTab, windows: one, channel: 'Claude', shown: 'Claude'), KeyAction.none);
      expect(_k(ControlKey.altTab), KeyAction.none);
    });

    test('Alt+F4 closes the window on top; on the desktop nothing', () {
      expect(
        _k(ControlKey.altF4, windows: two, channel: 'Weather', shown: 'Weather'),
        const KeyAction(KeyActionKind.closeTop),
      );
      expect(_k(ControlKey.altF4, windows: two.minimizeAll()), KeyAction.none);
    });

    test('Windows toggles Start; Esc closes it, else nothing', () {
      expect(_k(ControlKey.windows), const KeyAction(KeyActionKind.toggleStart));
      expect(_k(ControlKey.escape, start: true), const KeyAction(KeyActionKind.closeMenu));
      expect(_k(ControlKey.escape), KeyAction.none);
      expect(_k(ControlKey.down, start: true), KeyAction.none); // Start's lit item: panel design
    });
  });

  group('R-DK-19 menus', () {
    const win = MenuView(MenuKind.window, 71, 100, program: 'Claude');

    test('↓ lights the next usable item (dim ones skipped), round; ↑ back', () {
      // Window menu of a shown window: Thu nhỏ and Đóng are usable.
      expect(_k(ControlKey.down, menu: win), const KeyAction(KeyActionKind.hover, item: MenuItem.minimize));
      expect(
        _k(ControlKey.down, menu: win, lit: MenuItem.minimize),
        const KeyAction(KeyActionKind.hover, item: MenuItem.close),
      );
      expect(
        _k(ControlKey.down, menu: win, lit: MenuItem.close),
        const KeyAction(KeyActionKind.hover, item: MenuItem.minimize),
      );
      expect(_k(ControlKey.up, menu: win), const KeyAction(KeyActionKind.hover, item: MenuItem.close));
    });

    test('Enter chooses the lit item; Esc closes the menu', () {
      expect(
        _k(ControlKey.enter, menu: win, lit: MenuItem.close),
        const KeyAction(KeyActionKind.choose, item: MenuItem.close),
      );
      expect(_k(ControlKey.enter, menu: win), KeyAction.none);
      expect(_k(ControlKey.escape, menu: win), const KeyAction(KeyActionKind.closeMenu));
    });
  });
}
