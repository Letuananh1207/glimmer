import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';

/// Forecast (`ch_forecast.cpp`, XP-Forecast / -Empty): a white list box (10, 28) 220×162 with three 53-px rows —
/// "Nay" (today, highlighted) / "Mai" / "Kia", condition, low (sky) / high (red) and a range bar on a shared scale;
/// status bar "3 ngày tới". No weather yet → the sun ×2 and "Chưa có dự báo".
class ForecastChannel extends MirrorChannel {
  const ForecastChannel();

  static const _boxX = 10, _boxY = 28, _boxW = 220, _boxH = 162, _rowH = 53;

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    Xp.window(c, l.devXpTitleForecast, icon: XpIcon.weather, statusBar: true);
    Xp.statusBar(c, l.devXpForecastNext3, '');
    Xp.field(c, _boxX, _boxY, _boxW, _boxH);
    final w = f.ambient.weather;
    if (w.phase != WeatherPhase.ready) {
      Xp.drawIcon(c, XpIcon.weather, 104, 70, XpColors.group, scale: 2);
      c.text(l.devXpForecastEmpty, 120, 111, XpFont.jb12b, XpColors.muted, align: XpAlign.center);
      return;
    }
    for (var i = 1; i < 3; i++) {
      c.fill(_boxX + 1, _boxY + i * _rowH, _boxW - 2, 1, XpColors.rowLine);
    }
    final labels = [l.devXpDayToday, l.devXpDayTomorrow, l.devXpDayAfter];
    for (var i = 0; i < 3; i++) {
      _row(c, i, labels[i], i < w.days.length ? w.days[i] : const MirrorDay());
    }
  }

  static void _row(XpCanvas c, int i, String label, MirrorDay d) {
    final base = _boxY + i * _rowH;
    final today = i == 0;
    c.fill(_boxX + 1, base + 1, _boxW - 2, _rowH - 1, XpColors.white);
    if (today) c.fill(_boxX + 1, base + 2, _boxW - 2, _rowH - 2, XpColors.rowHi);
    c.text(label, 18, base + 9, XpFont.jb12b, today ? XpColors.sky : XpColors.black);
    c.text(d.desc, 18, base + 28, XpFont.jb11, XpColors.muted, maxWidth: 112 - 21 - 18 - 4);
    c.fill(118, base + 25, 74, 4, XpColors.rowLine);
    if (d.spanX1 > d.spanX0) {
      c.fill(d.spanX0, base + 24, d.spanX1 - d.spanX0, 6, today ? XpColors.sky : XpColors.muted);
    }
    c.text(d.lo == null ? '--' : '${d.lo}°', 112, base + 20, XpFont.jb11, XpColors.sky, align: XpAlign.right);
    c.text(d.hi == null ? '--' : '${d.hi}°', 222, base + 20, XpFont.jb11, XpColors.red, align: XpAlign.right);
  }
}
