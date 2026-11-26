import 'dart:ui';

import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../domain/models/usage_mirror.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';
import 'usage_chrome.dart';

/// AI hôm nay window (`ch_aidash.cpp`, XP-AI / -Loading / -KeyBad): hero = Codex credits left, two groupboxes
/// "Claude" / "Codex" (value VT323-44 + bar), status bar advice | "CL 2G 14P · CX 3NG".
class AiChannel extends MirrorChannel {
  const AiChannel();

  static const _boxY = 120, _boxW = 106, _boxH = 66;

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final m = f.usage.ai;
    final age = m.staleAge;
    Xp.window(
      c,
      l.devXpTitleAi,
      icon: XpIcon.clawd,
      meta: age == null ? '' : l.devXpStaleMeta(UsageChrome.span(l, age)),
    );
    c.text(l.devXpAiHero, Xp.left, 28, XpFont.jb11, XpColors.label);

    final credits = m.credits;
    final hero = credits == null ? '--' : '\$${credits.toStringAsFixed(2)}';
    final heroInk = credits == null || m.creditsStale ? XpColors.dim : XpColors.black;
    // "$123.45" is wider than the body at 86 px → VT323-44 (text shrinks to its box).
    final big = c.textWidth(hero, XpFont.vt86) <= 220;
    c.text(hero, Xp.left, big ? 40 : 64, big ? XpFont.vt86 : XpFont.vt44, heroInk);

    Xp.groupBox(c, 10, _boxY, _boxW, _boxH, 'Claude');
    Xp.groupBox(c, 124, _boxY, _boxW, _boxH, 'Codex');
    _block(c, l, 10, m.claude);
    _block(c, l, 124, m.codex);
    _status(c, l, m);
  }

  void _block(XpCanvas c, AppLocalizations l, int bx, AiSide s) {
    final String text;
    final Color ink;
    switch (s.mode) {
      case AiMode.credBad:
        text = l.devXpAiBad(s.cred == CredKind.blocked ? 'blocked' : 'other');
        ink = UsageChrome.credColor(s.cred);
      case _ when s.mode == AiMode.loading || s.used < 0:
        text = '--';
        ink = XpColors.dim;
      default:
        text = '${s.used}%';
        ink = s.mode == AiMode.stale ? XpColors.dim : XpColors.black;
    }
    c.text(text, bx + 8, 128, XpFont.vt44, ink);
    final lit = (s.mode == AiMode.value || s.mode == AiMode.stale) && s.used >= 0;
    Xp.progress(
      c,
      bx + 8,
      164,
      90,
      12,
      lit ? s.used.toDouble() : 0,
      on: s.mode == AiMode.stale ? XpColors.dim : UsageChrome.level(s.level, XpColors.green),
      padY: 1,
    );
  }

  void _status(XpCanvas c, AppLocalizations l, AiMirror m) {
    for (final (side, claude) in [(m.claude, true), (m.codex, false)]) {
      if (side.cred.bad) {
        Xp.statusBar(c, UsageChrome.credStatus(l, side.cred, claude: claude), '');
        return;
      }
    }
    String cd(DevSpan? s) => s == null ? '--' : UsageChrome.span(l, s);
    var right = l.devXpAiResets(cd(m.claude.reset), cd(m.codex.reset));
    final loading = m.claude.mode == AiMode.loading || m.codex.mode == AiMode.loading;
    final left = loading ? l.devXpLoading : _advice(l, m.advice);
    // A long advice keeps its words: the right text goes instead.
    final rw = c.textWidth(right, XpFont.jb11).round();
    if (left.isNotEmpty && 8 + c.textWidth(left, XpFont.jb11) + 4 > (231 - rw - 8) - 4) right = '';
    Xp.statusBar(c, left, right);
  }

  static String _advice(AppLocalizations l, AiAdvice? a) {
    if (a == null) return '';
    final name = a.claude ? 'Claude' : 'Codex';
    return switch (a.kind) {
      AdviceKind.use => l.devXpAdviceUse(name),
      AdviceKind.resets => l.devXpAdviceResets(name, a.left),
      AdviceKind.bothLow => l.devXpAdviceBothLow,
    };
  }
}
