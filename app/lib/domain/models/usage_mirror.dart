// What the DeviceMirror's usage channels show — Claude, Codex, AI hôm nay, Xu hướng (firmware ch_claude.cpp,
// ch_codex.cpp, ch_aidash.cpp, ch_trend.cpp, chrome.cpp). Built by `usageMirrorOf` (domain/rules/
// usage_mirror_rules.dart) from /api/state; painted by ui/control/widgets/device_mirror/channels/. Words are
// enums here — the painters turn them into `devXp…` strings.
import 'clawd_mood.dart';
import 'usage_meta.dart';
export 'clawd_mood.dart';
export 'usage_meta.dart' show UsageLevel;

/// A span of time as the device writes it: `TimeUtil::countdown` ("4NG", "2G 14P", "14P", "ngay") or
/// `TimeUtil::shortDuration` ("14P", "2G", "3NG"); [none] = "--" (unknown / clock not set).
enum SpanKind { none, now, minutes, hours, hoursMinutes, days }

class DevSpan {
  const DevSpan(this.kind, [this.a = 0, this.b = 0]);

  static const unknown = DevSpan(SpanKind.none);

  final SpanKind kind;

  /// Days / hours / minutes (first number) and the minutes of [SpanKind.hoursMinutes].
  final int a, b;

  @override
  bool operator ==(Object other) => other is DevSpan && other.kind == kind && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(kind, a, b);

  @override
  String toString() => 'DevSpan($kind, $a, $b)';
}

/// Window title meta (`xpUsageMeta`): khóa lỗi / bị chặn > cũ 14P > hạn 2NG > vendor badge > the channel's own.
enum MetaKind { none, keyBad, blocked, stale, expiring, maintenance, minor, major, label }

class TitleMeta {
  const TitleMeta(this.kind, {this.span = DevSpan.unknown, this.label = ''});

  static const none = TitleMeta(MetaKind.none);

  final MetaKind kind;

  /// Age of the data ([MetaKind.stale]) or time to the token's expiry ([MetaKind.expiring]).
  final DevSpan span;

  /// [MetaKind.label]: the Codex model label ("GPT-5").
  final String label;
}

/// Credential as `/api/state` names it.
enum CredKind { unknown, notSet, checking, ok, expiring, expired, rejected, blocked }

extension CredKindX on CredKind {
  /// `CredState::bad`: the key does not work (expired / rejected / blocked).
  bool get bad => this == CredKind.expired || this == CredKind.rejected || this == CredKind.blocked;
}

/// The XP message box over an empty window (`Chrome::credCard`).
enum CredCardKind { rejected, expired, blocked, notSet, offline, upstream }

class CredCard {
  const CredCard(this.kind, {this.expiry, this.err = '', this.ip = ''});

  final CredCardKind kind;

  /// Device-local expiry date of the token ([CredCardKind.expired]); null = unknown ("Đã hết hạn.").
  final DateTime? expiry;

  /// Upstream error text ([CredCardKind.upstream], e.g. "HTTP 503").
  final String err;

  /// Device IP under the `glimmer.local` link.
  final String ip;
}

/// Which body a usage window draws.
enum UsageView { card, loading, data }

/// One project row of the Claude field (`paintProjectRow`).
class BoardRow {
  const BoardRow(this.project, this.state, this.detail, this.age);

  final String project;

  /// approval / input / error / working / done.
  final String state;
  final String detail;

  /// Time in this state (`shortDuration`).
  final DevSpan age;
}

/// Clawd 72×40 on the Claude screen (`clawdFrame`): mood from the most urgent board row; [walk] = mid-stride legs.
class ClawdPose {
  const ClawdPose(this.mood, {this.walk = false});

  final ClawdMood mood;
  final bool walk;

  bool get asleep => mood == ClawdMood.sleep;
}

/// Claude window (`ch_claude.cpp`).
class ClaudeMirror {
  const ClaudeMirror({
    this.view = UsageView.loading,
    this.card,
    this.meta = TitleMeta.none,
    this.weeklyHero = false,
    this.heroUsed = -1,
    this.secUsed = -1,
    this.heroLevel = UsageLevel.unknown,
    this.secLevel = UsageLevel.unknown,
    this.heroReset = DevSpan.unknown,
    this.secReset = DevSpan.unknown,
    this.stale = false,
    this.cred = CredKind.unknown,
    this.clawd = const ClawdPose(ClawdMood.sleep),
    this.rows = const [],
  });

  final UsageView view;
  final CredCard? card;
  final TitleMeta meta;

  /// Hero = the weekly window (`claudeWeeklyHero`), else the 5-hour session.
  final bool weeklyHero;

  /// % used, −1 = unknown ("--").
  final int heroUsed, secUsed;

  /// Bar colour from % remaining (R-DUNG-1).
  final UsageLevel heroLevel, secLevel;
  final DevSpan heroReset, secReset;
  final bool stale;
  final CredKind cred;
  final ClawdPose clawd;

  /// Board rows, most urgent first (all of them; the painter shows 3, or 2 under a credential strip).
  final List<BoardRow> rows;
}

/// Rate-limit window label (`windowLabel`): Hạn mức tuần / ngày, Phiên N giờ / phút, or plain Hạn mức.
enum WindowKind { week, day, hours, minutes, generic }

class WindowLabel {
  const WindowLabel(this.kind, [this.n = 0]);

