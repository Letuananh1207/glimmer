// Shapes of the display's JSON API (see src/core/web.cpp in the firmware).
import '../../utils/json.dart';
import 'cursor.dart';
import 'device_sources.dart';
import 'device_weather.dart';
import 'library_photo.dart';
import 'project.dart';
import 'usage.dart';

export 'device_sources.dart';
export 'device_weather.dart';
export 'library_photo.dart' show PhotoSourceInfo, PhotoSourceState;

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
    this.photoSourceApi = false,
    this.photoSource,
    this.nightFace = false,
    this.paused,
    this.screenOn,
    this.balloon,
    this.slideMs = 0,
    this.slideLeftMs,
    this.wallpaper,
    this.codexConfigured = false,
    this.sources = const DeviceSources(),
    this.windowsApi = false,
    this.clockApi = false,
    this.ntpLast = 0,
    this.cursorPort,
    this.power,
    this.startRecent = const [],
    this.minesApi = false,
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
    projects: List.unmodifiable(
      (j['projects'] as List? ?? const []).whereType<Map<String, dynamic>>().map(Project.fromJson),
    ),
    skill: jsonStr(j['skill']),
    skills: List.unmodifiable((j['skills'] as List? ?? const []).whereType<String>()),
    skillsOn: List.unmodifiable((j['skills_on'] as List? ?? const []).whereType<String>()),
    weatherConfigured: jsonBool(j['weather_configured']) || j['weather'] is Map,
    weather: j['weather'] is Map<String, dynamic> ? DeviceWeather.fromJson(j['weather'] as Map<String, dynamic>) : null,
    photos: j['photos'] is num ? (j['photos'] as num).toInt() : null,
    photoSourceApi: j['photo_source'] is Map,
    photoSource: j['photo_source'] is Map<String, dynamic>
        ? PhotoSourceInfo.fromJson(j['photo_source'] as Map<String, dynamic>)
        : null,
    nightFace: jsonBool(j['night_face']),
    paused: j['paused'] is bool ? j['paused'] as bool : null,
    screenOn: j['screen_on'] is bool ? j['screen_on'] as bool : null,
    balloon: j['balloon'] is bool ? j['balloon'] as bool : null,
    slideMs: jsonInt(j['slide_ms']),
    slideLeftMs: j['slide_left_ms'] is num ? (j['slide_left_ms'] as num).toInt() : null,
    wallpaper: j['wallpaper'] is bool ? j['wallpaper'] as bool : null,
    codexConfigured: jsonBool(j['codex_configured']),
    sources: DeviceSources.fromJson(j),
    windowsApi: j['windows'] is Map,
    clockApi: j['clock'] is Map,
    ntpLast: jsonInt(j['ntp_last']),
    cursorPort: j['cursor'] is Map && (j['cursor'] as Map)['port'] is num ? ((j['cursor'] as Map)['port'] as num).toInt() : null,
    power: PowerState.fromName(j['power']),
    startRecent: List.unmodifiable((j['start_recent'] as List? ?? const []).whereType<String>()),
    minesApi: j['mines'] is Map,
  );

  /// The same state with what a control command changed (answer of `/api/channel`, `/api/screen`).
  DeviceState withControl({
    String? activeChannel,
    bool? paused,
    bool? screenOn,
    int? slideLeftMs,
    bool? balloon,
    PowerState? power,
  }) =>
      DeviceState(
        fw: fw,
        build: build,
        wifi: wifi,
        ip: ip,
        ssid: ssid,
        activeChannel: activeChannel ?? this.activeChannel,
        resetReason: resetReason,
        rssi: rssi,
        uptimeS: uptimeS,
        heap: heap,
        maxBlock: maxBlock,
        heapRefusals: heapRefusals,
        nextFetchS: nextFetchS,
        time: time,
        claudeConfigured: claudeConfigured,
        claudeValid: claudeValid,
        claudeErr: claudeErr,
        usage: usage,
        projects: projects,
        skill: skill,
        skills: skills,
        skillsOn: skillsOn,
        weatherConfigured: weatherConfigured,
        weather: weather,
        photos: photos,
        photoSourceApi: photoSourceApi,
        photoSource: photoSource,
        nightFace: nightFace,
        paused: paused ?? this.paused,
        screenOn: screenOn ?? this.screenOn,
        balloon: balloon ?? this.balloon,
        slideMs: slideMs,
        slideLeftMs: slideLeftMs ?? this.slideLeftMs,
        wallpaper: wallpaper,
        codexConfigured: codexConfigured,
        sources: sources,
        windowsApi: windowsApi,
        clockApi: clockApi,
        cursorPort: cursorPort,
        power: power ?? this.power,
        startRecent: startRecent,
        minesApi: minesApi,
        ntpLast: ntpLast,
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

  /// R-AK-5: the firmware points at the app's photo library (`photo_source` in /api/state, POST /api/photos/source).
  final bool photoSourceApi;

  /// Where the device's slideshow is (`photo_source`, design 2026-11-28.11); null = firmware without it.
  final PhotoSourceInfo? photoSource;

  /// The device shows its night face (`night_face`).
  final bool nightFace;

  /// Rotation held by the app remote (R-DK-4); null = firmware without the command (R-DK-3).
  final bool? paused;

  /// The firmware takes the app's open windows and context menus (`windows` in `/api/state`, panel
  /// P-2026-11-26.14): `POST /api/windows`, `POST /api/menu`.
  final bool windowsApi;

  /// The firmware takes touches on the Ngày và Giờ window (`clock` in `/api/state`, panel P-2026-11-26.22, R-DK-16).
  final bool clockApi;

  /// Epoch of the device's last time sync (`ntp_last`), 0 = none yet / unknown.
  final int ntpLast;

  /// UDP port the device takes the mouse pointer on (`cursor.port`, R-DK-17); null = firmware without the mouse
  /// (R-DK-21).
  final int? cursorPort;

  /// The "computer" on / off (`power`, R-DK-20); null = firmware without the power button.
  final PowerState? power;

  /// Start's "most frequently used": programs opened last, newest first (`start_recent`, R-DK-22).
  final List<String> startRecent;

  /// The firmware draws Dò mìn (`mines` in `/api/state`, R-DK-23).
  final bool minesApi;

  /// Backlight on; null = firmware without `/api/screen` (R-DK-3).
  final bool? screenOn;

  /// The desktop's weather balloon is up (panel P-2026-11-26.15, R-DK-13); null = firmware before it (the
  /// balloon was always up then).
  final bool? balloon;

  /// Length of the current slide (ms); 0 = not rotating.
  final int slideMs;

  /// Time left of the current slide (ms, at the moment of the read); 0 = not rotating; null = firmware without it.
  final int? slideLeftMs;

  /// A desktop wallpaper JPEG is stored on the device; null = firmware without it.
  final bool? wallpaper;

  /// A Codex token is set (`codex_configured`).
  final bool codexConfigured;

  /// Per-source fetch health + vendor status (`sources`, `vendor_status`).
  final DeviceSources sources;

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
    return DateTime(
      int.tryParse(p[2]) ?? 0,
      m + 1,
      int.tryParse(p[1]) ?? 1,
      int.tryParse(t[0]) ?? 0,
      int.tryParse(t[1]) ?? 0,
      int.tryParse(t[2]) ?? 0,
    );
  }
}
