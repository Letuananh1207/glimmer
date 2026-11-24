// Shapes of the display's JSON API (see src/core/web.cpp in the firmware).
import '../../utils/json.dart';
import 'project.dart';
import 'usage.dart';

/// GET /api/state.
class DeviceState {
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

  factory DeviceState.fromJson(Map<String, dynamic> j) => DeviceState(
        fw: jsonStr(j['fw']),
        build: jsonStr(j['build']),
        wifi: jsonStr(j['wifi']),
        ip: jsonStr(j['ip']),
        ssid: jsonStr(j['ssid']),
        activeChannel: jsonStr(j['active_channel']),
        resetReason: jsonStr(j['reset_reason']),
        rssi: jsonInt(j['rssi']),
        uptimeS: jsonInt(j['uptime_s']),
        heap: jsonInt(j['heap']),
        maxBlock: jsonInt(j['maxblk']),
        heapRefusals: jsonInt(j['heap_refusals']),
        nextFetchS: jsonInt(j['next_fetch_s']),
        time: jsonInt(j['time']),
        claudeConfigured: jsonBool(j['claude_configured']),
        claudeValid: jsonBool(j['claude_valid']),
        claudeErr: jsonStr(j['claude_err']),
        usage: j['claude_usage'] is Map<String, dynamic>
            ? Usage.fromJson(j['claude_usage'] as Map<String, dynamic>)
            : const Usage(),
        projects: List.unmodifiable((j['projects'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Project.fromJson)),
      );

  final String fw, build, wifi, ip, ssid, activeChannel, resetReason;
  final int rssi, uptimeS, heap, maxBlock, heapRefusals, nextFetchS, time;
  final bool claudeConfigured, claudeValid;
  final String claudeErr;
  final Usage usage;
  final List<Project> projects;

  /// In setup-AP mode the device reports wifi "ap".
  bool get inSetupMode => wifi == 'ap';
  bool get clockSynced => time > 1000000000;

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
