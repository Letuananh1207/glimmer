import 'dart:ui';

import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../domain/models/usage_mirror.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';
import 'usage_chrome.dart';

/// Codex window (`ch_codex.cpp`, XP-Codex / -Stale / -Loading / -Expired): hero % + "đặt lại sau" countdown (+ limit
/// credits), the secondary window groupbox, the "Đặt lại tuần" groupbox (reset credits + weekly pace) and the
/// credential strip at y 198. No status bar.
class CodexChannel extends MirrorChannel {
  const CodexChannel();

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final m = f.usage.codex;
    Xp.window(c, 'Codex', icon: XpIcon.clawd, meta: UsageChrome.meta(l, m.meta));
    switch (m.view) {
      case UsageView.card:
        UsageChrome.credCard(c, l, m.card ?? const CredCard(CredCardKind.offline), claude: false);
      case UsageView.loading:
        Xp.loading(c, l.devXpLoading, step: f.deviceNow.second % 11);
      case UsageView.data:
        _data(c, l, m);
    }
  }

  static String window(AppLocalizations l, WindowLabel w) => l.devXpWindow(w.kind.name, w.n);

  void _data(XpCanvas c, AppLocalizations l, CodexMirror m) {
    final dim = m.stale;
    final ink = dim ? XpColors.dim : XpColors.black;
    c.text(window(l, m.heroLabel), Xp.left, 28, XpFont.jb11, XpColors.label);
    UsageChrome.hero(c, m.heroUsed, ink);
    Xp.progress(
      c,
      Xp.left,
      102,
      220,
      14,
      m.heroUsed < 0 ? 0 : m.heroUsed.toDouble(),
      on: dim ? XpColors.dim : UsageChrome.level(m.heroLevel, XpColors.lilac),
      padY: 1,
    );

    // Right column x 150..229: credits (when any), "đặt lại sau" + the countdown.
    final credits = m.credits;
    if (credits != null) {
      c.text(l.devXpCredits, Xp.right, 28, XpFont.jb11, XpColors.muted, align: XpAlign.right);
      c.text('\$${credits.toStringAsFixed(2)}', Xp.right, 43, XpFont.jb12b, ink, align: XpAlign.right);
    }
    c.text(l.devXpResetIn, Xp.right, 68, XpFont.jb11, XpColors.muted, align: XpAlign.right);
    c.text(
      UsageChrome.span(l, m.heroReset),
      Xp.right,
      85,
      XpFont.jb12b,
      dim ? XpColors.dim : XpColors.red,
      align: XpAlign.right,
    );

    Xp.groupBox(c, Xp.left, 128, 220, 30, window(l, m.secLabel));
    _secondary(c, l, m, ink);

    Xp.groupBox(c, Xp.left, 170, 220, 24, l.devXpWeekResets);
    _resets(c, l, m);

    if (m.cred.bad) UsageChrome.credBanner(c, l, Xp.left, 198, 220, m.cred, claude: false);
  }

  void _secondary(XpCanvas c, AppLocalizations l, CodexMirror m, Color ink) {
    final has = m.secUsed >= 0, reset = m.secReset.kind != SpanKind.none;
    if (m.secKnown && !has && !reset && m.secTag.isEmpty) {
      c.text(l.devXpNone, 18, 137, XpFont.jb11, XpColors.muted);
      return;
    }
    final right = has && reset
        ? '${m.secUsed}% · ${UsageChrome.span(l, m.secReset)}'
        : has
        ? '${m.secUsed}%'
        : (reset ? UsageChrome.span(l, m.secReset) : '--');
    c.text(right, 222, 137, XpFont.jb11, ink, align: XpAlign.right);
    final room = 222 - c.textWidth(right, XpFont.jb11) - 8 - 18;
    final tag = m.secTag;
    final left = tag.isEmpty ? l.devXpUsed : '${tag[0].toUpperCase()}${tag.substring(1).toLowerCase()}';
    c.text(left, 18, 137, XpFont.jb11, XpColors.black, maxWidth: room); // a label: stays black when stale
  }

  void _resets(XpCanvas c, AppLocalizations l, CodexMirror m) {
    var room = 222.0 - 18;
    final p = m.pace;
    if (p != null) {
      final pace = p.runsOut ? l.devXpPaceEmpty(UsageChrome.span(l, p.span)) : l.devXpPaceAtReset(p.pct);
      c.text(pace, 222, 177, XpFont.jb11, p.runsOut ? XpColors.red : XpColors.muted, align: XpAlign.right);
      room = 222 - c.textWidth(pace, XpFont.jb11) - 8 - 18;
    }
    final r = m.resets;
    if (r.left <= 0) {
      c.text(l.devXpNoResets, 18, 177, XpFont.jb11, XpColors.muted, maxWidth: room);
      return;
    }
    final span = r.span, until = r.until;
    var t = span != null
        ? l.devXpResetsLeftIn(r.left, UsageChrome.span(l, span))
        : until != null
        ? l.devXpResetsLeftUntil(
            r.left,
            '${until.day.toString().padLeft(2, '0')}/${until.month.toString().padLeft(2, '0')}',
          )
        : l.devXpResetsLeft(r.left);
    if (c.textWidth(t, XpFont.jb11) > room) t = l.devXpResetsLeft(r.left); // "còn 2 · đến 12/10" → "còn 2"
    c.text(t, 18, 177, XpFont.jb11, XpColors.black, maxWidth: room);
  }
}