  static const generic = WindowLabel(WindowKind.generic);

  final WindowKind kind;
  final int n;
}

/// Weekly pace line of Codex (`paceFor`): runs out in [span] (red) or ~[pct]% left at the reset.
class CodexPace {
  const CodexPace.empty(this.span) : pct = 0, runsOut = true;
  const CodexPace.atReset(this.pct) : span = DevSpan.unknown, runsOut = false;

  final bool runsOut;
  final DevSpan span;
  final int pct;
}

/// Limit-reset credits (`Chrome::resetsText`): "còn 2 · 3NG", "còn 2 · đến 12/10", "còn 2"; [left] 0 = none.
class ResetCredits {
  const ResetCredits({this.left = 0, this.span, this.until});

  static const none = ResetCredits();

  final int left;

  /// Expires within a week (`shortDuration`).
  final DevSpan? span;

  /// Expires later (device-local date).
  final DateTime? until;
}

/// Codex window (`ch_codex.cpp`). Values the device keeps but `/api/state` does not send stay null / −1.
class CodexMirror {
  const CodexMirror({
    this.view = UsageView.loading,
    this.card,
    this.meta = TitleMeta.none,
    this.heroLabel = WindowLabel.generic,
    this.heroUsed = -1,
    this.heroLevel = UsageLevel.unknown,
    this.heroReset = DevSpan.unknown,
    this.credits,
    this.secLabel = WindowLabel.generic,
    this.secUsed = -1,
    this.secReset = DevSpan.unknown,
    this.secTag = '',
    this.secKnown = false,
    this.resets = ResetCredits.none,
    this.pace,
    this.stale = false,
    this.cred = CredKind.unknown,
  });

  final UsageView view;
  final CredCard? card;
  final TitleMeta meta;
  final WindowLabel heroLabel;
  final int heroUsed;
  final UsageLevel heroLevel;
  final DevSpan heroReset;

  /// Limit credits left in dollars; null = none (no "tín dụng" block).
  final double? credits;
  final WindowLabel secLabel;
  final int secUsed;
  final DevSpan secReset;

  /// Per-model limit name ("Spark") in place of "Đã dùng".
  final String secTag;

  /// The secondary window's values are known (false: the app has no figures → "--", never "Không có").
  final bool secKnown;
  final ResetCredits resets;
  final CodexPace? pace;
  final bool stale;
  final CredKind cred;
}

/// One groupbox of AI hôm nay (`paintBlock`).
enum AiMode { value, loading, credBad, stale }

class AiSide {
  const AiSide({
    this.mode = AiMode.loading,
    this.used = -1,
    this.level = UsageLevel.unknown,
    this.cred = CredKind.unknown,
    this.reset,
  });

  final AiMode mode;
  final int used;
  final UsageLevel level;
  final CredKind cred;

  /// Hero window's reset countdown for the status bar; null = "--".
  final DevSpan? reset;
}

/// Status-bar advice (`adviceText`).
enum AdviceKind { use, resets, bothLow }

class AiAdvice {
  const AiAdvice(this.kind, {this.claude = true, this.left = 0});

  final AdviceKind kind;

  /// Which provider ([AdviceKind.use], [AdviceKind.resets]).
  final bool claude;

  /// Reset credits ([AdviceKind.resets]).
  final int left;
}

/// AI hôm nay window (`ch_aidash.cpp`).
class AiMirror {
  const AiMirror({
    this.credits,
    this.creditsStale = false,
    this.claude = const AiSide(),
    this.codex = const AiSide(),
    this.advice,
    this.staleAge,
  });

  /// Codex credits left (hero); null = "--".
  final double? credits;
  final bool creditsStale;
  final AiSide claude, codex;
  final AiAdvice? advice;

  /// Title " · cũ 14P" from the older of the stale sides; null = fresh.
  final DevSpan? staleAge;
}

/// One provider of Xu hướng (`Block`).
class TrendBlock {
  const TrendBlock({required this.claude, this.cred = CredKind.unknown, this.burn, this.lastReading});

  final bool claude;
  final CredKind cred;

  /// Weekly-allowance points used per day, oldest first (7), null entry = no reading that day; null list =
  /// history not known to the app.
  final List<double?>? burn;

  /// Device-local date of its last reading (status "cuối 3/8"); null = unknown.
  final DateTime? lastReading;
}

/// Xu hướng window (`ch_trend.cpp`).
class TrendMirror {
  const TrendMirror({this.blocks = const [], this.weekdays = const []});

  /// Configured providers (Claude first).
  final List<TrendBlock> blocks;

  /// `DateTime.weekday` of the 7 columns, 6 days ago … today; empty = device clock not set.
  final List<int> weekdays;

  /// Days since the first reading (0…7); null = history unknown.
  int? get haveDays {
    if (blocks.every((b) => b.burn == null)) return null;
    for (var i = 0; i < 7; i++) {
      for (final b in blocks) {
        final v = b.burn;
        if (v != null && i < v.length && v[i] != null) return 7 - i;
      }
    }
    return 0;
  }
}

/// The four usage windows of one frame.
class UsageMirror {
  const UsageMirror({
    this.claude = const ClaudeMirror(),
    this.codex = const CodexMirror(),
    this.ai = const AiMirror(),
    this.trend = const TrendMirror(),
  });

  final ClaudeMirror claude;
  final CodexMirror codex;
  final AiMirror ai;
  final TrendMirror trend;
}
