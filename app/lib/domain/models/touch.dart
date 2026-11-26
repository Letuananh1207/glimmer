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
