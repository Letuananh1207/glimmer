// The usage windows of the DeviceMirror from /api/state — the firmware's own decisions (ch_claude.cpp,
// ch_codex.cpp, ch_aidash.cpp, ch_trend.cpp, chrome.cpp, api.cpp, timeutil.h), so the mirror shows what the device
// draws. Called from `mirrorFrameOf`.
import '../models/device_state.dart';
import '../models/usage_mirror.dart';
import 'time_rules.dart';
import 'usage_rules.dart';

const _synced = 1000000000;

/// `TimeUtil::countdown` to [resetEpoch] at [now]: "4NG" (≥ 24 h), "2G 14P", "14P", "ngay" once passed; "--" while
/// the reset or the clock is unknown (`Api::formatCountdown`).
DevSpan countdownSpan(int resetEpoch, int now) {
  if (now < _synced || resetEpoch <= 0) return DevSpan.unknown;
  final diff = resetEpoch - now;
  if (diff <= 0) return const DevSpan(SpanKind.now);
  final h = diff ~/ 3600, m = (diff % 3600) ~/ 60;
  if (h >= 24) return DevSpan(SpanKind.days, (h + 12) ~/ 24);
  if (h >= 1) return DevSpan(SpanKind.hoursMinutes, h, m);
  return DevSpan(SpanKind.minutes, m);
}

/// `TimeUtil::shortDuration`: "14P" (< 1 h), "2G" (< 48 h, rounded), "3NG".
DevSpan shortSpan(int sec) {
  final s = sec < 0 ? 0 : sec;
  if (s < 3600) return DevSpan(SpanKind.minutes, s ~/ 60);
  if (s < 172800) return DevSpan(SpanKind.hours, (s + 1800) ~/ 3600);
  return DevSpan(SpanKind.days, (s + 43200) ~/ 86400);
}

CredKind credKind(String name) => switch (name) {
  'not_set' => CredKind.notSet,
  'checking' => CredKind.checking,
  'ok' => CredKind.ok,
  'expiring' => CredKind.expiring,
  'expired' => CredKind.expired,
  'rejected' => CredKind.rejected,
  'blocked' => CredKind.blocked,
  _ => CredKind.unknown,
};

/// `Api::isStale`: older than 3 refresh intervals, 15-minute floor; never before a first fetch or clock sync.
bool staleAt(int lastOk, int now, int refreshMin) {
  if (lastOk <= 0 || now < _synced) return false;
  final limit = refreshMin * 180 < 900 ? 900 : refreshMin * 180;
  return now - lastOk > limit;
}

/// `xpUsageMeta`: credential problem > cũ 14P > hạn 2NG > vendor status (fresh < 1 h, `showStatus`) > [label].
TitleMeta titleMetaOf({
  required CredKind cred,
  required int lastOk,
  required int now,
  required int refreshMin,
  int jwtExp = 0,
  String vendorLevel = '',
  int vendorOk = 0,
  String label = '',
}) {
  if (cred.bad) return TitleMeta(cred == CredKind.blocked ? MetaKind.blocked : MetaKind.keyBad);
  if (staleAt(lastOk, now, refreshMin)) return TitleMeta(MetaKind.stale, span: shortSpan(now - lastOk));
  if (cred == CredKind.expiring && jwtExp > now) {
    return TitleMeta(MetaKind.expiring, span: shortSpan(jwtExp - now));
  }
  if (vendorOk > 0 && now - vendorOk < 3600) {
    switch (vendorLevel) {
      case 'maintenance':
        return const TitleMeta(MetaKind.maintenance);
      case 'minor':
        return const TitleMeta(MetaKind.minor);
      case 'major' || 'critical':
        return const TitleMeta(MetaKind.major);
    }
  }
  return label.isEmpty ? TitleMeta.none : TitleMeta(MetaKind.label, label: label);
}

/// `Chrome::credCard`: the message box of a window with nothing to show and something wrong. The firmware's
/// offline text is its transport error, i.e. a negative last HTTP [code].
CredCard credCardOf(CredKind cred, String err, {int code = 0, int expiresAt = 0, int tzMinutes = 0, String ip = ''}) =>
    switch (cred) {
      CredKind.rejected => CredCard(CredCardKind.rejected, ip: ip),
      CredKind.expired => CredCard(
        CredCardKind.expired,
        expiry: expiresAt > 0 ? deviceLocal(expiresAt, tzMinutes) : null,
        ip: ip,
      ),
      CredKind.blocked => const CredCard(CredCardKind.blocked),
      CredKind.notSet => CredCard(CredCardKind.notSet, ip: ip),
      _ when err.isEmpty || code < 0 => const CredCard(CredCardKind.offline),
      _ => CredCard(CredCardKind.upstream, err: err),
    };

