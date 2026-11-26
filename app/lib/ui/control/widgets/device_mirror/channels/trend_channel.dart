import 'dart:ui';

import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../domain/models/usage_mirror.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';
import 'usage_chrome.dart';

/// Xu hướng window (`ch_trend.cpp`, XP-Trend / -Trend-Collecting): white field 220×130 at (10, 44) with the legend,
/// paired day bars (Claude x 18 + 30i, Codex x 29 + 30i, up to 102 px over the rule y 164), weekdays at y 177 and
/// the status bar ("Hôm nay CL 9 · CX 4" | "Đỉnh T2", "Có 2 / 7 ngày", or a dead credential).
class TrendChannel extends MirrorChannel {
  const TrendChannel();

  static const _base = 164, _barMax = 102, _step = 30, _barW = 10;

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final m = f.usage.trend;
    Xp.window(c, l.devXpTitleTrend, icon: XpIcon.clawd, statusBar: true);
    c.text(l.devXpTrendLabel, Xp.left, 28, XpFont.jb11, XpColors.label);
    c.outline(10, 44, 220, 130, XpColors.fieldBorder);
    c.fill(11, 45, 218, 128, XpColors.white);

    final have = m.haveDays;
    final n = m.blocks.length;
    if (have != null && have >= 7) {
      for (var k = 0; k < n; k++) {
        final b = m.blocks[k];
        final lx = 12 + k * 72;
        c.fill(lx, 48, 8, 8, _color(b));
        c.text(b.claude ? 'Claude' : 'Codex', lx + 12, 46, XpFont.jb11, XpColors.black);
      }
    }
    var scale = 10.0; // floor: tiny noise never fills a bar
    for (final b in m.blocks) {
      for (final v in b.burn ?? const <double?>[]) {
        if (v != null && v > scale) scale = v;
      }
    }
    for (var i = 0; i < 7; i++) {
      for (var k = 0; k < n; k++) {
        final v = _burn(m.blocks[k], i);
        if (v == null || v <= 0) continue;
        final h = (v / scale * _barMax).round().clamp(2, _barMax);
        final x = n == 2 ? 18 + i * _step + k * (_barW + 1) : 18 + i * _step + 5;
        c.fill(x, _base - h, _barW, h, _color(m.blocks[k]));
      }
    }
    c.hLine(14, _base, 212, XpColors.statusLine);
    if (have != null && have < 7 && 7 - have >= 4) {
      c.text(l.devXpTrendCollecting, 15 + 15 * (7 - have), 100, XpFont.jb11, XpColors.muted, align: XpAlign.center);
    }

    for (var i = 0; i < m.weekdays.length && i < 7; i++) {
      c.text(
        l.devWeekdayShort('${m.weekdays[i]}'),
        28 + i * _step,
        177,
        XpFont.jb11,
        XpColors.muted,
        align: XpAlign.center,
      );
    }
    _status(c, l, m, have);
  }

  static double? _burn(TrendBlock b, int i) {
    final v = b.burn;
    return v == null || i >= v.length ? null : v[i];
  }

  static Color _color(TrendBlock b) => b.cred.bad ? XpColors.dim : (b.claude ? XpColors.red : XpColors.lilac);

  void _status(XpCanvas c, AppLocalizations l, TrendMirror m, int? have) {
    for (final b in m.blocks) {
      if (!b.cred.bad) continue;
      final last = b.lastReading;
      Xp.statusBar(
        c,
        UsageChrome.credStatus(l, b.cred, claude: b.claude),
        last == null ? '' : l.devXpTrendLast(last.day, last.month),
        leftColor: UsageChrome.credColor(b.cred),
        rightColor: XpColors.muted,
      );
      return;
    }
    if (have == null) return; // history unknown to the app: empty status bar
    if (have < 7) {
      Xp.statusBar(c, l.devXpTrendHave(have), '');
      return;
    }
    final parts = [for (final b in m.blocks) '${b.claude ? 'CL' : 'CX'} ${(_burn(b, 6) ?? 0).round()}'];
    var peak = -1;
    var best = 0.0;
    for (var i = 0; i < 7; i++) {
      var sum = 0.0;
      for (final b in m.blocks) {
        sum += _burn(b, i) ?? 0;
      }
      if (sum > best) {
        best = sum;
        peak = i;
      }
    }
    final right = peak >= 0 && peak < m.weekdays.length
        ? l.devXpTrendPeak(l.devWeekdayShort('${m.weekdays[peak]}'))
        : '';
    Xp.statusBar(c, '${l.devXpTrendToday} ${parts.join(' · ')}', right);
  }
}
