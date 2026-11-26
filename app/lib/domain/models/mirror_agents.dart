// What the DeviceMirror needs to draw the agent / desktop / setup / photo channels (design 2026-11-26.5, firmware
// src/channels/ch_attention.cpp, ch_home.cpp, ch_setup.cpp, ch_photo.cpp). Built by domain/rules/mirror_agent_rules.dart
// from /api/state, /push and /api/settings; words are added by the painters (`devXp…` strings).
import 'dart:typed_data';

/// Card kind, in the firmware's priority order (`Attention::Kind`).
enum CardKind { approval, error, input, progress, warning, success, info }

/// Who sent the card (`Attention::Agent`).
enum CardAgent { claude, codex, other }

/// Clawd's eyes on the card (`eyesFor`); the blink / walk animation is not mirrored.
enum ClawdEyes { open, wide, happy, sad }

/// How the card body reads: as sent, "Claude finished" → "Claude đã xong", or a question's notification →
/// "Claude đang chờ câu trả lời".
enum CardBody { plain, finished, waiting }

/// The interrupt card on the Attention channel (`paintCard`).
class MirrorCard {
  const MirrorCard({
    required this.kind,
    this.agent = CardAgent.other,
    this.project = '',
    this.ownTitle,
    this.progress = -1,
    this.lead = '',
    this.body = '',
    this.bodyForm = CardBody.plain,
    this.ageS = 0,
    this.index = 0,
    this.count = 1,
  });

  final CardKind kind;
  final CardAgent agent;
  final String project;

  /// The agent's own title; null = the built-in title of [kind] (hook titles DONE, APPROVAL NEEDED…).
  final String? ownTitle;

  /// 0…100 for progress cards, −1 = none.
  final int progress;

  /// Approval: "Bash · pio run" (tool · command); other kinds: the card's value ('' = none).
  final String lead;

  /// Body after [lead]: the text ([CardBody.plain]) or the name ([CardBody.finished]); '' for [CardBody.waiting].
  final String body;
  final CardBody bodyForm;

  /// Seconds since the card arrived (at the last read).
  final int ageS;

  /// Which of several cards holding the screen ("· 1/2"); the device cycles them every 6 s.
  final int index, count;

  /// Approvals and questions: the waiting rule + "chờ bạn · 2P".
  bool get waits => kind == CardKind.approval || kind == CardKind.input;

  ClawdEyes get eyes => switch (kind) {
    CardKind.approval || CardKind.warning => ClawdEyes.wide,
    CardKind.success => ClawdEyes.happy,
    CardKind.error => ClawdEyes.sad,
    _ => ClawdEyes.open,
  };
}

/// Title of a row in the Agents list.
enum RowTitle {
  /// approval: "Cần bạn" (+ " · tool").
  needYou,

  /// input: "Lượt bạn" (+ " · tool").
  yourTurn,

  /// The agent's own title, sentence case ([AgentRow.text]).
  own,

  /// Hook title DONE → "Xong".
  hookDone,

  /// Hook title APPROVAL NEEDED → "Cần duyệt".
  hookApproval,

  /// Hook title WAITING FOR YOU → "Đang chờ bạn".
  hookWaiting,

  /// No title: the kind's word ("Phê duyệt", "Tiến độ"…).
  kindWord,
}

/// One row of the Agents list box (`listRow`).
class AgentRow {
  const AgentRow({
    required this.kind,
    required this.title,
    this.text = '',
    this.suffix = '',
    this.agent = CardAgent.other,
    this.project = '',
    this.ageS = 0,
    this.selected = false,
  });

  final CardKind kind;
  final RowTitle title;

  /// The own title (sentence case) for [RowTitle.own].
  final String text;

  /// After " · ": the tool (waiting rows), "64%" or the value; '' = none.
  final String suffix;
  final CardAgent agent;
  final String project;
  final int ageS;

  /// First row waiting on the user: drawn selected (blue, white text).
  final bool selected;
}

