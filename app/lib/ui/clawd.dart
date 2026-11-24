import 'dart:async';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Clawd's expressions — same set as Display::drawClawd in the firmware.
enum ClawdMood { open, wide, happy, sad, sleep }

/// Clawd, the Claude Code mascot: the terminal sprite as an 18×10 grid,
/// drawn pixel-crisp. Blinks every 4 s while awake; steps when [walking].
class Clawd extends StatefulWidget {
  const Clawd({super.key, this.mood = ClawdMood.open, this.walking = false, this.size = 90, this.color = G.clawd});

  final ClawdMood mood;
  final bool walking;
  final double size; // width in logical px; height = size × 10/18
  final Color color;

  @override
  State<Clawd> createState() => _ClawdState();
}

class _ClawdState extends State<Clawd> {
  Timer? _t;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 150), (_) => setState(() => _tick++));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blink = (widget.mood == ClawdMood.open || widget.mood == ClawdMood.wide) && _tick % 27 == 0;
    final step = widget.walking && (_tick ~/ 3).isOdd;
    return CustomPaint(
      size: Size(widget.size, widget.size * 10 / 18),
      painter: _ClawdPainter(blink ? ClawdMood.sleep : widget.mood, step, widget.color),
    );
  }
}

class _ClawdPainter extends CustomPainter {
  _ClawdPainter(this.mood, this.step, this.color);
  final ClawdMood mood;
  final bool step;
  final Color color;

  static const _base = [
    '...############...',
    '...############...',
    '...##.######.##...',
    '...##.######.##...',
    '.################.',
    '.################.',
    '...############...',
    '...############...',
    '....#.#....#.#....',
    '....#.#....#.#....',
  ];

  List<List<bool>> _grid() {
    final g = [for (final r in _base) [for (final c in r.split('')) c == '#']];
    void hole(int r, int c, bool on) => g[r][c] = !on;
    switch (mood) {
      case ClawdMood.wide:
        hole(1, 5, true);
        hole(1, 12, true);
      case ClawdMood.happy:
        hole(2, 5, false);
        hole(2, 12, false);
      case ClawdMood.sad:
        hole(2, 5, false);
        hole(2, 12, false);
        hole(2, 6, true);
        hole(2, 11, true);
      case ClawdMood.sleep:
        for (final r in [2, 3]) {
          hole(r, 5, false);
          hole(r, 12, false);
        }
      case ClawdMood.open:
        break;
    }
    if (step) {
      for (final r in [8, 9]) {
        g[r] = [for (final c in '...#..#....#..#...'.split('')) c == '#'];
      }
    }
    return g;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 18;
    final p = Paint()
      ..color = color
      ..isAntiAlias = false;
    final g = _grid();
    for (var j = 0; j < 10; j++) {
      for (var i = 0; i < 18; i++) {
        if (g[j][i]) canvas.drawRect(Rect.fromLTWH(i * s, j * s, s + 0.5, s + 0.5), p);
      }
    }
  }

  @override
  bool shouldRepaint(_ClawdPainter o) => o.mood != mood || o.step != step || o.color != color;
}

/// The mood the device shows for a project board (most urgent row first).
ClawdMood moodFor(List<String> states) {
  if (states.isEmpty) return ClawdMood.sleep;
  if (states.contains('approval')) return ClawdMood.wide;
  if (states.contains('error')) return ClawdMood.sad;
  if (states.contains('working') || states.contains('input')) return ClawdMood.open;
  return ClawdMood.happy;
}
