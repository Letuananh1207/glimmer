// Shapes of the display's JSON API (see src/core/web.cpp in the firmware).
import '../../utils/json.dart';
import 'device_weather.dart';
import 'project.dart';
import 'usage.dart';

export 'device_weather.dart';

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
    this.skill = '',
    this.skills = const [],
    this.skillsOn = const [],
    this.weatherConfigured = false,
    this.weather,
    this.photos,
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
        skill: jsonStr(j['skill']),
        skills: List.unmodifiable((j['skills'] as List? ?? const []).whereType<String>()),
        skillsOn: List.unmodifiable((j['skills_on'] as List? ?? const []).whereType<String>()),
        weatherConfigured: jsonBool(j['weather_configured']) || j['weather'] is Map,
        weather: j['weather'] is Map<String, dynamic>
            ? DeviceWeather.fromJson(j['weather'] as Map<String, dynamic>)
            : null,
        photos: j['photos'] is num ? (j['photos'] as num).toInt() : null,
      );

  final String fw, build, wifi, ip, ssid, activeChannel, resetReason;
  final int rssi, uptimeS, heap, maxBlock, heapRefusals, nextFetchS, time;
  final bool claudeConfigured, claudeValid;
  final String claudeErr;
  final Usage usage;
  final List<Project> projects;

  /// Legacy: first enabled skill; '' on firmware without skills.
  final String skill;

  /// Every skill the firmware has channels for, in dock order; empty on firmware without skills.
  final List<String> skills;

  /// Skills enabled on the device (one dock tab each), in dock order; empty on firmware before the dock (R-SK-4).
  final List<String> skillsOn;

  /// The device has a weather location set.
  final bool weatherConfigured;

  /// Weather now + today and 3 days; null when the device has no location or the firmware has none.
  final DeviceWeather? weather;

  /// Photos stored on the device (skill `photo`); null = firmware without photos (no `photos` in /api/state).
  final int? photos;

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
