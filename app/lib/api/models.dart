// Shapes of the display's JSON API (see src/core/web.cpp in the firmware).

int _int(Object? v, [int d = 0]) => v is num ? v.toInt() : d;
bool _bool(Object? v) => v == true;
String _str(Object? v) => v is String ? v : '';

/// Claude usage as the screen shows it: % USED, -1 = unknown.
class Usage {
  final int sessionUsed, weeklyUsed;
  final int sessionReset, weeklyReset, lastOk; // epoch seconds, 0 = unknown
  final bool stale;
  final String cred; // not_set / checking / ok / expiring / expired / rejected / blocked

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
        sessionUsed: _int(j['session_used'], -1),
        weeklyUsed: _int(j['weekly_used'], -1),
        sessionReset: _int(j['session_reset']),
        weeklyReset: _int(j['weekly_reset']),
        lastOk: _int(j['last_ok']),
        stale: _bool(j['stale']),
        cred: _str(j['cred']),
      );
}

/// One row of the project board (latest state per project).
class Project {
  final String project, agent, state, detail;
  final int ageS, idleS;
  final bool shown;

  const Project(this.project, this.agent, this.state, this.detail, this.ageS, this.idleS, this.shown);

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        _str(j['project']),
        _str(j['agent']),
        _str(j['state']),
        _str(j['detail']),
        _int(j['age_s']),
        _int(j['idle_s']),
        _bool(j['shown']),
      );
}

/// An attention card in the device's queue.
class Card {
  final String id, kind, agent, title, value, body, project;
  final int progress, ageS;

  const Card(this.id, this.kind, this.agent, this.title, this.value, this.body, this.project,
      this.progress, this.ageS);

  factory Card.fromJson(Map<String, dynamic> j) => Card(
        _str(j['id']),
        _str(j['kind']),
        _str(j['agent']),
        _str(j['title']),
        _str(j['value']),
        _str(j['body']),
        _str(j['project']),
        _int(j['progress'], -1),
        _int(j['age_s']),
      );
}

/// GET /api/state.
class DeviceState {
  final String fw, build, wifi, ip, ssid, activeChannel, resetReason;
  final int rssi, uptimeS, heap, maxBlock, heapRefusals, nextFetchS, time;
  final bool claudeConfigured, claudeValid;
  final String claudeErr;
  final Usage usage;
  final List<Project> projects;

  const DeviceState({
    required this.fw,
    required this.build,
    required this.wifi,
    required this.ip,
    required this.ssid,
    required this.activeChannel,
    required this.resetReason,
    required this.rssi,
    required this.uptimeS,
    required this.heap,
    required this.maxBlock,
    required this.heapRefusals,
    required this.nextFetchS,
    required this.time,
    required this.claudeConfigured,
    required this.claudeValid,
    required this.claudeErr,
    required this.usage,
    required this.projects,
  });

  /// In setup-AP mode the device reports wifi "ap".
  bool get inSetupMode => wifi == 'ap';
  bool get clockSynced => time > 1000000000;

  factory DeviceState.fromJson(Map<String, dynamic> j) => DeviceState(
        fw: _str(j['fw']),
        build: _str(j['build']),
        wifi: _str(j['wifi']),
        ip: _str(j['ip']),
        ssid: _str(j['ssid']),
        activeChannel: _str(j['active_channel']),
        resetReason: _str(j['reset_reason']),
        rssi: _int(j['rssi']),
        uptimeS: _int(j['uptime_s']),
        heap: _int(j['heap']),
        maxBlock: _int(j['maxblk']),
        heapRefusals: _int(j['heap_refusals']),
        nextFetchS: _int(j['next_fetch_s']),
        time: _int(j['time']),
        claudeConfigured: _bool(j['claude_configured']),
        claudeValid: _bool(j['claude_valid']),
        claudeErr: _str(j['claude_err']),
        usage: j['claude_usage'] is Map<String, dynamic>
            ? Usage.fromJson(j['claude_usage'] as Map<String, dynamic>)
            : const Usage(),
        projects: (j['projects'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Project.fromJson)
            .toList(),
      );

  /// Build time "Nov 25 2026 10:21:07" (__DATE__ __TIME__, device-local) → DateTime.
  DateTime? get buildTime {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final p = build.split(RegExp(r'\s+'));
    if (p.length < 4) return null;
    final m = months.indexOf(p[0]);
    final t = p[3].split(':');
    if (m < 0 || t.length < 3) return null;
    return DateTime(int.tryParse(p[2]) ?? 0, m + 1, int.tryParse(p[1]) ?? 1,
        int.tryParse(t[0]) ?? 0, int.tryParse(t[1]) ?? 0, int.tryParse(t[2]) ?? 0);
  }
}
