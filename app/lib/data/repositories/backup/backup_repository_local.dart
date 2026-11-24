import 'dart:convert';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/config_backup.dart';
import '../../../domain/rules/update_rules.dart';
import '../../../utils/result.dart';
import '../../services/file_service.dart';
import 'backup_repository.dart';

class BackupRepositoryLocal implements BackupRepository {
  BackupRepositoryLocal({required FileService files, DateTime Function() now = DateTime.now})
      : _files = files,
        _now = now;

  final FileService _files;
  final DateTime Function() _now;

  @override
  Future<Result<String>> save(Map<String, dynamic> config) async {
    try {
      final stamp = _now().toIso8601String().substring(0, 16).replaceAll(':', '');
      return Result.ok(await _files.writeDocument(
          'glimmer-config-$stamp.json', const JsonEncoder.withIndent('  ').convert(config)));
    } catch (e) {
      return Result.error(AppError.from(e));
    }
  }

  @override
  Future<Result<void>> share(String path, String text) async {
    try {
      await _files.share(path, text);
      return const Result.ok(null);
    } catch (e) {
      return Result.error(AppError.from(e));
    }
  }

  @override
  Future<Result<ConfigBackup?>> pick() async {
    final PickedFile? file;
    try {
      file = await _files.pick('json');
    } catch (e) {
      return Result.error(AppError.from(e));
    }
    if (file == null) return const Result.ok(null);
    return decode(file.name, file.bytes);
  }

  /// Bytes of a picked file → [ConfigBackup], or an invalidBackup error (R-TB-2).
  static Result<ConfigBackup?> decode(String name, List<int> bytes) {
    try {
      final cfg = jsonDecode(utf8.decode(bytes));
      if (cfg is! Map<String, dynamic>) throw const FormatException('not a JSON object');
      if (!isGlimmerConfig(cfg)) throw const FormatException('no wifi_ssid');
      return Result.ok(ConfigBackup(name, cfg));
    } catch (e) {
      return Result.error(AppError(AppErrorKind.invalidBackup, detail: e is FormatException ? e.message : '$e'));
    }
  }
}
