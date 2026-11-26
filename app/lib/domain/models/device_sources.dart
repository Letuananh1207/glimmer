// Per-source fetch health of GET /api/state (`sources`, `vendor_status`) — firmware src/core/web.cpp
// `sourceJson` / `credJson`. Read by the DeviceMirror's Codex / AI / Trend painters (design 2026-11-26.5).
import '../../utils/json.dart';

/// One upstream (`sources.claude` / `sources.codex`).
class SourceHealth {
  const SourceHealth({
    this.valid = false,
    this.lastOk = 0,
    this.code = 0,
    this.err = '',
    this.cred = '',
    this.expiresAt = 0,
    this.resetsLeft = 0,
    this.resetsUsable = false,
    this.resetsEndsAt = 0,
  });

  factory SourceHealth.fromJson(Map<String, dynamic> j) {
    final r = j['resets'] is Map<String, dynamic> ? j['resets'] as Map<String, dynamic> : const <String, dynamic>{};
    return SourceHealth(
      valid: jsonBool(j['valid']),
      lastOk: jsonInt(j['last_ok']),
      code: jsonInt(j['code']),
      err: jsonStr(j['err']),
      cred: jsonStr(j['cred']),
      expiresAt: jsonInt(j['expires_at']),
      resetsLeft: jsonInt(r['left']),
      resetsUsable: jsonBool(r['usable']),
      resetsEndsAt: jsonInt(r['ends_at']),
    );
  }

  /// The device has (possibly old) data of this source.
  final bool valid;

  /// Epoch of the last good fetch, 0 = never.
  final int lastOk;

  /// HTTP code of the last attempt; negative = transport failure (no network).
  final int code;

  /// Surfaced non-credential failure (offline, "HTTP 503", "JSON …"), '' = none.
  final String err;

  /// not_set / checking / ok / expiring / expired / rejected / blocked ('' = firmware without it).
  final String cred;

  /// Token expiry from its JWT (Codex), 0 = unknown.
  final int expiresAt;

  /// Limit-reset credits on the account (0 = none), spendable now, and when they expire (epoch, 0 = unknown).
  final int resetsLeft;
  final bool resetsUsable;
  final int resetsEndsAt;
}

/// `sources` + `vendor_status` (the latter only when the device's `showStatus` is on).
class DeviceSources {
  const DeviceSources({
    this.claude = const SourceHealth(),
    this.codex = const SourceHealth(),
    this.claudeStatus = '',
    this.claudeStatusOk = 0,
    this.openaiStatus = '',
    this.openaiStatusOk = 0,
  });

  factory DeviceSources.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> m(Object? v) => v is Map<String, dynamic> ? v : const {};
    final src = m(j['sources']);
    final vs = m(j['vendor_status']);
    return DeviceSources(
      claude: SourceHealth.fromJson(m(src['claude'])),
      codex: SourceHealth.fromJson(m(src['codex'])),
      claudeStatus: jsonStr(m(vs['claude'])['level']),
      claudeStatusOk: jsonInt(m(vs['claude'])['last_ok']),
      openaiStatus: jsonStr(m(vs['openai'])['level']),
      openaiStatusOk: jsonInt(m(vs['openai'])['last_ok']),
    );
  }

  final SourceHealth claude, codex;

  /// Vendor status page level (operational / maintenance / minor / major / critical, '' = not read) and when.
  final String claudeStatus, openaiStatus;
  final int claudeStatusOk, openaiStatusOk;
}
