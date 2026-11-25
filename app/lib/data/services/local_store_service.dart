import 'package:shared_preferences/shared_preferences.dart';

/// What the app remembers between launches (shared_preferences). Keys: docs/backend/README.md.
class LocalStoreService {
  LocalStoreService(this._p);
  final SharedPreferences _p;

  static Future<LocalStoreService> open() async => LocalStoreService(await SharedPreferences.getInstance());

  /// Last address that answered, e.g. "http://192.168.100.40".
  String get deviceUrl => _p.getString('device_url') ?? '';
  set deviceUrl(String v) => _p.setString('device_url', v);

  /// The device's API token (empty when none is set on the device).
  String get token => _p.getString('token') ?? '';
  set token(String v) => _p.setString('token', v);

  /// Ids of the enabled skills in dock order (null = never set). Replaces `active_skill` (one skill, until
  /// 2026-11-25.3), which is dropped on the first write.
  List<String>? get skillsOn => _p.getStringList('skills_on');
  set skillsOn(List<String>? v) {
    _p.remove('active_skill');
    v == null ? _p.remove('skills_on') : _p.setStringList('skills_on', v);
  }

  /// GitHub repo whose `latest` release holds the firmware builds.
  String get repo => _p.getString('repo') ?? 'Letuananh1207/glimmer';
  set repo(String v) => _p.setString('repo', v);
}
