// Máy tính bỏ túi (R-DK-27, panel P-2026-11-28.31): XP Standard's arithmetic and the device's key layout
// (`src/data/calc_core.h`).
import 'dart:math' as math;

import '../models/calc_state.dart';

/// R-DK-27: characters on the display.
const calcDisplayMax = 16;

/// R-DK-27: the key under device pixel ([x], [y]) of the Calculator window, null = none (calc_core.h `keyAt`).
CalcKey? calcKeyAt(int x, int y) {
  bool inBox(int bx, int by, int w, int h) => x >= bx && x < bx + w && y >= by && y < by + h;
  if (inBox(46, 56, 76, 24)) return CalcKey.back;
  if (inBox(126, 56, 52, 24)) return CalcKey.ce;
  if (inBox(182, 56, 50, 24)) return CalcKey.c;
  for (var k = 0; k < 24; k++) {
    if (inBox(8 + 38 * (k % 6), 86 + 30 * (k ~/ 6), 34, 26)) return CalcKey.values[k];
  }
  return null;
}

const _digits = {
  CalcKey.d0: '0', CalcKey.d1: '1', CalcKey.d2: '2', CalcKey.d3: '3', CalcKey.d4: '4', //
  CalcKey.d5: '5', CalcKey.d6: '6', CalcKey.d7: '7', CalcKey.d8: '8', CalcKey.d9: '9',
};
const _ops = {CalcKey.add: CalcOp.add, CalcKey.sub: CalcOp.sub, CalcKey.mul: CalcOp.mul, CalcKey.div: CalcOp.div};

/// R-DK-27: [s] after key [k], as XP's Calculator (Standard view).
CalcState calcPress(CalcState s, CalcKey k) {
  if (s.error) return k == CalcKey.c || k == CalcKey.ce ? CalcState(memory: s.memory) : s;
  final digit = _digits[k];
  if (digit != null) return _type(s, digit);
  final op = _ops[k];
  if (op != null) return _operator(s, op);
  switch (k) {
    case CalcKey.point:
      final e = s.entry;
      if (e == null) return s.copyWith(entry: '0.');
      return e.contains('.') ? s : s.copyWith(entry: '$e.');
    case CalcKey.equals:
      return _equals(s);
    case CalcKey.percent:
      return _show(s, s.op == null ? 0 : s.acc * s.shown / 100);
    case CalcKey.sqrt:
      return s.shown < 0 ? s : _show(s, math.sqrt(s.shown));
    case CalcKey.inverse:
      return s.shown == 0 ? _error(s) : _show(s, 1 / s.shown);
    case CalcKey.negate:
      final e = s.entry;
      if (e == null) return s.copyWith(value: -s.value);
      if (e == '0') return s;
      return s.copyWith(entry: e.startsWith('-') ? e.substring(1) : '-$e');
    case CalcKey.back:
      final e = s.entry;
      if (e == null) return s;
      final cut = e.substring(0, e.length - 1);
      return s.copyWith(entry: cut.isEmpty || cut == '-' ? '0' : cut);
    case CalcKey.ce:
      return s.copyWith(clearEntry: true, value: 0);
    case CalcKey.c:
      return CalcState(memory: s.memory);
    case CalcKey.mc:
      return s.copyWith(memory: 0);
    case CalcKey.mr:
      return _show(s, s.memory);
    case CalcKey.ms:
      return s.copyWith(memory: s.shown);
    case CalcKey.mPlus:
      return s.copyWith(memory: s.memory + s.shown);
    default:
      return s;
  }
}

/// A digit: a new number after an operation / result, else onto the one being typed (≤ 16 characters).
CalcState _type(CalcState s, String d) {
  final e = s.entry;
  if (e == null || e == '0') return s.copyWith(entry: d);
  if (e == '-0') return s.copyWith(entry: '-$d');
  final shownLen = e.length + (e.contains('.') ? 0 : 1);
  if (shownLen >= calcDisplayMax) return s;
  return s.copyWith(entry: '$e$d');
}

/// An operation: the one waiting is done first (left to right) when a number was typed / recalled since; pressed
/// twice in a row only the operation changes.
CalcState _operator(CalcState s, CalcOp op) {
  final x = s.shown;
  final waiting = s.op;
  if (waiting != null && s.entry == null) return s.copyWith(op: op);
  if (waiting != null) {
    final r = _apply(waiting, s.acc, x);
    if (r == null) return _error(s);
    return s.copyWith(clearEntry: true, value: r, acc: r, op: op);
  }
  return s.copyWith(clearEntry: true, value: x, acc: x, op: op);
}

/// `=`: the waiting operation with the number on screen; again → the last operation with the same number.
CalcState _equals(CalcState s) {
  final x = s.shown;
  final waiting = s.op;
  if (waiting != null) {
    final r = _apply(waiting, s.acc, x);
    if (r == null) return _error(s);
    return s.copyWith(clearEntry: true, value: r, acc: r, clearOp: true, lastOp: waiting, lastOperand: x);
  }
  final last = s.lastOp;
  if (last == null) return s.copyWith(clearEntry: true, value: x);
  final r = _apply(last, x, s.lastOperand);
  if (r == null) return _error(s);
  return s.copyWith(clearEntry: true, value: r, acc: r);
}

double? _apply(CalcOp op, double a, double b) => switch (op) {
      CalcOp.add => a + b,
      CalcOp.sub => a - b,
      CalcOp.mul => a * b,
      CalcOp.div => b == 0 ? null : a / b,
    };

/// A result of a function (%, sqrt, 1/x, MR) on screen; it counts as a typed number for the next operation.
CalcState _show(CalcState s, double v) {
  final t = calcText(v);
  return s.copyWith(entry: t.endsWith('.') ? t.substring(0, t.length - 1) : t, value: v);
}

CalcState _error(CalcState s) => CalcState(memory: s.memory, error: true);

/// R-DK-27: what the display shows for [s] — XP puts a "." after a whole number ("0.", "12.").
String calcDisplay(CalcState s) {
  final e = s.entry;
  if (e != null) return e.contains('.') ? e : '$e.';
  return calcText(s.value);
}

/// [v] in ≤ 16 characters: whole numbers "12.", others with up to 15 significant digits, huge / tiny ones as
/// "1.5e+20".
String calcText(double v) {
  if (v.isNaN || v.isInfinite) return '0.';
  if (v == 0) return '0.';
  if (v == v.truncateToDouble() && v.abs() < 1e15) return '${v.toInt()}.';
  for (var p = 15; p >= 1; p--) {
    var t = v.toStringAsPrecision(p);
    if (t.contains('e')) {
      final parts = t.split('e');
      var m = parts[0];
      if (m.contains('.')) m = m.replaceFirst(RegExp(r'0+$'), '');
      t = '${m.contains('.') ? m : '$m.'}e${parts[1]}';
    } else if (t.contains('.')) {
      t = t.replaceFirst(RegExp(r'0+$'), '');
    }
    if (t.length <= calcDisplayMax) return t;
  }
  return v.toStringAsExponential(0);
}

/// R-DK-27: `POST /api/calc` — the display, the error, the memory cell, the key held down (index, −1 none).
Map<String, Object?> calcBody(CalcState s, {CalcKey? down}) => {
      'display': calcDisplay(s),
      'error': s.error,
      'mem': s.memory != 0,
      'down': down?.index ?? -1,
    };