/// Which body: message box (no data + bad key / error), loading (no data yet), or the figures.
UsageView usageView(bool valid, CredKind cred, String err) =>
    valid ? UsageView.data : (cred.bad || err.isNotEmpty ? UsageView.card : UsageView.loading);

/// `clawdFrame`: asleep with nothing on the board or when the most urgent row is done; wide-eyed for an approval,
/// sad for an error, walking while working, open otherwise. (The mirror does not blink.)
ClawdPose clawdPoseOf(List<BoardRow> rows) {
  if (rows.isEmpty) return const ClawdPose(ClawdMood.sleep);
  return switch (rows.first.state) {
    'approval' => const ClawdPose(ClawdMood.wide),
    'error' => const ClawdPose(ClawdMood.sad),
    'done' => const ClawdPose(ClawdMood.sleep),
    'working' => const ClawdPose(ClawdMood.open, walk: true),
    _ => const ClawdPose(ClawdMood.open),
  };
}

int _refreshMin(Map<String, dynamic>? settings) => (settings?['refreshMin'] as num?)?.toInt() ?? 5;
int _tz(Map<String, dynamic>? settings) => (settings?['tzMinutes'] as num?)?.toInt() ?? 0;

/// Claude window (`chClaudeDraw`).
ClaudeMirror claudeMirrorOf(DeviceState s, Map<String, dynamic>? settings) {
  final u = s.usage;
  final now = s.time;
  final cred = credKind(u.cred.isNotEmpty ? u.cred : s.sources.claude.cred);
  final view = usageView(s.claudeValid, cred, s.claudeErr);
  final meta = titleMetaOf(
    cred: cred,
    lastOk: u.lastOk,
    now: now,
    refreshMin: _refreshMin(settings),
    vendorLevel: s.sources.claudeStatus,
    vendorOk: s.sources.claudeStatusOk,
  );
  if (view != UsageView.data) {
    return ClaudeMirror(
      view: view,
      meta: meta,
      cred: cred,
      card: view == UsageView.card ? credCardOf(cred, s.claudeErr, code: s.sources.claude.code, ip: s.ip) : null,
    );
  }
  final weekly = settings?['claudeWeeklyHero'] == true;
  final heroUsed = weekly ? u.weeklyUsed : u.sessionUsed;
  final secUsed = weekly ? u.sessionUsed : u.weeklyUsed;
  final rows = [
    for (final p in s.projects)
      if (p.shown) BoardRow(p.project, p.state, p.detail, shortSpan(p.ageS)),
  ];
  return ClaudeMirror(
    view: view,
    meta: meta,
    weeklyHero: weekly,
    heroUsed: heroUsed,
    secUsed: secUsed,
    heroLevel: usageLevel(heroUsed),
    secLevel: usageLevel(secUsed),
    heroReset: countdownSpan(weekly ? u.weeklyReset : u.sessionReset, now),
    secReset: countdownSpan(weekly ? u.sessionReset : u.weeklyReset, now),
    stale: u.stale,
    cred: cred,
    clawd: clawdPoseOf(rows),
    rows: List.unmodifiable(rows),
  );
}

/// `Chrome::resetsText` source: credits left and when they expire (a week or less → span, else the date).
ResetCredits resetCreditsOf(SourceHealth h, int now, int tzMinutes) {
  if (h.resetsLeft <= 0) return ResetCredits.none;
  final end = h.resetsEndsAt;
  if (end > 0 && now >= _synced && end > now) {
    return end - now < 7 * 86400
        ? ResetCredits(left: h.resetsLeft, span: shortSpan(end - now))
        : ResetCredits(left: h.resetsLeft, until: deviceLocal(end, tzMinutes));
  }
  return ResetCredits(left: h.resetsLeft);
}

/// Codex window (`chCodexDraw`). `/api/state` has no Codex figures (windows, %, resets, credits, pace): those
/// stay unknown and draw "--".
CodexMirror codexMirrorOf(DeviceState s, Map<String, dynamic>? settings) {
  final h = s.sources.codex;
  final now = s.time;
  final cred = credKind(h.cred);
  final view = usageView(h.valid, cred, h.err);
  final meta = titleMetaOf(
    cred: cred,
    lastOk: h.lastOk,
    now: now,
    refreshMin: _refreshMin(settings),
    jwtExp: h.expiresAt,
    vendorLevel: s.sources.openaiStatus,
    vendorOk: s.sources.openaiStatusOk,
    label: (settings?['codexModelLabel'] as String?) ?? '',
  );
  return CodexMirror(
    view: view,
    meta: meta,
    card: view == UsageView.card
        ? credCardOf(cred, h.err, code: h.code, expiresAt: h.expiresAt, tzMinutes: _tz(settings), ip: s.ip)
        : null,
    resets: resetCreditsOf(h, now, _tz(settings)),
    stale: view == UsageView.data && staleAt(h.lastOk, now, _refreshMin(settings)),
    cred: cred,
  );
}

