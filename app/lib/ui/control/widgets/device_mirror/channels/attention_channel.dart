import 'dart:ui';

import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';
import 'agent_bits.dart';

/// Attention — the interrupt card (`ch_attention.cpp` paintCard, XP-Attention / -Input / -Done / -Error /
/// -Progress): window named after the kind ("· 1/2" when several hold the screen), header "CLAUDE · glimmer",
/// Clawd ×6 at (66, 50), title 16B in the kind colour (120, 120), detail (120, 146), then the waiting rule +
/// "chờ bạn · 2P" or the progress bar (30, 166, 180×14). Empty queue → the bare "Tác tử" window.
class AttentionChannel extends MirrorChannel {
  const AttentionChannel();

  static const _mid = 120, _maxW = 216.0;

  static String windowTitle(AppLocalizations l, CardKind k) => switch (k) {
    CardKind.approval => l.devXpCardApproval,
    CardKind.input => l.devXpCardInput,
    CardKind.success => l.devXpCardDone,
    CardKind.error => l.devXpCardError,
    CardKind.progress => l.devXpCardProgress,
    CardKind.warning => l.devXpCardWarning,
    CardKind.info => l.devXpCardInfo,
  };

  static String _header(MirrorCard m) {
    final a = switch (m.agent) {
      CardAgent.claude => 'CLAUDE',
      CardAgent.codex => 'CODEX',
      CardAgent.other => '',
    };
    if (a.isEmpty) return m.project.isEmpty ? 'glimmer' : m.project;
    return m.project.isEmpty ? a : '$a · ${m.project}';
  }

  static String _title(AppLocalizations l, MirrorCard m) {
    final own = m.ownTitle;
    if (m.kind == CardKind.progress && m.progress >= 0) {
      return own == null ? l.devXpCardRunningPct(m.progress) : '$own ${m.progress}%';
    }
    if (own != null) return own;
    return switch (m.kind) {
      CardKind.approval => l.devXpCardNeedApproval,
      CardKind.success => l.devXpCardDoneTitle,
      _ => windowTitle(l, m.kind),
    };
  }

  static String _detail(AppLocalizations l, MirrorCard m) {
    final agentName = switch (m.agent) {
      CardAgent.claude => 'Claude',
      CardAgent.codex => 'Codex',
      CardAgent.other => l.devXpTitleAgents,
    };
    final body = switch (m.bodyForm) {
      CardBody.plain => m.body,
      CardBody.finished => l.devXpCardFinished(m.body),
      CardBody.waiting => l.devXpCardWaitingAnswer(agentName),
    };
    if (m.lead.isNotEmpty && body.isNotEmpty) return '${m.lead} · $body';
    return m.lead.isNotEmpty ? m.lead : body;
  }

  /// "chờ bạn · 45 giây" under a minute, then "chờ bạn · 2P".
  static String status(AppLocalizations l, int ageS) =>
      l.devXpCardWaitStatus(ageS < 60 ? l.devXpSeconds(ageS) : AgentBits.shortDuration(l, shortDurationOf(ageS)));

  void _center(XpCanvas c, String s, int y, XpFont f, Color color) =>
      c.text(AgentBits.fitDots(c, s, f, _maxW), _mid, y, f, color, align: XpAlign.center);

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final m = f.agents.card;
    if (m == null) {
      Xp.window(c, l.devXpTitleAgents);
      return;
    }
    Xp.window(c, windowTitle(l, m.kind), meta: m.count > 1 ? '${m.index + 1}/${m.count}' : '');
    final kc = AgentBits.kindColor(m.kind);
    _center(c, _header(m), 30, XpFont.jb11, XpColors.label);
    AgentBits.clawd(c, 66, 50, 6, m.agent == CardAgent.codex ? XpColors.lilac : PanelColors.clawd, m.eyes);
    _center(c, _title(l, m), 120, XpFont.jb16b, kc);
    final d = _detail(l, m);
    if (d.isNotEmpty) _center(c, d, 146, XpFont.jb11, XpColors.black);
    if (m.waits) {
      c.hLine(Xp.left, 168, Xp.right + 1 - Xp.left, XpColors.statusLine);
      _center(c, status(l, m.ageS), 176, XpFont.jb11, kc);
    } else if (m.kind == CardKind.progress && m.progress >= 0) {
      Xp.progress(c, 30, 166, 180, 14, m.progress.toDouble());
    }
  }
}
