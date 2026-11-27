// Dò mìn (R-DK-23, panel P-2026-11-27.25, §17 XP-Mines): Minesweeper of Windows XP at Beginner, played with the
// app's mouse; the app keeps the game and sends the board (`POST /api/mines`) for the device to draw.
import 'dart:math' as math;

import '../models/mines_game.dart';

const _cols = MinesGame.cols, _rows = MinesGame.rows, _cells = MinesGame.cells;

/// Board geometry on the device (firmware `Mines::kBoardX`…): cell (c, r) at (48 + 16c, 64 + 16r), 16 × 16.
const minesBoardX = 48, minesBoardY = 64, minesCell = 16;

/// The face button 26 × 26 at (107, 29).
const minesFaceX = 107, minesFaceY = 29, minesFaceSize = 26;

/// The cell under device pixel ([x], [y]), null = none.
int? minesCellAt(int x, int y) {
  if (x < minesBoardX || y < minesBoardY) return null;
  final c = (x - minesBoardX) ~/ minesCell, r = (y - minesBoardY) ~/ minesCell;
  return c < _cols && r < _rows ? r * _cols + c : null;
}

/// The face button is under ([x], [y]).
bool minesFaceAt(int x, int y) =>
    x >= minesFaceX && x < minesFaceX + minesFaceSize && y >= minesFaceY && y < minesFaceY + minesFaceSize;

Iterable<int> _around(int i) sync* {
  final c = i % _cols, r = i ~/ _cols;
  for (var dr = -1; dr <= 1; dr++) {
    for (var dc = -1; dc <= 1; dc++) {
      if (dr == 0 && dc == 0) continue;
      final cc = c + dc, rr = r + dr;
      if (cc >= 0 && cc < _cols && rr >= 0 && rr < _rows) yield rr * _cols + cc;
    }
  }
}

/// Mines next to cell [i].
int minesAround(MinesGame g, int i) => _around(i).where(g.mines.contains).length;

/// Left click on cell [i]: opens it (a 0 opens its neighbours, flags excepted). The first click of a game places the
/// mines first, never on [i]. A mine → lost; every safe cell open → won (every mine flagged). Flags, opened cells
/// and a finished game: nothing.
MinesGame minesReveal(MinesGame g, int i, {required math.Random random, required DateTime now}) {
  if (g.over || g.flags.contains(i) || g.opened.contains(i)) return g;
  var game = g;
  if (g.status == MinesStatus.ready) {
    final free = [for (var k = 0; k < _cells; k++) if (k != i) k]..shuffle(random);
    game = g.copyWith(mines: free.take(MinesGame.mineCount).toSet(), status: MinesStatus.playing, startedAt: now);
  }
  if (game.mines.contains(i)) {
    return game.copyWith(opened: {...game.opened, i}, status: MinesStatus.lost, blast: i, endedAt: now);
  }
  final opened = {...game.opened};
  final todo = [i];
  while (todo.isNotEmpty) {
    final k = todo.removeLast();
    if (!opened.add(k)) continue;
    if (minesAround(game, k) == 0) {
      todo.addAll(_around(k).where((n) => !opened.contains(n) && !game.flags.contains(n) && !game.mines.contains(n)));
    }
  }
  if (opened.length == _cells - MinesGame.mineCount) {
    return game.copyWith(opened: opened, flags: game.mines, status: MinesStatus.won, endedAt: now);
  }
  return game.copyWith(opened: opened);
}

/// Right click on cell [i]: a flag on / off (no `?`). Opened cells and a finished game: nothing.
MinesGame minesFlag(MinesGame g, int i) {
  if (g.over || g.opened.contains(i)) return g;
  final flags = {...g.flags};
  if (!flags.remove(i)) flags.add(i);
  return g.copyWith(flags: flags);
}

/// The board as the firmware draws it (81 chars): '.' not opened, 'F' flag, '0'..'8' opened, on a loss 'M' a
/// mine, 'X' the mine clicked, 'W' a wrong flag.
String minesBoard(MinesGame g) {
  final lost = g.status == MinesStatus.lost;
  final b = StringBuffer();
  for (var i = 0; i < _cells; i++) {
    final mine = g.mines.contains(i), flag = g.flags.contains(i);
    if (lost && i == g.blast) {
      b.write('X');
    } else if (lost && flag && !mine) {
      b.write('W');
    } else if (flag) {
      b.write('F');
    } else if (lost && mine) {
      b.write('M');
    } else if (g.opened.contains(i)) {
      b.write(minesAround(g, i));
    } else {
      b.write('.');
    }
  }
  return b.toString();
}

/// Mines left on the LED: 10 − flags (below 0 allowed); 0 once won.
int minesLeft(MinesGame g) => g.status == MinesStatus.won ? 0 : MinesGame.mineCount - g.flags.length;

/// Seconds on the LED: from the first click to the end (or [now]), at most 999.
int minesSecs(MinesGame g, DateTime now) {
  final s = g.startedAt;
  if (s == null) return 0;
  return math.min(999, (g.endedAt ?? now).difference(s).inSeconds);
}

/// `POST /api/mines` body.
Map<String, Object?> minesBody(MinesGame g, DateTime now) => {
  'board': minesBoard(g),
  'face': switch (g.status) {
    MinesStatus.won => 'cool',
    MinesStatus.lost => 'dead',
    _ => 'smile',
  },
  'left': minesLeft(g),
  'secs': minesSecs(g, now),
  'run': g.status == MinesStatus.playing,
};
