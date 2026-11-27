import 'dart:math' as math;
import 'dart:ui';

import '../../../../../domain/models/clock_view.dart';
import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';

/// Clock = XP "Date and Time Properties" (`ch_clock.cpp`, panel P-2026-11-26.17 / .22 XP-Clock-Props / -Month / -Zone /
/// -Net), drawn from the app's [ClockView] (R-DK-16): tabs Ngày và giờ · Múi giờ · Internet. Ngày và giờ — month field
/// "Thg 11" + year spin, the viewed month from Monday (other months dim; a chosen day, else today, selected), the month
/// list when open; the analog face, the read-only time field (xpBody, dim spin arrows); "Múi giờ: GMT+7 · place".
/// Múi giờ — zone field, world map (the zone's column lighter), daylight saving dim, the zone list when open.
/// Internet — auto sync ☑, server, "Cập nhật ngay", last / next sync.
class ClockChannel extends MirrorChannel {
  const ClockChannel();

  static const _cx = 183, _cy = 106;
  static const _calX = 13, _calY = 98, _cellW = 16, _cellH = 13;

  static const _sea = XpColors.mapSea, _land = XpColors.mapLand;
  static const _seaSel = XpColors.mapSeaSel, _landSel = XpColors.mapLandSel;
  static const _btnLine = XpColors.pushLine, _btnFace = XpColors.pushFace, _btnFoot = XpColors.pushFoot;

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final v = f.clockView;
    Xp.window(c, l.devXpTitleDateTime, icon: XpIcon.clock);
    Xp.tabs(c, [l.devXpTabDateTime, l.devXpTabTimeZone, l.devXpTabInternet], v.tab.index);
    switch (v.tab) {
      case ClockTab.date:
        _date(c, f, l, v);
      case ClockTab.zone:
        _zone(c, f, l, v);
      case ClockTab.net:
        _net(c, f, l);
    }
  }

  static void _drop(XpCanvas c, int x, int y) {
    c.fill(x, y, 14, 14, XpColors.btn);
    for (var r = 0; r < 3; r++) {
      c.fill(x + 3 + r, y + 6 + r, 5 - 2 * r, 1, XpColors.white);
    }
  }

  static void _spin(XpCanvas c, int x, int y, int h, Color arrow) {
    c.fill(x, y, 12, h, XpColors.body);
    final mid = y + h ~/ 2;
    c.fill(x, mid, 12, 1, XpColors.fieldBorder);
    for (var r = 0; r < 3; r++) {
      c.fill(x + 6 - r, y + 2 + r, 1 + 2 * r, 1, arrow);
      c.fill(x + 4 + r, mid + 3 + r, 5 - 2 * r, 1, arrow);
    }
  }

  /// Drop-down list box (x, y, w × 119): black border, 9 rows, row [sel] xpSelect, scroll bar.
  static void _list(XpCanvas c, int x, int y, int w, ClockList list, int top, int sel, String Function(int) label) {
    const h = 2 + listRows * listRowH;
    c.fill(x, y, w, h, XpColors.black);
    c.fill(x + 1, y + 1, w - 2, h - 2, XpColors.white);
    final sbx = x + w - 11;
    for (var r = 0; r < listRows && top + r < listCount(list); r++) {
      final ry = y + 1 + r * listRowH, i = top + r;
      if (i == sel) c.fill(x + 1, ry, sbx - x - 1, listRowH, XpColors.select);
      c.text(
        label(i),
        x + 3,
        ry,
        XpFont.jb11,
        i == sel ? XpColors.white : XpColors.black,
        maxWidth: (sbx - x - 6).toDouble(),
      );
    }
    c.fill(sbx, y + 1, 10, h - 2, _btnFace);
    for (final by in [y + 1, y + h - 11]) {
      c.fill(sbx, by, 10, 10, XpColors.btnEdge);
      c.fill(sbx + 1, by + 1, 8, 8, XpColors.btn);
    }
    c.pixel(sbx + 4, y + 5, XpColors.white);
    c.fill(sbx + 3, y + 6, 3, 1, XpColors.white);
    c.fill(sbx + 3, y + h - 7, 3, 1, XpColors.white);
    c.pixel(sbx + 4, y + h - 6, XpColors.white);
    final (ty, th) = listThumb(list, top, y + 11, h - 22);
    c.fill(sbx, ty, 10, th, XpColors.btnEdge);
    c.fill(sbx + 1, ty + 1, 8, th - 2, XpColors.btn);
  }

  void _date(XpCanvas c, MirrorFrame f, AppLocalizations l, ClockView v) {
    final k = f.ambient.clock;
    Xp.groupBox(c, 10, 54, 122, 128, l.devXpGroupDate, bg: XpColors.white);
    Xp.groupBox(c, 136, 54, 94, 128, l.devXpGroupTime, bg: XpColors.white);
    final t = f.deviceNow;
    final synced = f.clockSynced;
    final year = v.year ?? t.year, month = v.month ?? t.month;

    // Month field + drop button, year field + spin.
    Xp.field(c, 14, 62, 67, 16);
    if (synced) c.text(l.devXpMonthShort(month), 17, 63, XpFont.jb11, XpColors.black);
    _drop(c, 66, 63);
    Xp.field(c, 85, 62, 44, 16);
    if (synced) c.text('$year', 87, 63, XpFont.jb11, XpColors.black);
    _spin(c, 116, 63, 14, XpColors.black);

    // Calendar of the viewed month: weeks from Monday; a chosen day, else today, selected.
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
      final first = DateTime(year, month);
      final lead = first.weekday - 1;
      final n = DateTime(year, month + 1, 0).day;
      final prevN = DateTime(year, month, 0).day;
      final lit = v.day ?? (year == t.year && month == t.month ? t.day : 0);
      for (var i = 0; i < 42; i++) {
        final inMonth = i >= lead && i - lead < n;
        final d = i < lead ? prevN - lead + 1 + i : (inMonth ? i - lead + 1 : i - lead - n + 1);
        final x = _calX + _cellW * (i % 7), y = _calY + _cellH * (i ~/ 7);
        final sel = inMonth && d == lit;
        if (sel) c.fill(x, y, _cellW, _cellH, XpColors.select);
        c.text(
          '$d',
          x + _cellW / 2,
          y,
          XpFont.jb11,
          sel ? XpColors.white : (inMonth ? XpColors.black : XpColors.dim),
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

    // Time field, read-only (the time comes from the Internet): xpBody, dim spin arrows.
    c.fill(145, 152, 76, 18, XpColors.fieldBorder);
    c.fill(146, 153, 74, 16, XpColors.body);
    _spin(c, 208, 153, 16, XpColors.dim);
    if (synced) {
      final mm = t.minute.toString().padLeft(2, '0');
      final text = f.h24
          ? '${t.hour.toString().padLeft(2, '0')}:$mm:${t.second.toString().padLeft(2, '0')}'
          : '${t.hour % 12 == 0 ? 12 : t.hour % 12}:$mm ${t.hour < 12 ? l.devClockAm : l.devClockPm}';
      c.text(text, 148, 153, XpFont.jb12b, XpColors.black);
    }
    final zone = k.place.isEmpty ? k.gmt : '${k.gmt} · ${k.place}';
    c.text(l.devXpClockZone(zone), 12, 189, XpFont.jb11, XpColors.black, maxWidth: 216);
    if (v.list == ClockList.month) {
      _list(c, 14, 78, 67, ClockList.month, v.top, month - 1, (i) => l.devXpMonthShort(i + 1));
    }
  }

  static String _zoneLabel(AppLocalizations l, int tz) {
    final i = clockZones.indexOf(tz);
    return i < 0 ? gmtParen(tz) : '${gmtParen(tz)} ${l.devXpZoneName('$i')}';
  }

  void _zone(XpCanvas c, MirrorFrame f, AppLocalizations l, ClockView v) {
    final tz = (f.settings?['tzMinutes'] as num?)?.toInt() ?? 0;
    Xp.field(c, 12, 50, 216, 18);
    c.text(_zoneLabel(l, tz), 15, 52, XpFont.jb11, XpColors.black, maxWidth: 196);
    _drop(c, 213, 52);
    c.fill(12, 74, 218, 90, XpColors.fieldBorder);
    final col = mapColumn(tz);
    for (var r = 0; r < 11; r++) {
      for (var k = 0; k < 27; k++) {
        final land = mapIsLand(r, k), sel = k == col;
        c.fill(13 + 8 * k, 75 + 8 * r, 8, 8, land ? (sel ? _landSel : _land) : (sel ? _seaSel : _sea));
      }
    }
    c.fill(12, 172, 13, 13, XpColors.dim);
    c.fill(13, 173, 11, 11, XpColors.body);
    c.text(l.devXpDst, 30, 172, XpFont.jb11, XpColors.dim);
    if (v.list == ClockList.zone) {
      _list(c, 12, 68, 216, ClockList.zone, v.top, clockZones.indexOf(tz), (i) => _zoneLabel(l, clockZones[i]));
    }
  }

  void _net(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    c.fill(12, 52, 13, 13, XpColors.fieldBorder);
    c.fill(13, 53, 11, 11, XpColors.white);
    const tick = [6, 7, 8, 7, 6, 5, 4];
    for (var i = 0; i < 7; i++) {
      c.fill(15 + i, 52 + tick[i] - 1, 1, 3, XpColors.check);
    }
    c.text(l.devXpNetAuto, 30, 52, XpFont.jb11, XpColors.black);
    c.text(l.devXpNetServerLabel, 12, 77, XpFont.jb11, XpColors.black);
    Xp.field(c, 72, 74, 156, 18);
    c.text(l.devXpNetServer, 75, 76, XpFont.jb11, XpColors.black);
    _drop(c, 213, 76);
    c.fill(125, 98, 103, 21, _btnLine);
    c.fill(126, 99, 101, 19, _btnFace);
    c.fill(126, 116, 101, 2, _btnFoot);
    for (final (px, py) in [(125, 98), (227, 98), (125, 118), (227, 118)]) {
      c.pixel(px, py, XpColors.white);
    }
    c.text(l.devXpNetUpdate, 176, 102, XpFont.jb11, XpColors.black, align: XpAlign.center);
    final last = f.ntpLast;
    if (last == null) {
      c.text(l.devXpNetNever, 12, 130, XpFont.jb11, XpColors.black);
      return;
    }
    String hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final next = last.add(const Duration(hours: 1));
    c.text(l.devXpNetSynced(hm(last)), 12, 130, XpFont.jb11, XpColors.black);
    c.text(
      l.devXpNetDate('${last.day.toString().padLeft(2, '0')}/${last.month.toString().padLeft(2, '0')}/${last.year}'),
      12,
      144,
      XpFont.jb11,
      XpColors.black,
    );
    c.text(l.devXpNetNext(hm(next)), 12, 166, XpFont.jb11, XpColors.label);
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
