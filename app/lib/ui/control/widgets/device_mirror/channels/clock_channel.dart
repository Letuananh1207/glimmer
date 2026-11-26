import 'dart:math' as math;
import 'dart:ui';

import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';

/// Clock = XP "Date and Time Properties" (`ch_clock.cpp`, panel P-2026-11-26.17 XP-Clock-Props): window "Ngày và Giờ",
/// tabs Ngày và giờ · Múi giờ; group Ngày — month field + the month from Monday (other months dim, today selected);
/// group Giờ — the analog face (hour marks, minute dots, hour / minute / red second hands), the time field with spin
/// buttons; "Múi giờ: GMT+7 · place" below.
class ClockChannel extends MirrorChannel {
  const ClockChannel();

  static const _cx = 183, _cy = 106;
  static const _calX = 13, _calY = 98, _cellW = 16, _cellH = 13;

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final k = f.ambient.clock;
    Xp.window(c, l.devXpTitleDateTime, icon: XpIcon.clock);
    Xp.tabs(c, [l.devXpTabDateTime, l.devXpTabTimeZone], 0);
    Xp.groupBox(c, 10, 54, 122, 128, l.devXpGroupDate, bg: XpColors.white);
    Xp.groupBox(c, 136, 54, 94, 128, l.devXpGroupTime, bg: XpColors.white);
    final t = f.deviceNow;
    final synced = f.clockSynced;

    // Month field + drop button.
    Xp.field(c, 14, 62, 114, 16);
    if (synced) c.text('${t.month.toString().padLeft(2, '0')}/${t.year}', 17, 63, XpFont.jb11, XpColors.black);
    c.fill(113, 63, 14, 14, XpColors.btn);
    for (var r = 0; r < 3; r++) {
      c.fill(116 + r, 69 + r, 5 - 2 * r, 1, XpColors.white);
    }

    // Calendar: weeks from Monday.
    for (var i = 0; i < 7; i++) {
      c.text(
        l.devXpWeekdayShort('${i + 1}'),
        _calX + _cellW * i + _cellW / 2,
        82,
        XpFont.jb11,
        XpColors.groupLabel,
        align: XpAlign.center,
      );
    }
    c.fill(_calX, 96, 112, 1, XpColors.group);
    if (synced) {
      final first = DateTime(t.year, t.month);
      final lead = first.weekday - 1;
      final n = DateTime(t.year, t.month + 1, 0).day;
      final prevN = DateTime(t.year, t.month, 0).day;
      for (var i = 0; i < 42; i++) {
        final inMonth = i >= lead && i - lead < n;
        final d = i < lead ? prevN - lead + 1 + i : (inMonth ? i - lead + 1 : i - lead - n + 1);
        final x = _calX + _cellW * (i % 7), y = _calY + _cellH * (i ~/ 7);
        final today = inMonth && d == t.day;
        if (today) c.fill(x, y, _cellW, _cellH, XpColors.select);
        c.text(
          '$d',
          x + _cellW / 2,
          y,
          XpFont.jb11,
          today ? XpColors.white : (inMonth ? XpColors.black : XpColors.dim),
          align: XpAlign.center,
        );
      }
    }

    // Analog face.
    c.fill(147, 70, 73, 73, XpColors.white);
    for (var m = 0; m < 60; m++) {
      if (m % 5 != 0) {
        final (x, y) = _at(m, 34);
        c.pixel(x, y, XpColors.dim);
        continue;
      }
      final (x, y) = _at(m, 33);
      final s = m % 15 == 0 ? 3 : 2;
      c.fill(x - 1, y - 1, s, s, XpColors.title);
    }
    if (synced) {
      _hand(c, (t.hour % 12) * 5 + t.minute ~/ 12, 18, 3, XpColors.black);
      _hand(c, t.minute, 27, 2, XpColors.black);
      _hand(c, t.second, 30, 1, XpColors.red);
    }
    c.fill(_cx - 1, _cy - 1, 3, 3, XpColors.black);

    // Time field + spin buttons.
    Xp.field(c, 145, 152, 76, 18);
    c.fill(208, 153, 12, 16, XpColors.body);
    c.fill(208, 160, 12, 1, XpColors.fieldBorder);
    for (var r = 0; r < 3; r++) {
      c.fill(214 - r, 155 + r, 1 + 2 * r, 1, XpColors.black);
      c.fill(212 + r, 163 + r, 5 - 2 * r, 1, XpColors.black);
    }
    if (synced) {
      final mm = t.minute.toString().padLeft(2, '0');
      final text = f.h24
          ? '${t.hour.toString().padLeft(2, '0')}:$mm:${t.second.toString().padLeft(2, '0')}'
          : '${t.hour % 12 == 0 ? 12 : t.hour % 12}:$mm ${t.hour < 12 ? l.devClockAm : l.devClockPm}';
      c.text(text, 148, 153, XpFont.jb12b, XpColors.black);
    }
    final zone = k.place.isEmpty ? k.gmt : '${k.gmt} · ${k.place}';
    c.text(l.devXpClockZone(zone), 12, 189, XpFont.jb11, XpColors.black, maxWidth: 216);
  }

  /// Point at position [i] (0–59, 0 = 12 o'clock) on radius [r] (the firmware's 60-entry sine table, rounded).
  static (int, int) _at(int i, int r) {
    final a = i * math.pi / 30;
    return (_cx + (math.sin(a) * r).round(), _cy - (math.cos(a) * r).round());
  }

  /// A hand: a [t]×[t] brush along the line (`thickLine`), no anti-aliasing.
  static void _hand(XpCanvas c, int pos, int len, int t, Color color) {
    var (x0, y0) = (_cx, _cy);
    final (x1, y1) = _at(pos, len);
    final o = t ~/ 2;
    final dx = (x1 - x0).abs(), sx = x0 < x1 ? 1 : -1, dy = -(y1 - y0).abs(), sy = y0 < y1 ? 1 : -1;
    var e = dx + dy;
    while (true) {
      c.fill(x0 - o, y0 - o, t, t, color);
      if (x0 == x1 && y0 == y1) break;
      final e2 = 2 * e;
      if (e2 >= dy) {
        e += dy;
        x0 += sx;
      }
      if (e2 <= dx) {
        e += dx;
        y0 += sy;
      }
    }
  }
}
