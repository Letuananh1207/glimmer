// Agent / desktop / setup / photo channels of the DeviceMirror (design 2026-11-26.5) — the firmware's logic of
// src/channels/ch_attention.cpp, ch_home.cpp, ch_setup.cpp, ch_photo.cpp as pure functions; called by mirrorFrameOf.
import '../models/attention_card.dart';
import '../models/device_photo.dart';
import '../models/device_state.dart';
import '../models/mirror_agents.dart';
import 'skill_rules.dart';

/// `kind` of a /push card (unknown → info).
CardKind cardKind(String kind) => switch (kind) {
  'approval' => CardKind.approval,
  'error' => CardKind.error,
  'input' => CardKind.input,
  'progress' => CardKind.progress,
  'warning' => CardKind.warning,
  'success' => CardKind.success,
  _ => CardKind.info,
};

CardAgent cardAgent(String agent) => switch (agent) {
  'claude' => CardAgent.claude,
  'codex' => CardAgent.codex,
  _ => CardAgent.other,
};

bool _waits(CardKind k) => k == CardKind.approval || k == CardKind.input;

/// How long an interrupt card holds the screen after it arrives (`kInterruptS`).
const interruptS = 30;

/// Cards showing now (Codex "your turn" waits until `shows_in_s` is 0), in the device's order (GET /push is
/// already priority then oldest first).
List<AttentionCard> visibleCards(List<AttentionCard> cards) => [
  for (final c in cards)
    if (c.showsInS <= 0) c,
];

/// Cards holding the Attention screen (`holdsScreen`): approvals / questions while [pin] (`pinApprovals`), others
/// for [interruptS] after they arrive. /push does not say how long a pushed card asked to interrupt, so a card
/// with its own duration counts as 30 s.
List<AttentionCard> screenHolders(List<AttentionCard> cards, {bool pin = true}) => [
  for (final c in visibleCards(cards))
    if ((pin && _waits(cardKind(c.kind))) || c.ageS < interruptS) c,
];

/// "Bash: pio run" → (tool "Bash", detail "pio run"); "wants to use Bash" → ("Bash", ''); else ('', body).
(String, String) toolAndDetail(String body) {
  final colon = body.indexOf(': ');
  if (colon > 0 && colon < 20) return (body.substring(0, colon), body.substring(colon + 2));
  final use = body.indexOf('use ');
  if (use >= 0) return (body.substring(use + 4), '');
  return ('', body);
}

const _hookTitles = {'', 'APPROVAL NEEDED', 'WAITING FOR YOU', 'DONE'};

String _join(String a, String b) => a.isNotEmpty && b.isNotEmpty ? '$a · $b' : (a.isNotEmpty ? a : b);

/// The card [c] as the Attention window draws it ([index] of [count] holders).
MirrorCard mirrorCardOf(AttentionCard c, {int index = 0, int count = 1}) {
  final kind = cardKind(c.kind);
  final agent = cardAgent(c.agent);
  var lead = c.value;
  var body = c.body;
  var form = CardBody.plain;
  if (kind == CardKind.approval) {
    final (tool, detail) = toolAndDetail(c.body);
    lead = _join(tool, detail);
    body = '';
  } else {
    final f = c.body.indexOf(' finished');
    if (f >= 0 && f < 12 && f + 9 == c.body.length) {
      form = CardBody.finished;
      body = c.body.substring(0, f);
    } else if (kind == CardKind.input && (c.body.isEmpty || c.body.contains('waiting for your input'))) {
      form = CardBody.waiting;
      body = '';
    }
  }
  return MirrorCard(
    kind: kind,
    agent: agent,
    project: c.project,
    ownTitle: _hookTitles.contains(c.title) ? null : c.title,
    progress: kind == CardKind.progress ? c.progress : -1,
    lead: lead,
    body: body,
    bodyForm: form,
    ageS: c.ageS,
    index: index,
    count: count,
  );
}

/// The card on the Attention channel: the first holder (the device starts from the top on each arrival), or the
/// first visible card when none holds the screen (the mirror switched there itself); null = empty queue.
MirrorCard? attentionOf(List<AttentionCard> cards, Map<String, dynamic>? settings) {
  final holders = screenHolders(cards, pin: settings?['pinApprovals'] != false);
  if (holders.isNotEmpty) return mirrorCardOf(holders.first, count: holders.length);
  final shown = visibleCards(cards);
  return shown.isEmpty ? null : mirrorCardOf(shown.first);
}

/// Sentence case like `Utf8::sentence`: first character kept, the rest lower case.
String sentenceCase(String s) => s.isEmpty ? s : s[0] + s.substring(1).toLowerCase();

