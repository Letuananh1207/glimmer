import 'dart:ui';

import '../../../../../domain/models/usage_mirror.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';

/// Shared pieces of the usage windows (firmware `chrome.cpp`): spans, title meta, the credential message box and
/// the credential info strip, usage colours.
abstract final class UsageChrome {
  /// mDNS link under the credential dialogs (`MDNS_HOSTNAME` + ".local").
  static const host = 'glimmer.local';

  /// Upstream hosts named by the dialogs.
  static const claudeHost = 'claude.ai', codexHost = 'chatgpt.com';

  /// "4NG", "2G 14P", "14P", "2G", "ngay", "--".
  static String span(AppLocalizations l, DevSpan s) => switch (s.kind) {
    SpanKind.none => '--',
    SpanKind.now => l.devNow,
    SpanKind.minutes => l.devXpSpanShort('minutes', s.a),
    SpanKind.hours => l.devXpSpanShort('hours', s.a),
    SpanKind.hoursMinutes => l.devXpSpanHourMin(s.a, s.b),
    SpanKind.days => l.devXpSpanShort('days', s.a),
  };

  /// Title meta text ('' = none): "khóa lỗi", "bị chặn", "cũ 14P", "hạn 2NG", "sự cố"…, or the model label.
  static String meta(AppLocalizations l, TitleMeta m) => switch (m.kind) {
    MetaKind.none => '',
    MetaKind.keyBad => l.devXpMeta('keyBad'),
    MetaKind.blocked => l.devXpMeta('blocked'),
    MetaKind.stale => l.devXpStaleMeta(span(l, m.span)),
    MetaKind.expiring => l.devXpMetaExpiring(span(l, m.span)),
    MetaKind.maintenance => l.devXpMeta('maintenance'),
    MetaKind.minor => l.devXpMeta('minor'),
    MetaKind.major => l.devXpMeta('major'),
    MetaKind.label => m.label,
  };

  /// `xpUsageColor` of a bar: ≤ 20 % left red, ≤ 50 % amber, else [healthy]; unknown dim.
  static Color level(UsageLevel v, Color healthy) => switch (v) {
    UsageLevel.unknown => XpColors.dim,
    UsageLevel.critical => XpColors.red,
    UsageLevel.low => XpColors.amber,
    UsageLevel.ok => healthy,
  };

  /// `XP::fitText`-style "%" hero: VT323-86 digits at (10, 40) and VT323-44 "%" at (10 + w + 2, 70); [percent] false
  /// leaves the "%" out (Claude asleep with "100").
  static void hero(XpCanvas c, int used, Color color, {bool percent = true}) {
    final s = used < 0 ? '--' : '$used';
    c.text(s, Xp.left, 40, XpFont.vt86, color);
    if (percent) c.text('%', Xp.left + c.textWidth(s, XpFont.vt86).round() + 2, 70, XpFont.vt44, color);
  }

  /// `Chrome::credCard`: the XP message box with the reason, the fix and the device link.
  static void credCard(XpCanvas c, AppLocalizations l, CredCard card, {required bool claude}) {
    final kind = claude ? 'claude' : 'codex';
    final noun = l.devXpCredNoun(kind), cap = l.devXpCredNounCap(kind);
    final up = claude ? claudeHost : codexHost;
    String two(int n) => n.toString().padLeft(2, '0');
    switch (card.kind) {
      case CredCardKind.rejected:
        Xp.dialog(
          c,
          XpDialog.error,
          l.devXpCredHeadRejected(cap),
          [l.devXpCredRejectedLine(up, noun), l.devXpCredEnterNew(noun)],
          link: host,
          sub: card.ip,
        );
      case CredCardKind.expired:
        final d = card.expiry;
        Xp.dialog(
          c,
          XpDialog.error,
          l.devXpCredHeadExpired(cap),
          [
            d == null ? l.devXpCredExpired : l.devXpCredExpiredOn('${two(d.day)}/${two(d.month)}'),
            l.devXpCredEnterNew(noun),
          ],
          link: host,
          sub: card.ip,
        );
      case CredCardKind.blocked:
        Xp.dialog(c, XpDialog.warn, l.devXpCredHeadBlocked, [
          l.devXpCredBlockedLine(up),
          l.devXpCredStillGood(cap),
          '',
          l.devXpCredRetry15,
        ]);
      case CredCardKind.notSet:
        Xp.dialog(c, XpDialog.info, l.devXpCredHeadNotSet(noun), [l.devXpCredEnter(noun)], link: host, sub: card.ip);
      case CredCardKind.offline:
        Xp.dialog(c, XpDialog.warn, l.devXpCredHeadOffline, [
          claude ? l.devXpCredUnreachable(up) : l.devXpCredUnreachableShort(up),
          l.devXpCredCheckWifi,
          '',
          l.devXpCredAutoRetry,
        ]);
      case CredCardKind.upstream:
        Xp.dialog(c, XpDialog.warn, l.devXpCredHeadUpstream, [
          l.devXpCredUpstreamLine(up),
          card.err,
          '',
          l.devXpCredAutoRetry,
        ]);
    }
  }

  /// `Chrome::credBanner`: yellow strip (x, y, w) for a bad credential over data; the short form when too wide.
  /// Blocked is not the key's fault: black text.
  static void credBanner(XpCanvas c, AppLocalizations l, int x, int y, int w, CredKind cred, {required bool claude}) {
    final kind = claude ? 'claude' : 'codex';
    final blocked = cred == CredKind.blocked;
    final state = cred == CredKind.expired ? 'expired' : 'rejected';
    var t = blocked
        ? l.devXpBannerBlocked(l.devXpCredNoun(kind))
        : l.devXpBanner(l.devXpCredNounCap(kind), state, host);
    if (c.textWidth(t, XpFont.jb11) > w - 17) {
      t = blocked ? l.devXpBannerBlockedShort(l.devXpCredNoun(kind)) : l.devXpBannerShort(state, host);
    }
    Xp.infoStrip(c, x, y, w, t, textColor: blocked ? XpColors.black : XpColors.red);
  }

  /// `Chrome::credStatus`: "Khóa Claude bị từ chối", "chatgpt.com chặn máy này"… ('' for a working key).
  static String credStatus(AppLocalizations l, CredKind cred, {required bool claude}) {
    final kind = claude ? 'claude' : 'codex';
    return switch (cred) {
      CredKind.notSet => l.devXpCredStatusNotSet(l.devXpCredWhoLower(kind)),
      CredKind.expired => l.devXpCredStatusExpired(l.devXpCredWho(kind)),
      CredKind.rejected => l.devXpCredStatusRejected(l.devXpCredWho(kind)),
      CredKind.blocked => l.devXpCredStatusBlocked(claude ? claudeHost : codexHost),
      _ => '',
    };
  }

  /// `xpCredColor`: amber for blocked / expiring, red otherwise.
  static Color credColor(CredKind cred) =>
      cred == CredKind.blocked || cred == CredKind.expiring ? XpColors.amber : XpColors.red;
}
