// What a click on XP's Start menu on the device picks (R-DK-22); worked out by domain/rules/start_rules.dart.

/// Screens of the app the right column of Start opens on the phone (the app is the computer).
enum AppScreen { details, settings, skills, device }

enum StartPickKind {
  /// Empty space inside Start: nothing.
  none,

  /// A program (left column / All Programs sub-menu): [StartPick.program] opens.
  program,

  /// Tất cả chương trình: its sub-menu opens / closes.
  toggleAll,

  /// Desktop: every window down (XP "Show desktop").
  desktop,

  /// Số liệu / Cài đặt / Thêm / gỡ / Thiết bị: [StartPick.screen] opens on the phone.
  appScreen,

  /// Khởi động lại (asked again first).
  restart,

  /// Tắt màn: the power button, off (R-DK-20).
  turnOff,

  /// Outside Start (or on the start button again): Start closes.
  close,
}

class StartPick {
  const StartPick(this.kind, {this.program, this.screen});

  static const none = StartPick(StartPickKind.none);

  final StartPickKind kind;
  final String? program;
  final AppScreen? screen;

  @override
  bool operator ==(Object other) =>
      other is StartPick && other.kind == kind && other.program == program && other.screen == screen;

  @override
  int get hashCode => Object.hash(kind, program, screen);

  @override
  String toString() => 'StartPick(${kind.name}, $program, $screen)';
}
