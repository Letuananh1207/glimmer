// Máy tính bỏ túi (R-DK-27, panel P-2026-11-28.31): the app keeps the arithmetic, the device draws.

/// The keys of the device's Calculator, in the firmware's order (`src/data/calc_core.h`): the 6 × 4 grid row by
/// row, then Backspace, CE, C.
enum CalcKey {
  mc, d7, d8, d9, div, sqrt, //
  mr, d4, d5, d6, mul, percent, //
  ms, d1, d2, d3, sub, inverse, //
  mPlus, d0, negate, point, add, equals, //
  back, ce, c,
}

/// The four operations of XP Standard (left to right, no precedence).
enum CalcOp { add, sub, mul, div }

/// XP Standard's state: what shows, what waits, the memory.
class CalcState {
  const CalcState({
    this.entry,
    this.value = 0,
    this.acc = 0,
    this.op,
    this.lastOp,
    this.lastOperand = 0,
    this.memory = 0,
    this.error = false,
  });

  static const fresh = CalcState();

  /// The number being typed, as typed ("12", "0.", "-3.5"); null = not typing ([value] shows).
  final String? entry;

  /// The number on the display when not typing.
  final double value;

  /// The left side waiting for [op].
  final double acc;
  final CalcOp? op;

  /// `=` repeats [lastOp] with [lastOperand].
  final CalcOp? lastOp;
  final double lastOperand;

  final double memory;

  /// "Không thể chia cho 0." shows; only C / CE leave it.
  final bool error;

  /// The number on screen.
  double get shown {
    final e = entry;
    if (e == null) return value;
    return double.parse(e.endsWith('.') ? '${e}0' : e);
  }

  CalcState copyWith({
    String? entry,
    bool clearEntry = false,
    double? value,
    double? acc,
    CalcOp? op,
    bool clearOp = false,
    CalcOp? lastOp,
    double? lastOperand,
    double? memory,
  }) =>
      CalcState(
        entry: clearEntry ? null : entry ?? this.entry,
        value: value ?? this.value,
        acc: acc ?? this.acc,
        op: clearOp ? null : op ?? this.op,
        lastOp: lastOp ?? this.lastOp,
        lastOperand: lastOperand ?? this.lastOperand,
        memory: memory ?? this.memory,
        error: error,
      );
}
