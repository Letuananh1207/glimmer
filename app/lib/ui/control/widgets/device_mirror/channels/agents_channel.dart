import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';
import 'agent_bits.dart';

/// Agents — the queue as an XP list box (`ch_attention.cpp` paintList, XP-Agents / XP-Agents-Idle): window
/// "Tác tử", list box (10, 28, 220×162), rows every 52 px from y 30 (■ 8×8 kind colour at (18, y+9), title 12B
/// (32, y+6), meta JBMono-11 muted (32, y+26)); the first row selected when it waits on the user; > 3 cards → 2
/// rows + "+ N mục khác"; status bar "3 mục" · "1 cần duyệt" / "không mục nào chờ".
class AgentsChannel extends MirrorChannel {
  const AgentsChannel();

  static const _rowX = 11, _rowW = 218, _row0 = 30, _pitch = 52, _rowH = 50, _textX = 32, _textW = 192.0;

  static String _title(AppLocalizations l, AgentRow r) {
    final t = switch (r.title) {
      RowTitle.needYou => l.devXpRowNeedYou,
      RowTitle.yourTurn => l.devXpCardInput,
      RowTitle.own => r.text,
      RowTitle.hookDone => l.devXpCardDone,
      RowTitle.hookApproval => l.devXpCardApproval,
      RowTitle.hookWaiting => l.devXpRowWaitingYou,
      RowTitle.kindWord => l.devXpKindWord(r.kind.name),
    };
    return r.suffix.isEmpty ? t : '$t · ${r.suffix}';
  }

  static String _meta(AppLocalizations l, AgentRow r) {
    final age = AgentBits.shortDuration(l, shortDurationOf(r.ageS)).toLowerCase();
    final a = switch (r.agent) {
      CardAgent.claude => 'claude',
      CardAgent.codex => 'codex',
      CardAgent.other => '',
    };
    return [a, r.project, age].where((s) => s.isNotEmpty).join(' · ');
  }

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final list = f.agents.list;
    Xp.window(c, l.devXpTitleAgents, statusBar: true);
    Xp.field(c, 10, 28, 220, 162);
    for (var i = 0; i < list.rows.length; i++) {
      final r = list.rows[i];
      final y = _row0 + i * _pitch;
      if (r.selected) c.fill(_rowX, y, _rowW, _rowH, XpColors.select);
      c.fill(18, y + 9, 8, 8, AgentBits.kindColor(r.kind));
      final ink = r.selected ? XpColors.white : XpColors.black;
      c.text(AgentBits.fitDots(c, _title(l, r), XpFont.jb12b, _textW), _textX, y + 7, XpFont.jb12b, ink);
      c.text(
        AgentBits.fitDots(c, _meta(l, r), XpFont.jb11, _textW),
        _textX,
        y + 26,
        XpFont.jb11,
        r.selected ? XpColors.white : XpColors.muted,
      );
      if (i < 2 && !r.selected) c.hLine(_rowX, y + _rowH, _rowW, XpColors.rowLine);
    }
    if (list.more > 0) {
      c.text(l.devXpMoreItems(list.more), _textX, _row0 + list.rows.length * _pitch + 18, XpFont.jb11, XpColors.muted);
    }
    final right = list.approvals > 0
        ? l.devXpNApprovals(list.approvals)
        : list.inputs > 0
        ? l.devXpNInputs(list.inputs)
        : l.devXpNoneWaiting;
    Xp.statusBar(c, l.devXpItems(list.total), right);
  }
}
