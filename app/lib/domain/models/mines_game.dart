// Dò mìn (R-DK-23, panel P-2026-11-27.25): the game the app keeps — the device only draws the board it is sent
// (firmware src/data/mines_core.h). Rules in domain/rules/mines_rules.dart.

enum MinesStatus {
  /// No click yet: the mines are not placed (the first click is never a mine).
  ready,
  playing,
  won,
  lost,
}

/// A game of Beginner Minesweeper (9 × 9, 10 mines); cell (c, r) = index 9r + c.
class MinesGame {
  const MinesGame({
    this.mines = const {},
    this.opened = const {},
    this.flags = const {},
    this.status = MinesStatus.ready,
    this.blast,
    this.startedAt,
    this.endedAt,
  });

  static const cols = 9, rows = 9, cells = 81, mineCount = 10;

  /// A new game (also the face's click).
  static const fresh = MinesGame();

  final Set<int> mines, opened, flags;
  final MinesStatus status;

  /// The mine clicked on a loss.
  final int? blast;

  /// The first click (the clock starts); the end of the game (it stops).
  final DateTime? startedAt, endedAt;

  bool get over => status == MinesStatus.won || status == MinesStatus.lost;

  MinesGame copyWith({
    Set<int>? mines,
    Set<int>? opened,
    Set<int>? flags,
    MinesStatus? status,
    int? blast,
    DateTime? startedAt,
    DateTime? endedAt,
  }) => MinesGame(
    mines: mines ?? this.mines,
    opened: opened ?? this.opened,
    flags: flags ?? this.flags,
    status: status ?? this.status,
    blast: blast ?? this.blast,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
  );
}