/// `claudeLoading` / `codexLoading`: configured, never fetched, nothing to report yet.
bool _loading(bool valid, String err, CredKind cred) => !valid && err.isEmpty && !cred.bad && cred != CredKind.notSet;

AiMode _aiMode(CredKind cred, bool loading, bool stale) =>
    cred.bad ? AiMode.credBad : (loading ? AiMode.loading : (stale ? AiMode.stale : AiMode.value));

/// `adviceText` on % REMAINING: a nearly-out provider with a usable reset credit, else the one resetting within
/// 48 h with ≥ 25 % unused (soonest), else the one with more room ("Cả hai sắp hết" under 15 %). Null without
/// both figures or a set clock.
AiAdvice? aiAdvice({
  required int now,
  required double? claudeLeft,
  required int claudeReset,
  required int claudeCredits,
  required bool claudeUsable,
  required double? codexLeft,
  required int codexReset,
  required int codexCredits,
  required bool codexUsable,
}) {
  if (claudeLeft == null || codexLeft == null || claudeLeft < 0 || codexLeft < 0 || now < _synced) return null;
  final c = [
    (claude: true, pct: claudeLeft, reset: claudeReset, left: claudeCredits, usable: claudeUsable),
    (claude: false, pct: codexLeft, reset: codexReset, left: codexCredits, usable: codexUsable),
  ];
  for (final k in c) {
    if (k.pct < 15 && k.left > 0 && k.usable) return AiAdvice(AdviceKind.resets, claude: k.claude, left: k.left);
  }
  int? pick;
  for (var i = 0; i < 2; i++) {
    final left = c[i].reset - now;
    if (c[i].reset <= now || left > 48 * 3600 || c[i].pct < 25) continue;
    if (pick == null || c[i].reset < c[pick].reset) pick = i;
  }
  if (pick == null) {
    pick = c[0].pct >= c[1].pct ? 0 : 1;
    if (c[pick].pct < 15) return const AiAdvice(AdviceKind.bothLow);
  }
  return AiAdvice(AdviceKind.use, claude: c[pick].claude);
}

/// AI hôm nay window (`chAiDashDraw`). Codex % / credits / reset are not in `/api/state`: "--", no advice.
AiMirror aiMirrorOf(DeviceState s, Map<String, dynamic>? settings) {
  final now = s.time;
  final rm = _refreshMin(settings);
  final u = s.usage;
  final weekly = settings?['claudeWeeklyHero'] == true;
  final clCred = credKind(u.cred.isNotEmpty ? u.cred : s.sources.claude.cred);
  final clStale = s.claudeValid && u.stale;
  final clUsed = weekly ? u.weeklyUsed : u.sessionUsed;
  final clReset = weekly ? u.weeklyReset : u.sessionReset;
  final clLoading = _loading(s.claudeValid, s.claudeErr, clCred);
  final cx = s.sources.codex;
  final cxCred = credKind(cx.cred);
  final cxStale = cx.valid && staleAt(cx.lastOk, now, rm);
  final cxLoading = _loading(cx.valid, cx.err, cxCred);
  int? oldest;
  if (clStale) oldest = u.lastOk;
  if (cxStale && (oldest == null || cx.lastOk < oldest)) oldest = cx.lastOk;
  return AiMirror(
    claude: AiSide(
      mode: _aiMode(clCred, clLoading, clStale),
      used: clUsed,
      level: usageLevel(clUsed),
      cred: clCred,
      reset: clLoading || clReset <= 0 ? null : countdownSpan(clReset, now),
    ),
    codex: AiSide(mode: _aiMode(cxCred, cxLoading, cxStale), cred: cxCred),
    staleAge: oldest == null ? null : shortSpan(now - oldest),
  );
}

/// Xu hướng window (`chTrendDraw`): providers with a key, the 7 weekday columns. The usage history ring is not in
/// `/api/state`: bars, "Có N / 7 ngày" and "cuối 3/8" stay unknown.
TrendMirror trendMirrorOf(DeviceState s, Map<String, dynamic>? settings) {
  final tz = _tz(settings);
  return TrendMirror(
    blocks: [
      if (s.claudeConfigured)
        TrendBlock(claude: true, cred: credKind(s.usage.cred.isNotEmpty ? s.usage.cred : s.sources.claude.cred)),
      if (s.codexConfigured) TrendBlock(claude: false, cred: credKind(s.sources.codex.cred)),
    ],
    weekdays: s.clockSynced ? [for (var k = 6; k >= 0; k--) deviceLocal(s.time - k * 86400, tz).weekday] : const [],
  );
}

/// All four usage windows of [s].
UsageMirror usageMirrorOf(DeviceState s, Map<String, dynamic>? settings) => UsageMirror(
  claude: claudeMirrorOf(s, settings),
  codex: codexMirrorOf(s, settings),
  ai: aiMirrorOf(s, settings),
  trend: trendMirrorOf(s, settings),
);