AgentRow _row(AttentionCard c, bool selected) {
  final kind = cardKind(c.kind);
  RowTitle title;
  var text = '';
  String suffix;
  if (_waits(kind)) {
    title = kind == CardKind.approval ? RowTitle.needYou : RowTitle.yourTurn;
    suffix = toolAndDetail(c.body).$1;
  } else {
    title = switch (c.title) {
      '' => RowTitle.kindWord,
      'DONE' => RowTitle.hookDone,
      'APPROVAL NEEDED' => RowTitle.hookApproval,
      'WAITING FOR YOU' => RowTitle.hookWaiting,
      _ => RowTitle.own,
    };
    if (title == RowTitle.own) text = sentenceCase(c.title);
    suffix = c.progress >= 0 ? '${c.progress}%' : c.value;
  }
  return AgentRow(
    kind: kind,
    title: title,
    text: text,
    suffix: suffix,
    agent: cardAgent(c.agent),
    project: c.project,
    ageS: c.ageS,
    selected: selected,
  );
}

/// The Agents list box: > 3 cards → 2 rows + "+ N mục khác"; the first row is selected when it waits on the user.
AgentsList agentsListOf(List<AttentionCard> cards) {
  final shown = visibleCards(cards);
  final n = shown.length > 3 ? 2 : shown.length;
  return AgentsList(
    rows: [for (var i = 0; i < n; i++) _row(shown[i], i == 0 && _waits(cardKind(shown[i].kind)))],
    total: shown.length,
    approvals: shown.where((c) => c.kind == 'approval').length,
    inputs: shown.where((c) => c.kind == 'input').length,
  );
}

const _badCred = {'not_set', 'expired', 'rejected', 'blocked'};

int _toDisplay(double c, bool fahrenheit) => (fahrenheit ? c * 9 / 5 + 32 : c).round();

/// Desktop icons (panel P-2026-11-26.14 §17 XP-Desk): column 0 (centre x 40) Claude, Codex, Ảnh then the trash;
/// column 1 (centre x 120) Thời tiết, Đồng hồ — cells 48 tall from y 8, column 1 stops above the weather balloon.
List<DeskIcon> deskIconsOf(List<String> skillsOn) {
  const x0 = 40, x1 = 120, y0 = 8, cell = 48;
  final col0 = <String?>[
    if (skillsOn.contains(SkillIds.agent)) ...['Claude', 'Codex'],
    if (skillsOn.contains(SkillIds.photo)) 'Photo',
    null,
  ];
  final col1 = [if (skillsOn.contains(SkillIds.weather)) 'Weather', if (skillsOn.contains(SkillIds.clock)) 'Clock'];
  return [
    for (final (i, p) in col0.indexed) DeskIcon(p, x0, y0 + cell * i),
    for (final (i, p) in col1.indexed) DeskIcon(p, x1, y0 + cell * i),
  ];
}

/// The desktop (`labelText`, `balloonText`): Claude's hero % (weekly when `claudeWeeklyHero`) unless a key
/// problem or no number; Codex usage is not in /api/state (always the bare name); the balloon when a location is set.
DesktopView desktopOf(DeviceState s, Map<String, dynamic>? settings) {
  final u = s.usage;
  final used = settings?['claudeWeeklyHero'] == true ? u.weeklyUsed : u.sessionUsed;
  final credOk = s.claudeConfigured && !_badCred.contains(u.cred);
  final w = s.weather;
  final f = settings?['useFahrenheit'] == true;
  final valid = w != null && w.valid && w.tempC != null;
  final on = s.skillsOn.isEmpty ? const [SkillIds.agent] : s.skillsOn;
  return DesktopView(
    claudePct: credOk && used >= 0 ? used : null,
    balloon: s.weatherConfigured && on.contains(SkillIds.weather),
    icons: deskIconsOf(on),
    temp: valid ? _toDisplay(w.tempC!, f) : null,
    feels: valid && w.feelsC != null ? _toDisplay(w.feelsC!, f) : null,
    desc: valid ? w.desc : '',
  );
}

/// The Setup checklist: a key counts as set when the settings show a (masked) value, or the state says so.
SetupView setupOf(DeviceState s, Map<String, dynamic>? settings) {
  bool set(String k) => (settings?[k] as String? ?? '').isNotEmpty;
  return SetupView(
    claude: s.claudeConfigured || set('claudeKey'),
    codex: set('codexToken'),
    weather: s.weatherConfigured,
    ip: s.ip,
  );
}

/// The Photo channel: [count] photos on the device (`/api/state.photos`, else the gallery's) and the first one the
/// app has a copy of (the device's position in its rotation is not reported).
MirrorPhoto mirrorPhotoOf(int? count, PhotoGallery? gallery) {
  final n = count ?? gallery?.info.count ?? 0;
  final items = gallery?.items ?? const <GalleryPhoto>[];
  for (var i = 0; i < items.length && i < n; i++) {
    final jpeg = items[i].preview;
    if (jpeg != null) return MirrorPhoto(count: n, index: i, jpeg: jpeg);
  }
  return MirrorPhoto(count: n);
}

/// Values of the Attention, Agents, Home, Setup and Photo painters for a frame of [s].
AgentsMirror agentsMirrorOf(
  DeviceState s,
  List<AttentionCard> cards,
  Map<String, dynamic>? settings, {
  PhotoGallery? gallery,
}) => AgentsMirror(
  card: attentionOf(cards, settings),
  list: agentsListOf(cards),
  desktop: desktopOf(s, settings),
  setup: setupOf(s, settings),
  photo: mirrorPhotoOf(s.photos, gallery),
);
