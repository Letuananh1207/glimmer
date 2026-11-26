// What a touch on the device screen hits (design 2026-11-26.6, R-DK-8), and the groups of installed programs.
// Worked out by domain/rules/touch_rules.dart and control_rules.dart.

/// What a touch hits.
enum TouchKind { none, minimize, maximize, close, start, taskbar, icon }

class TouchTarget {
  const TouchTarget(this.kind, {this.skill, this.program});

  static const none = TouchTarget(TouchKind.none);

  final TouchKind kind;

  /// Skill of a taskbar button.
  final String? skill;

  /// Program of a desktop icon.
  final String? program;

  @override
  bool operator ==(Object other) =>
      other is TouchTarget && other.kind == kind && other.skill == skill && other.program == program;

  @override
  int get hashCode => Object.hash(kind, skill, program);

  @override
  String toString() => 'TouchTarget($kind${skill == null ? '' : ', $skill'}${program == null ? '' : ', $program'})';
}

/// A group of Tất cả chương trình (AllProgramsSheet).
enum ProgramGroup { agent, other, system }

/// Context menus of the device screen (panel P-2026-11-26.14 XP-Menu), opened by holding on the app.
enum MenuKind { desktop, window }

/// Items, in screen order; separators are not items. Arrow items ([arrange], [newItem]) open sub-menus not drawn yet.
enum MenuItem {
  arrange,
  refresh,
  paste,
  pasteShortcut,
  newItem,
  properties,
  restore,
  move,
  size,
  minimize,
  maximize,
  close,
}

/// A context menu on screen: [kind], top-left ([x], [y], already kept inside y ≤ 213), the window it belongs to
/// ([program], window menus) and whether that window is minimized (Khôi phục lit, Thu nhỏ dim).
class MenuView {
  const MenuView(this.kind, this.x, this.y, {this.program, this.minimized = false});

  final MenuKind kind;
  final int x, y;
  final String? program;
  final bool minimized;

  /// Sizes from the sources: 1-px border + 1-px pad, items 17, separators 7.
  static const itemH = 17, sepH = 7, pad = 2;
  int get width => kind == MenuKind.desktop ? 166 : 128;
  int get height => kind == MenuKind.desktop ? 2 * pad + 6 * itemH + 3 * sepH : 2 * pad + 6 * itemH + sepH;

  /// Rows top to bottom: an item, or null for a separator.
  List<MenuItem?> get rows => kind == MenuKind.desktop
      ? const [
          MenuItem.arrange, MenuItem.refresh, null, MenuItem.paste, MenuItem.pasteShortcut, null, //
          MenuItem.newItem, null, MenuItem.properties,
        ]
      : const [
          MenuItem.restore, MenuItem.move, MenuItem.size, MenuItem.minimize, MenuItem.maximize, null, //
          MenuItem.close,
        ];

  /// Lit (usable) items; the rest are drawn dim and do nothing.
  bool enabled(MenuItem i) => switch (i) {
    MenuItem.arrange || MenuItem.refresh || MenuItem.properties || MenuItem.close => true,
    MenuItem.restore => minimized,
    MenuItem.minimize => !minimized,
    _ => false,
  };

  /// `POST /api/menu` body.
  Map<String, Object?> toJson() => {'kind': kind.name, 'x': x, 'y': y, 'minimized': minimized};

  @override
  bool operator ==(Object other) =>
      other is MenuView &&
      other.kind == kind &&
      other.x == x &&
      other.y == y &&
      other.program == program &&
      other.minimized == minimized;

  @override
  int get hashCode => Object.hash(kind, x, y, program, minimized);
}
