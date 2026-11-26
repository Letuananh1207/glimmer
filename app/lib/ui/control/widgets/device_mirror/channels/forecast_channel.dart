import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';

/// Forecast = the "Dự báo" tab of the Weather window (`ch_forecast.cpp`, panel P-2026-11-26.17 XP-Forecast-Details;
/// one window with Weather, R-DK-14): an XP ListView "Details" (10, 48) 220×157 — header Ngày · Trời · Thấp · Cao on
/// the body colour, then three 24-px rows Hôm nay (selected) / Mai / Kia with the 16-px icon. No weather yet → the empty
/// list and "Chưa có dự báo".
class ForecastChannel extends MirrorChannel {
  const ForecastChannel();

  static const _rowY = 66, _rowH = 24;

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    Xp.window(c, l.devXpTitleWeather, icon: XpIcon.weather);
    Xp.tabs(c, [l.devXpTabNow, l.devXpTabForecast], 1);
    Xp.field(c, 10, 48, 220, 157);
    c.fill(11, 49, 218, 15, XpColors.body);
    c.fill(11, 64, 218, 1, XpColors.group);
    c.fill(11, 65, 218, 1, XpColors.dim);
    for (final x in const [95, 160, 193]) {
      c.fill(x, 52, 1, 10, XpColors.dim);
    }
    c.text(l.devXpColDay, 17, 50, XpFont.jb11, XpColors.black);
    c.text(l.devXpColSky, 101, 50, XpFont.jb11, XpColors.black);
    c.text(l.devXpColLow, 189, 50, XpFont.jb11, XpColors.black, align: XpAlign.right);
    c.text(l.devXpColHigh, 224, 50, XpFont.jb11, XpColors.black, align: XpAlign.right);
    final w = f.ambient.weather;
    if (w.phase != WeatherPhase.ready) {
      c.text(l.devXpForecastEmpty, 17, 70, XpFont.jb11, XpColors.dim);
      return;
    }
    final labels = [l.devXpDayTodayLong, l.devXpDayTomorrow, l.devXpDayAfter];
    for (var i = 0; i < 3; i++) {
      final d = i < w.days.length ? w.days[i] : const MirrorDay();
      final y = _rowY + _rowH * i;
      final sel = i == 0;
      final ink = sel ? XpColors.white : XpColors.black;
      c.fill(11, y, 218, _rowH, sel ? XpColors.select : XpColors.white);
      Xp.weatherIcon(c, d.code, 15, y + 4);
      c.text(labels[i], 35, y + 3, XpFont.jb13, ink);
      c.text(d.desc, 101, y + 3, XpFont.jb13, ink, maxWidth: 189 - 24 - 4 - 101);
      c.text(d.lo == null ? '--' : '${d.lo}°', 189, y + 3, XpFont.jb13, ink, align: XpAlign.right);
      c.text(d.hi == null ? '--' : '${d.hi}°', 224, y + 3, XpFont.jb13, ink, align: XpAlign.right);
    }
  }
}
