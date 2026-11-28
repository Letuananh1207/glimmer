// The control keys (R-DK-19): what a key does, given what is on the device screen. The ViewModel carries it out
// with the same commands as clicks (R-DK-7…16). Typing text comes later.
import '../models/cursor.dart';
import '../models/touch.dart';
import '../models/windows.dart';

enum KeyActionKind {
  none,

  /// Windows: Start opens / closes (R-DK-15).
  toggleStart,

  /// Esc: the open menu / Start closes.
  closeMenu,

  /// Alt+Tab → [KeyAction.program] comes to the top; Enter on a desktop icon → it opens.
  open,

  /// Alt+F4: the window on top closes (as `×`).
  closeTop,

  /// ↑ ↓ Tab in a menu: [KeyAction.item] is lit.
  hover,

  /// Enter in a menu: [KeyAction.item] is chosen.
  choose,

  /// Arrows / Tab on the desktop: icon [KeyAction.program] is selected.
  select,
}

class KeyAction {
  const KeyAction(this.kind, {this.program, this.item});

  static const none = KeyAction(KeyActionKind.none);

  final KeyActionKind kind;
  final String? program;
  final MenuItem? item;

  @override
  bool operator ==(Object other) =>
      other is KeyAction && other.kind == kind && other.program == program && other.item == item;

  @override
  int get hashCode => Object.hash(kind, program, item);

  @override
  String toString() => 'KeyAction(${kind.name}, $program, $item)';
}

/// What [key] does. [channel] is on the device screen; [shownWindow] = the program window on it (null = desktop,
/// card…); [menu] is the open context menu with item [lit]; [startOpen] = Start is open; [deskPrograms] = the desktop
/// icons top to bottom.
KeyAction keyAction(
  ControlKey key, {
  required WindowStack windows,
  required String channel,
  String? shownWindow,
  MenuView? menu,
  MenuItem? lit,
  bool startOpen = false,
  List<String> deskPrograms = const [],
}) {
  switch (key) {
    case ControlKey.windows:
      return const KeyAction(KeyActionKind.toggleStart);
    case ControlKey.escape:
      return menu != null || startOpen ? const KeyAction(KeyActionKind.closeMenu) : KeyAction.none;
    case ControlKey.altF4:
      return shownWindow != null ? const KeyAction(KeyActionKind.closeTop) : KeyAction.none;
    case ControlKey.altTab:
      final next = _nextWindow(windows, shownWindow);
      return next == null ? KeyAction.none : KeyAction(KeyActionKind.open, program: next);
    default:
      break;
  }
  if (menu != null) return _inMenu(key, menu, lit);
  if (startOpen) return KeyAction.none; // Start's own lit item waits for the panel design
  if (channel == 'Home') return _onDesktop(key, windows.sel, deskPrograms);
  return KeyAction.none;
}

/// The window after the one on screen in opening (taskbar) order, round; minimized ones too. Nothing when the only
/// open window is already on screen.
String? _nextWindow(WindowStack w, String? shown) {
  if (w.open.isEmpty) return null;
  final i = shown == null ? -1 : w.open.indexOf(shown);
  final next = w.open[(i + 1) % w.open.length];
  return next == shown ? null : next;
}

KeyAction _inMenu(ControlKey key, MenuView menu, MenuItem? lit) {
  final items = menu.rows.whereType<MenuItem>().where(menu.enabled).toList();
  if (items.isEmpty) return KeyAction.none;
  final i = lit == null ? -1 : items.indexOf(lit);
  switch (key) {
    case ControlKey.down || ControlKey.tab:
      return KeyAction(KeyActionKind.hover, item: items[(i + 1) % items.length]);
    case ControlKey.up:
      return KeyAction(KeyActionKind.hover, item: items[i <= 0 ? items.length - 1 : i - 1]);
    case ControlKey.enter:
      return lit != null && menu.enabled(lit) ? KeyAction(KeyActionKind.choose, item: lit) : KeyAction.none;
    default:
      return KeyAction.none;
  }
}

/// XP's desktop: arrows move the selection one icon and stop at the ends; nothing selected → the first.
KeyAction _onDesktop(ControlKey key, String? sel, List<String> icons) {
  if (icons.isEmpty) return KeyAction.none;
  final i = sel == null ? -1 : icons.indexOf(sel);
  switch (key) {
    case ControlKey.down || ControlKey.right || ControlKey.tab:
      return KeyAction(KeyActionKind.select, program: icons[i < 0 ? 0 : (i + 1).clamp(0, icons.length - 1)]);
    case ControlKey.up || ControlKey.left:
      return KeyAction(KeyActionKind.select, program: icons[i <= 0 ? 0 : i - 1]);
    case ControlKey.enter:
      return sel != null && icons.contains(sel) ? KeyAction(KeyActionKind.open, program: sel) : KeyAction.none;
    default:
      return KeyAction.none;
  }
}
