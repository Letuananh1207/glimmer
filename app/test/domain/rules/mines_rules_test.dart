import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/mines_game.dart';
import 'package:glimmer_app/domain/rules/mines_rules.dart';

final _t0 = DateTime(2026, 11, 27, 10);

/// A game with the mines at [mines], already started.
MinesGame _with(Set<int> mines) =>
    MinesGame(mines: mines, status: MinesStatus.playing, startedAt: _t0);

void main() {
  group('R-DK-23 board geometry', () {
    test('cells (48 + 16c, 64 + 16r), the face (107, 29) 26 × 26', () {
      expect(minesCellAt(48, 64), 0);
      expect(minesCellAt(48 + 16 + 15, 64 + 16), 10);
      expect(minesCellAt(191, 207), 80);
      expect(minesCellAt(47, 70), isNull);
      expect(minesCellAt(192, 70), isNull);
      expect(minesFaceAt(120, 42), isTrue);
      expect(minesFaceAt(106, 42), isFalse);
    });
  });

  group('R-DK-23 rules (XP Beginner)', () {
    test('the first click is never a mine: 10 mines placed elsewhere, the clock starts', () {
      for (var seed = 0; seed < 50; seed++) {
        final g = minesReveal(MinesGame.fresh, 40, random: math.Random(seed), now: _t0);
        expect(g.mines, hasLength(10));
        expect(g.mines.contains(40), isFalse);
        expect(g.status, isNot(MinesStatus.lost));
        expect(g.startedAt, _t0);
      }
    });

    test('a 0 opens its neighbours, not a flag; a number opens alone', () {
      // Mines in the bottom row only: (0, 0) is a 0 → the top rows open up to the numbers above the mines.
      var g = _with({72, 73, 74, 75, 76, 77, 78, 79, 80, 71}).copyWith(flags: {1});
      g = minesReveal(g, 0, random: math.Random(1), now: _t0);
      expect(g.opened.contains(0), isTrue);
      expect(g.opened.contains(1), isFalse, reason: 'flagged');
      expect(g.opened.contains(9 * 6 + 3), isTrue, reason: 'row 6 is all 0s');
      expect(g.opened.contains(9 * 7 + 3), isTrue, reason: 'row 7: the numbers bordering the 0s open too (XP)');
      expect(g.opened.contains(9 * 8 + 3), isFalse, reason: 'the mines stay closed');
      final b = minesBoard(g);
      expect(b[0], '0');
      expect(b[1], 'F');
      expect(b[9 * 7 + 3], '3');
      expect(b[9 * 8 + 3], '.');
      // A number clicked directly opens alone.
      final n = minesReveal(_with({72, 73, 74}), 9 * 7 + 1, random: math.Random(1), now: _t0);
      expect(n.opened, {9 * 7 + 1});
    });

    test('a left click on a flag or an opened cell does nothing; right click flags / unflags', () {
      var g = _with({80});
      g = minesFlag(g, 5);
      expect(minesLeft(g), 9);
      expect(minesReveal(g, 5, random: math.Random(1), now: _t0), same(g));
      g = minesFlag(g, 5);
      expect(g.flags, isEmpty);
      g = minesFlag(minesFlag(minesFlag(g, 1), 2), 3);
      expect(minesLeft(minesFlag(minesFlag(minesFlag(minesFlag(minesFlag(minesFlag(minesFlag(minesFlag(g, 4), 6), 7),
          8), 10), 11), 12), 13)), -1, reason: '11 flags → -1, as XP');
    });

    test('a mine → lost: every mine shows, the clicked one blasts, a wrong flag is crossed, a right flag stays', () {
      var g = _with({0, 2, 80}).copyWith(flags: {2, 5});
      g = minesReveal(g, 80, random: math.Random(1), now: _t0.add(const Duration(seconds: 12)));
      expect(g.status, MinesStatus.lost);
      final b = minesBoard(g);
      expect(b[80], 'X');
      expect(b[0], 'M');
      expect(b[2], 'F');
      expect(b[5], 'W');
      final body = minesBody(g, _t0.add(const Duration(minutes: 5)));
      expect(body['face'], 'dead');
      expect(body['run'], false);
      expect(body['secs'], 12, reason: 'stopped at the loss');
      expect(minesReveal(g, 40, random: math.Random(1), now: _t0), same(g), reason: 'a finished game takes no click');
    });

    test('every safe cell open → won: all mines flagged, LED 000, face cool', () {
      final mines = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
      var g = _with(mines);
      g = minesReveal(g, 80, random: math.Random(1), now: _t0.add(const Duration(seconds: 7)));
      expect(g.status, MinesStatus.won);
      expect(g.flags, mines);
      final body = minesBody(g, _t0.add(const Duration(seconds: 30)));
      expect(body['face'], 'cool');
      expect(body['left'], 0);
      expect(body['secs'], 7);
      expect((body['board']! as String).substring(0, 10), 'FFFFFFFFFF');
    });

    test('body of a fresh game: 81 dots, smile, 10, 0 s, clock stopped; capped at 999 s', () {
      final body = minesBody(MinesGame.fresh, _t0);
      expect(body, {'board': '.' * 81, 'face': 'smile', 'left': 10, 'secs': 0, 'run': false});
      expect(minesSecs(_with({80}), _t0.add(const Duration(hours: 1))), 999);
      expect(minesBody(_with({80}), _t0.add(const Duration(seconds: 3)))['run'], true);
    });
  });
}
