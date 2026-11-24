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

  /// Id of the skill in use (null = never chosen).
  String? get activeSkill => _p.getString('active_skill');
  set activeSkill(String? v) => v == null ? _p.remove('active_skill') : _p.setString('active_skill', v);

  /// GitHub repo whose `latest` release holds the firmware builds.
  String get repo => _p.getString('repo') ?? 'Letuananh1207/glimmer';
  set repo(String v) => _p.setString('repo', v);
}
