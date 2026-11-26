// Open windows of the device screen, kept by the app (R-DK-7/8, design 2026-11-26.6): the app is the computer, the
// device is its screen. A window = a program (a device channel such as "Claude", "Weather").

/// Windows in the order they were opened, the one on top (null = the desktop shows) and the minimized ones.
class WindowStack {
  const WindowStack({this.open = const [], this.top, this.minimized = const {}});

  static const empty = WindowStack();

  final List<String> open;
  final String? top;
  final Set<String> minimized;

  bool isOpen(String program) => open.contains(program);

  /// [program] comes to the top (opened, restored or already there).
  WindowStack opened(String program) => WindowStack(
    open: [...open.where((p) => p != program), program],
    top: program,
    minimized: {...minimized}..remove(program),
  );

  /// `_`: [program] leaves the screen, keeps its taskbar button; the desktop shows.
  WindowStack minimize(String program) {
    if (!isOpen(program)) return this;
    return WindowStack(open: open, top: null, minimized: {...minimized, program});
  }

  /// Start → Desktop (XP "Show desktop"): every window minimized.
  WindowStack minimizeAll() => WindowStack(open: open, top: null, minimized: {...open});

  /// `×`: [program] is gone; the window opened before it that is not minimized comes up, none → the desktop.
  WindowStack close(String program) {
    final rest = [...open.where((p) => p != program)];
    final mins = {...minimized}..remove(program);
    String? next;
    if (top == program || top == null) {
      for (final p in rest.reversed) {
        if (!mins.contains(p)) {
          next = p;
          break;
        }
      }
    } else {
      next = top;
    }
    return WindowStack(open: rest, top: next, minimized: mins);
  }

  /// Only the windows [keep] accepts (R-DK-9: a skill turned off takes its windows with it).
  WindowStack only(bool Function(String program) keep) {
    final rest = [...open.where(keep)];
    return WindowStack(
      open: rest,
      top: top != null && keep(top!) ? top : null,
      minimized: {...minimized.where(keep)},
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WindowStack &&
      other.top == top &&
      other.open.length == open.length &&
      [for (var i = 0; i < open.length; i++) other.open[i] == open[i]].every((b) => b) &&
      other.minimized.length == minimized.length &&
      other.minimized.containsAll(minimized);

  @override
  int get hashCode => Object.hash(top, Object.hashAll(open), Object.hashAllUnordered(minimized));

  @override
  String toString() => 'WindowStack(open: $open, top: $top, minimized: $minimized)';
}
