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

/// Weather (`ch_weather.cpp`, panel P-2026-11-26.17 XP-Weather-Props / -Loading / -Error): an XP property sheet,
/// tab "Hiện tại" — the 32-px icon, condition 16B, the place (`weatherPlace`), VT323-44 temperature, then the rows
/// Cảm giác · Độ ẩm · Gió · Chỉ số UV and Cao / thấp · Mặt trời mọc / lặn. No status bar; stale dims every value and
/// puts "cũ 2G" in the title. The Dự báo tab is [ForecastChannel] (one window, R-DK-14).
class WeatherChannel extends MirrorChannel {
  const WeatherChannel();

  /// VT323-44 is drawn in a 36-px line box here, 44 on the design page: +4 keeps the digits where the panel has them.
  static const _tempY = 45 + 4;

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
    Xp.window(c, title, icon: XpIcon.weather, meta: stale && age != null ? l.devXpStaleMeta(xpSpan(l, age)) : '');
    Xp.tabs(c, [l.devXpTabNow, l.devXpTabForecast], 0);

    final ink = stale ? XpColors.dim : XpColors.black;
    Xp.weatherIcon(c, w.code, 14, 50, big: true);
    c.text(w.desc, 54, 52, XpFont.jb16b, ink, maxWidth: 112);
    if (w.place.isNotEmpty) {
      c.text(w.place, 54, 71, XpFont.jb11, stale ? XpColors.dim : XpColors.label, maxWidth: 112);
    }
    if (w.temp != null) c.text('${w.temp}°', 226, _tempY, XpFont.vt44, ink, align: XpAlign.right);
    c.fill(12, 90, 216, 1, XpColors.group);
    c.fill(12, 164, 216, 1, XpColors.group);

    void row(int y, String label, String value) {
      c.text(label, 14, y, XpFont.jb11, ink);
      c.text(value, 112, y, XpFont.jb11, ink);
    }

    String or(Object? v, String Function() s) => v == null ? '--' : s();
    row(96, l.devXpRowFeels, or(w.feels, () => '${w.feels}°'));
    row(112, l.devXpRowHumidity, or(w.humidity, () => '${w.humidity}%'));
    row(128, l.devXpRowWind, or(w.wind, () => l.devXpWindValue(w.wind!)));
    row(144, l.devXpRowUv, or(w.uv, () => l.devXpUvValue(w.uv!, uvLevel(w.uv!))));
    final today = w.days.isEmpty ? const MirrorDay() : w.days.first;
    row(171, l.devXpRowHiLo, today.hi == null || today.lo == null ? '--' : '${today.hi}° / ${today.lo}°');
    row(187, l.devXpRowSun((w.sunEvent ?? SunEvent.rise).name), w.sunAt == null ? '--' : xpHm(l, w.sunAt!, f.h24));
  }

  /// `uvWord` of ch_weather.cpp: < 3 thấp, < 6 trung bình, < 8 cao, < 11 rất cao, else cực cao.
  static String uvLevel(int uv) => uv < 3
      ? 'low'
      : uv < 6
      ? 'moderate'
      : uv < 8
      ? 'high'
      : uv < 11
      ? 'veryHigh'
      : 'extreme';

  static String _errText(AppLocalizations l, MirrorWeather w) => switch (w.err) {
    WeatherErr.http => l.devXpWeatherErrHttp(w.errCode),
    WeatherErr.connect => l.devXpWeatherErrConnect,
    WeatherErr.begin => l.devXpWeatherErrBegin,
    WeatherErr.json => l.devXpWeatherErrJson,
    WeatherErr.noCurrent => l.devXpWeatherErrNoCurrent,
    WeatherErr.unknown || WeatherErr.none => l.devXpWeatherErrUnknown,
  };
}
