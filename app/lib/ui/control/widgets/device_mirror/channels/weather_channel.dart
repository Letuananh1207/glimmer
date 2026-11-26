import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';

/// Words of a rounded age: short "2G" (title meta) or long "2 giờ" (status bar).
String xpSpan(AppLocalizations l, MirrorSpan s, {bool long = false}) =>
    long ? l.devXpSpanLong(s.unit.name, s.n) : l.devXpSpanShort(s.unit.name, s.n);

/// "17:48" / "5:48CH" (`ClockFmt::hm`) of a device wall clock.
String xpHm(AppLocalizations l, DateTime t, bool h24) {
  final m = t.minute.toString().padLeft(2, '0');
  if (h24) return '${t.hour.toString().padLeft(2, '0')}:$m';
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:$m${t.hour < 12 ? l.devClockAm : l.devClockPm}';
}

/// Weather (`ch_weather.cpp`, XP-Weather / -Loading / -Error / -Stale): VT323-86 temperature, the right stack
/// (feels, humidity, wind), condition + today's hi / lo, the "Mai" / "Kia" group boxes and the sun status bar.
/// Stale dims every value and puts "cũ 2G" in the title. UV is not in `/api/state`, so its row is never drawn.
class WeatherChannel extends MirrorChannel {
  const WeatherChannel();

  static const _boxX = [10, 124];
  static const _boxY = 144, _boxW = 106, _boxH = 46;

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final w = f.ambient.weather;
    final title = l.devXpTitleWeather;
    switch (w.phase) {
      case WeatherPhase.loading:
        Xp.window(c, title, icon: XpIcon.weather);
        Xp.loading(c, l.devXpWeatherLoading, step: 5);
        return;
      case WeatherPhase.error:
        Xp.window(c, title, icon: XpIcon.weather);
        Xp.dialog(c, XpDialog.warn, l.devXpWeatherErrorHead, [_errText(l, w), '', l.devXpWeatherRetrying]);
        return;
      case WeatherPhase.ready:
        break;
    }
    final stale = w.stale;
    final age = w.age;
    Xp.window(
      c,
      title,
      icon: XpIcon.weather,
      meta: stale && age != null ? l.devXpStaleMeta(xpSpan(l, age)) : '',
      statusBar: true,
    );
    final status = stale
        ? (age == null ? '' : l.devXpWeatherUpdated(xpSpan(l, age, long: true)))
        : (w.sunAt == null ? '' : l.devXpWeatherSun(w.sunEvent!.name, xpHm(l, w.sunAt!, f.h24)));
    Xp.statusBar(c, status, '');

    final ink = stale ? XpColors.dim : XpColors.black;
    final label = stale ? XpColors.dim : XpColors.label;
    if (w.temp != null) c.text('${w.temp}°', 10, 23, XpFont.vt86, ink);

    var ry = 32;
    for (final line in [
      if (w.feels != null) l.devXpWeatherFeels(w.feels!),
      if (w.humidity != null) l.devXpWeatherHumidity(w.humidity!),
      if (w.wind != null) l.devXpWeatherWind(w.wind!),
    ]) {
      c.text(line, Xp.right, ry, XpFont.jb11, label, align: XpAlign.right);
      ry += 18;
    }

    c.text(w.desc, 12, 100, XpFont.jb13, stale ? XpColors.dim : XpColors.sky, maxWidth: 128);
    final today = w.days.isEmpty ? const MirrorDay() : w.days.first;
    if (today.hi != null && today.lo != null) {
      c.text('${today.hi}° / ${today.lo}°', 12, 118, XpFont.jb11, label);
    }

    for (var k = 0; k < 2; k++) {
      final x = _boxX[k], cx = x + _boxW ~/ 2;
      Xp.groupBox(c, x, _boxY, _boxW, _boxH, k == 0 ? l.devXpDayTomorrow : l.devXpDayAfter);
      final d = k + 1 < w.days.length ? w.days[k + 1] : const MirrorDay();
      if (d.hi != null && d.lo != null) {
        c.text('${d.hi}/${d.lo}', cx, 149, XpFont.vt32, ink, align: XpAlign.center);
      }
      c.text(
        d.desc,
        cx,
        175,
        XpFont.jb11,
        stale ? XpColors.dim : XpColors.muted,
        align: XpAlign.center,
        maxWidth: _boxW - 6,
      );
    }
  }

  static String _errText(AppLocalizations l, MirrorWeather w) => switch (w.err) {
    WeatherErr.http => l.devXpWeatherErrHttp(w.errCode),
    WeatherErr.connect => l.devXpWeatherErrConnect,
    WeatherErr.begin => l.devXpWeatherErrBegin,
    WeatherErr.json => l.devXpWeatherErrJson,
    WeatherErr.noCurrent => l.devXpWeatherErrNoCurrent,
    WeatherErr.unknown || WeatherErr.none => l.devXpWeatherErrUnknown,
  };
}
