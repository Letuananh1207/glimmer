import 'dart:ui';

import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../domain/models/usage_mirror.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';
import 'claude_parts.dart';
import 'usage_chrome.dart';

/// Claude window (`ch_claude.cpp`, XP-Claude-A / -Stale / -KeyExpired / -Loading / -Rejected / -Offline /
/// -NoProject / -Done): hero % + countdown, Clawd 72×40 at (156, 36) — asleep at y 52 with the Zz — the other
/// window's groupbox and the project board field (credential strip + 2 rows when the key is bad). No status bar.
class ClaudeChannel extends MirrorChannel {
  const ClaudeChannel();

  static const _clawdX = 156, _clawdAwakeY = 36, _clawdAsleepY = 52;
  static const _barY = 102, _groupY = 128, _fieldY = 166, _rowH = 13;

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final m = f.usage.claude;
    Xp.window(c, 'Claude', icon: XpIcon.clawd, meta: UsageChrome.meta(l, m.meta));
    switch (m.view) {
      case UsageView.card:
        UsageChrome.credCard(c, l, m.card ?? const CredCard(CredCardKind.offline), claude: true);
      case UsageView.loading:
        Xp.loading(c, l.devXpLoading, step: f.deviceNow.second % 11);
      case UsageView.data:
        _data(c, f, l, m);
    }
  }

  void _data(XpCanvas c, MirrorFrame f, AppLocalizations l, ClaudeMirror m) {
    final dim = m.stale;
    final weekLabel = l.devXpWindow('week', 0), sessionLabel = l.devXpWindow('hours', 5);
    c.text(m.weeklyHero ? weekLabel : sessionLabel, Xp.left, 28, XpFont.jb11, XpColors.label);

    final asleep = m.clawd.asleep;
    final ink = dim ? XpColors.dim : XpColors.black;
    UsageChrome.hero(c, m.heroUsed, ink, percent: m.heroUsed < 100 || !asleep);
    Xp.progress(
      c,
      Xp.left,
      _barY,
      220,
      14,
      m.heroUsed < 0 ? 0 : m.heroUsed.toDouble(),
      on: _bar(m.heroLevel, dim),
      padY: 2,
    );

    ClaudeParts.clawd(c, _clawdX, asleep ? _clawdAsleepY : _clawdAwakeY, 4, m.clawd.mood, walk: m.clawd.walk);
    // One z per 400 ms of a 6 s cycle; the mirror takes it from the device clock's second.
    if (asleep) ClaudeParts.zz(c, (f.deviceNow.second % 6) * 1000 ~/ 400);
    c.text(
      UsageChrome.span(l, m.heroReset),
      asleep ? 150 : Xp.right,
      85,
      XpFont.jb12b,
      dim ? XpColors.dim : XpColors.red,
      align: XpAlign.right,
    );

    Xp.groupBox(c, Xp.left, _groupY, 220, 34, m.weeklyHero ? sessionLabel : weekLabel);
    final sec = m.secUsed < 0
        ? '--'
        : (m.secReset.kind == SpanKind.none ? '${m.secUsed}%' : '${m.secUsed}% · ${UsageChrome.span(l, m.secReset)}');
    c.text(sec, 224, 135, XpFont.jb11, ink, align: XpAlign.right);
    Xp.progress(c, 16, 151, 208, 7, m.secUsed < 0 ? 0 : m.secUsed.toDouble(), on: _bar(m.secLevel, dim));

    Xp.field(c, Xp.left, _fieldY, 220, 44);
    var y = _fieldY + 2, rows = 3;
    if (m.cred.bad) {
      UsageChrome.credBanner(c, l, Xp.left + 1, _fieldY + 1, 218, m.cred, claude: true);
      c.hLine(Xp.left + 1, _fieldY + 15, 218, XpColors.statusLine);
      y = _fieldY + 16;
      rows = 2;
    }
    for (var i = 0; i < m.rows.length && i < rows; i++) {
      final r = m.rows[i];
      ClaudeParts.row(c, l, r, y + i * _rowH, UsageChrome.span(l, r.age), dim: dim);
    }
    if (m.rows.isEmpty) {
      c.text(l.devXpNoProject, 120, rows == 3 ? 182 : y + 7, XpFont.jb11, XpColors.muted, align: XpAlign.center);
    }
  }

  /// Bars are the lighter xpBar while healthy, else the level colour; stale xpDim.
  static Color _bar(UsageLevel v, bool dim) => dim ? XpColors.dim : UsageChrome.level(v, XpColors.bar);
}
