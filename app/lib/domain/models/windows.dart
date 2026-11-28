// Open windows of the device screen, kept by the app (R-DK-7/8, design 2026-11-26.6 / .7; panel P-2026-11-26.14):
// the app is the computer, the device is its screen. A window = a program (a device channel such as "Claude").

/// Windows in the order they were opened (= taskbar order, as XP: activating a window never moves its button), the
/// activation order ([z], top-most last: who comes back when one closes), the one on top (null = the desktop
/// shows), the minimized ones, and the selected desktop icon ([sel], e.g. a skill just installed).
class WindowStack {
  const WindowStack({this.open = const [], this.z = const [], this.top, this.minimized = const {}, this.sel});

  static const empty = WindowStack();

  final List<String> open;
  final List<String> z;
  final String? top;
  final Set<String> minimized;
  final String? sel;

  bool isOpen(String program) => open.contains(program);

  WindowStack _copy({List<String>? open, List<String>? z, String? top, Set<String>? minimized, String? sel}) =>
      WindowStack(open: open ?? this.open, z: z ?? this.z, top: top, minimized: minimized ?? this.minimized, sel: sel);

  /// [program] comes to the top (opened, restored or already there); its taskbar button keeps its place.
  WindowStack opened(String program) => _copy(
    open: isOpen(program) ? open : [...open, program],
    z: [...z.where((p) => p != program), program],
    top: program,
    minimized: {...minimized}..remove(program),
  );

  /// `_`: [program] leaves the screen (bottom of the activation order), keeps its taskbar button; the desktop shows.
  WindowStack minimize(String program) {
    if (!isOpen(program)) return this;
    return _copy(
      z: [program, ...z.where((p) => p != program)],
      top: top == program ? null : top,
      minimized: {...minimized, program},
      sel: sel,
    );
  }

  /// Start → Desktop (XP "Show desktop"): every window minimized.
  WindowStack minimizeAll() => _copy(minimized: {...open}, sel: sel);

  /// `×`: [program] is gone; the most recently active window that is not minimized comes up, none → the desktop.
  WindowStack close(String program) {
    final rest = [...open.where((p) => p != program)];
    final order = [...z.where((p) => p != program)];
    final mins = {...minimized}..remove(program);
    String? next = top == program ? null : top;
    if (top == program || top == null) {
      for (final p in order.reversed) {
        if (!mins.contains(p)) {
          next = p;
          break;
        }
      }
    }
    return WindowStack(open: rest, z: order, top: next, minimized: mins, sel: sel);
  }

  /// Desktop icon [program] selected (null = none).
  WindowStack select(String? program) => _copy(top: top, sel: program);

  /// Only the windows [keep] accepts (R-DK-9: a skill turned off takes its windows with it).
  WindowStack only(bool Function(String program) keep) => WindowStack(
    open: [...open.where(keep)],
    z: [...z.where(keep)],
    top: top != null && keep(top!) ? top : null,
    minimized: {...minimized.where(keep)},
    sel: sel != null && keep(sel!) ? sel : null,
  );

  /// The device's windows (`/api/state` `windows {open, top, min, sel}`) when the device keeps them (R-DK-30: input
  /// stage ≥ 1). It does not report its activation order: opening order, the top one last.
  factory WindowStack.fromDevice(Map<String, dynamic> j) {
    final open = [...(j['open'] as List? ?? const []).whereType<String>()];
    final top = j['top'] is String ? j['top'] as String : null;
    return WindowStack(
      open: open,
      z: [...open.where((p) => p != top), ?top],
      top: top,
      minimized: {...(j['min'] as List? ?? const []).whereType<String>()},
      sel: j['sel'] is String ? j['sel'] as String : null,
    );
  }

  /// `POST /api/windows` body (panel P-2026-11-26.14).
  Map<String, Object?> toJson() => {
    'open': open,
    'top': top,
    'min': [...minimized],
    'sel': sel,
  };

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is WindowStack &&
      other.top == top &&
      other.sel == sel &&
      _sameList(other.open, open) &&
      _sameList(other.z, z) &&
      other.minimized.length == minimized.length &&
      other.minimized.containsAll(minimized);

  @override
  int get hashCode =>
      Object.hash(top, sel, Object.hashAll(open), Object.hashAll(z), Object.hashAllUnordered(minimized));

  @override
  String toString() => 'WindowStack(open: $open, z: $z, top: $top, minimized: $minimized, sel: $sel)';
}
