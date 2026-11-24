import '../../../domain/models/config_backup.dart';
import '../../../utils/result.dart';

/// Config backups on the phone (they hold secrets — Wi-Fi password, keys). Failures are [AppError]s.
abstract class BackupRepository {
  /// Save [config] as `glimmer-config-<time>.json` in the app's documents; returns the path.
  Future<Result<String>> save(Map<String, dynamic> config);

  /// Open the share sheet for the file at [path] with message [text].
  Future<Result<void>> share(String path, String text);

  /// Let the user pick a backup; Ok(null) when cancelled, error when it is not a glimmer config (R-TB-2).
  Future<Result<ConfigBackup?>> pick();
}
