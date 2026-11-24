import '../../utils/json.dart';

/// Claude usage as the screen shows it: % USED, -1 = unknown.
class Usage {
  const Usage({
    this.sessionUsed = -1,
    this.weeklyUsed = -1,
    this.sessionReset = 0,
    this.weeklyReset = 0,
    this.lastOk = 0,
    this.stale = false,
    this.cred = '',
  });

  factory Usage.fromJson(Map<String, dynamic> j) => Usage(
        sessionUsed: jsonInt(j['session_used'], -1),
        weeklyUsed: jsonInt(j['weekly_used'], -1),
        sessionReset: jsonInt(j['session_reset']),
        weeklyReset: jsonInt(j['weekly_reset']),
        lastOk: jsonInt(j['last_ok']),
        stale: jsonBool(j['stale']),
        cred: jsonStr(j['cred']),
      );

  final int sessionUsed, weeklyUsed;

  /// Epoch seconds, 0 = unknown.
  final int sessionReset, weeklyReset, lastOk;
  final bool stale;

  /// not_set / checking / ok / expiring / expired / rejected / blocked.
  final String cred;
}
