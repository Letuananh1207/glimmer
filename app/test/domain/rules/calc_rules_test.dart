import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/calc_state.dart';
import 'package:glimmer_app/domain/rules/calc_rules.dart';

/// Presses keys written as on the Calculator: digits, ".", + - * /, =, %, "s" sqrt, "i" 1/x, "n" +/-, "b" Backspace,
/// "e" CE, "c" C, "M" MS, "R" MR, "P" M+, "X" MC.
CalcState press(String keys, [CalcState s = CalcState.fresh]) {
  const map = {
    '0': CalcKey.d0, '1': CalcKey.d1, '2': CalcKey.d2, '3': CalcKey.d3, '4': CalcKey.d4, //
    '5': CalcKey.d5, '6': CalcKey.d6, '7': CalcKey.d7, '8': CalcKey.d8, '9': CalcKey.d9,
    '.': CalcKey.point, '+': CalcKey.add, '-': CalcKey.sub, '*': CalcKey.mul, '/': CalcKey.div,
    '=': CalcKey.equals, '%': CalcKey.percent, 's': CalcKey.sqrt, 'i': CalcKey.inverse, 'n': CalcKey.negate,
    'b': CalcKey.back, 'e': CalcKey.ce, 'c': CalcKey.c, 'M': CalcKey.ms, 'R': CalcKey.mr, 'P': CalcKey.mPlus,
    'X': CalcKey.mc,
  };
  for (final ch in keys.split('')) {
    if (ch == ' ') continue;
    s = calcPress(s, map[ch]!);
  }
  return s;
}

String shows(String keys) => calcDisplay(press(keys));

void main() {
  group('R-DK-27 Máy tính bỏ túi (XP Standard)', () {
    test('starts at "0." ; whole numbers end with "."', () {
      expect(calcDisplay(CalcState.fresh), '0.');
      expect(shows('12'), '12.');
      expect(shows('1.5'), '1.5');
      expect(shows('.'), '0.');
      expect(shows('007'), '7.');
    });

    test('left to right, no precedence: 2 + 3 × 4 = 20', () {
      expect(shows('2+3*'), '5.');
      expect(shows('2+3*4='), '20.');
    });

    test('= repeats the last operation with the last number', () {
      expect(shows('2+3*4=='), '80.');
      expect(shows('10-3=='), '4.');
      expect(shows('5+='), '10.', reason: '"5 + =" uses the shown number');
    });

    test('an operation pressed twice only changes the operation', () {
      expect(shows('6+-2='), '4.');
    });

    test('%: a × b / 100; then = applies it', () {
      expect(shows('50+10%'), '5.');
      expect(shows('50+10%='), '55.');
      expect(shows('10%'), '0.', reason: 'nothing waiting → 0');
    });

    test('sqrt, 1/x, +/-', () {
      expect(shows('9s'), '3.');
      expect(shows('4i'), '0.25');
      expect(shows('5n'), '-5.');
      expect(shows('5nn'), '5.');
      expect(shows('3+4ns='), '-1.', reason: 'sqrt of a negative does nothing: 3 + (-4)');
      expect(shows('2+9s='), '5.', reason: 'a function result counts as the typed number');
    });

    test('dividing by 0 → error; only C / CE leave it', () {
      final e = press('1/0=');
      expect(e.error, isTrue);
      expect(press('5+', e).error, isTrue);
      expect(calcDisplay(press('e', e)), '0.');
      expect(press('0i').error, isTrue);
    });

    test('Backspace, CE, C', () {
      expect(shows('123b'), '12.');
      expect(shows('1bb'), '0.');
      expect(shows('5+7e3='), '8.', reason: 'CE clears only the number being typed');
      expect(shows('5+7c3='), '3.');
    });

    test('memory: MS, MR, M+, MC; C keeps it', () {
      final s = press('7M c 2+R=');
      expect(calcDisplay(s), '9.');
      expect(s.memory, 7);
      expect(press('3P', s).memory, 10);
      expect(press('X', s).memory, 0);
    });

    test('≤ 16 characters; 1/3 and 0.1 + 0.2 shown tidily', () {
      expect(shows('1234567890123456789').length, lessThanOrEqualTo(16));
      expect(shows('1/3='), '0.33333333333333', reason: '16 characters');
      expect(shows('.1+.2='), '0.3');
      expect(shows('99999999*99999999=').length, lessThanOrEqualTo(16));
    });

    test('keys where the device draws them; body for POST /api/calc', () {
      expect(calcKeyAt(10, 90), CalcKey.mc);
      expect(calcKeyAt(8 + 38 * 5 + 33, 86 + 30 * 3 + 25), CalcKey.equals);
      expect(calcKeyAt(50, 60), CalcKey.back);
      expect(calcKeyAt(130, 60), CalcKey.ce);
      expect(calcKeyAt(200, 70), CalcKey.c);
      expect(calcKeyAt(43, 90), isNull, reason: 'the 4-px gap');
      expect(calcBody(press('7M'), down: CalcKey.ms), {'display': '7.', 'error': false, 'mem': true, 'down': 12});
    });
  });
}
