import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';

/// Clock (`ch_clock.cpp`, XP-Clock): "Thứ Tư · 25/11" 12B, VT323-86 time in a white field (20, 52) 200×86 — 12-hour
/// mode " 2:32" + "CH" 12B on the digits' baseline, centred as a group — the greeting 13 and status bar
/// "Tuần 48" | "GMT+7".
class ClockChannel extends MirrorChannel {
  const ClockChannel();

  static const _timeY = 55, _ampmGap = 2, _mid = 120;

  /// Top of "SA" / "CH": the firmware's baseline − ascent (116 − 13) + 1 like every JBMono-12B line of the design.
  static const _ampmY = 104;

  /// Greeting band x 10…229.
  static const _greetW = 220.0;

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final k = f.ambient.clock;
    Xp.window(c, l.devXpTitleClock, icon: XpIcon.clock, statusBar: true);
    Xp.statusBar(c, l.devXpClockWeek(k.week), k.gmt);
    final t = f.deviceNow;
    final synced = f.clockSynced;
    if (synced) {
      final date = '${l.devXpWeekday('${t.weekday}')} · ${t.day}/${t.month}';
      c.text(date, _mid, 31, XpFont.jb12b, XpColors.black, align: XpAlign.center);
    }
    Xp.field(c, 20, 52, 200, 86);
    final mm = synced ? t.minute.toString().padLeft(2, '0') : '--';
    if (f.h24) {
      final hh = synced ? t.hour.toString().padLeft(2, '0') : '--';
      c.text('$hh:$mm', _mid, _timeY, XpFont.vt86, XpColors.black, align: XpAlign.center);
    } else {
      final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final hh = synced ? '$h12'.padLeft(2) : '--';
      final ampm = t.hour < 12 ? l.devClockAm : l.devClockPm;
      final timeW = c.textWidth('00:00', XpFont.vt86);
      final apW = c.textWidth(ampm, XpFont.jb12b) + _ampmGap;
      final x = (_mid - (timeW + apW) / 2).floorToDouble();
      c.text('$hh:$mm', x, _timeY, XpFont.vt86, XpColors.black);
      if (synced) c.text(ampm, x + timeW + _ampmGap, _ampmY, XpFont.jb12b, XpColors.black);
    }
    if (!synced) return;
    final name = k.userName.isEmpty ? l.devXpClockYou : k.userName;
    final greet = _fitDots(c, l.devXpClockGreeting(k.greet.name, name));
    c.text(greet, _mid, 152, XpFont.jb13, XpColors.groupLabel, align: XpAlign.center);
  }

  /// A long user name is cut on whole characters + "..." to fit the band (`paintGreeting`).
  static String _fitDots(XpCanvas c, String s) {
    if (c.textWidth(s, XpFont.jb13) <= _greetW) return s;
    var r = s.runes.toList();
    while (r.length > 1) {
      r = r.sublist(0, r.length - 1);
      final t = '${String.fromCharCodes(r)}...';
      if (c.textWidth(t, XpFont.jb13) <= _greetW) return t;
    }
    return s;
  }
}