/// The Agents channel (`paintList`): up to 3 rows (more → 2 rows + "+ N mục khác") and the status bar counts.
class AgentsList {
  const AgentsList({this.rows = const [], this.total = 0, this.approvals = 0, this.inputs = 0});

  /// Rows drawn (≤ 3).
  final List<AgentRow> rows;

  /// Visible cards in the queue.
  final int total;
  final int approvals, inputs;

  /// Cards not drawn ("+ N mục khác"), 0 = none.
  int get more => total - rows.length;
}

/// The XP desktop (Home, `ch_home.cpp`).
class DesktopView {
  const DesktopView({
    this.claudePct,
    this.codexPct,
    this.balloon = false,
    this.tipBalloon = false,
    this.temp,
    this.feels,
    this.desc = '',
    this.icons = const [],
  });

  /// Desktop icons, one per program of the enabled skills + the trash (panel P-2026-11-26.14, XP Auto Arrange).
  final List<DeskIcon> icons;

  /// % used shown under the Claude / Codex icon; null = the bare name (no key, loading, a key problem).
  final int? claudePct, codexPct;

  /// Weather balloon over the tray: up now.
  final bool balloon;

  /// It is the XP notification balloon of panel P-2026-11-26.15 (box at (96, 138), × button, tail to the tray icon),
  /// up only while the device says so; false = firmware before it (the always-on balloon at (100, 150)).
  final bool tipBalloon;

  /// Temperature now / feels like in the unit of the settings; [temp] null = "chưa có thời tiết".
  final int? temp, feels;
  final String desc;
}

/// One desktop icon: [program] it opens (null = Thùng rác), column centre [cx] and cell top [y] (cells 48 tall).
class DeskIcon {
  const DeskIcon(this.program, this.cx, this.y);

  final String? program;
  final int cx, y;

  @override
  bool operator ==(Object other) => other is DeskIcon && other.program == program && other.cx == cx && other.y == y;

  @override
  int get hashCode => Object.hash(program, cx, y);

  @override
  String toString() => 'DeskIcon($program, $cx, $y)';
}

/// The first-run checklist (Setup, `ch_setup.cpp`).
class SetupView {
  const SetupView({this.claude = false, this.codex = false, this.weather = false, this.ip = ''});

  /// Done: Claude key, Codex token, weather location.
  final bool claude, codex, weather;
  final String ip;

  int get left => (claude ? 0 : 1) + (codex ? 0 : 1) + (weather ? 0 : 1);
}

/// The Photo channel (`ch_photo.cpp`): [count] photos on the device and the app's copy of one of them.
class MirrorPhoto {
  const MirrorPhoto({this.count = 0, this.index = 0, this.jpeg});

  final int count;

  /// Device order of the photo drawn (the device's own position in the rotation is not in /api/state).
  final int index;

  /// The JPEG this app sent for that photo; null = no copy (another phone sent it).
  final Uint8List? jpeg;

  bool get empty => count <= 0;
}

/// Short duration of the device ("45P", "6G", "2NG" — `TimeUtil::shortDuration`).
enum DurUnit { minutes, hours, days }

/// `TimeUtil::shortDuration` of [seconds]: < 1 h minutes, < 48 h hours (rounded), else days (rounded).
(int, DurUnit) shortDurationOf(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  if (s < 3600) return (s ~/ 60, DurUnit.minutes);
  if (s < 172800) return ((s + 1800) ~/ 3600, DurUnit.hours);
  return ((s + 43200) ~/ 86400, DurUnit.days);
}

/// Attention / Agents / Home / Setup / Photo values of a frame (`agentsMirrorOf`).
class AgentsMirror {
  const AgentsMirror({
    this.card,
    this.list = const AgentsList(),
    this.desktop = const DesktopView(),
    this.setup = const SetupView(),
    this.photo = const MirrorPhoto(),
  });

  /// The Attention card; null = empty queue (bare "Tác tử" window).
  final MirrorCard? card;
  final AgentsList list;
  final DesktopView desktop;
  final SetupView setup;
  final MirrorPhoto photo;
}
