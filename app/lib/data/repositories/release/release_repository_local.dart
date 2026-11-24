import 'dart:typed_data';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/release.dart';
import '../../../utils/result.dart';
import '../../services/local_store_service.dart';
import '../../services/releases_service.dart';
import 'release_repository.dart';

class ReleaseRepositoryLocal implements ReleaseRepository {
  ReleaseRepositoryLocal({required ReleasesService releases, required LocalStoreService store})
      : _releases = releases,
        _store = store;

  final ReleasesService _releases;
  final LocalStoreService _store;

  @override
  String get repo => _store.repo;

  @override
  Future<Result<Release>> latest() async {
    try {
      final j = await _releases.latestJson(_store.repo);
      return Result.ok(parse(j));
    } on ReleaseHttpException catch (e) {
      return Result.error(e.status == 403
          ? const AppError(AppErrorKind.rateLimited, status: 403)
          : AppError(AppErrorKind.releaseHttp, status: e.status));
    } catch (e) {
      return Result.error(AppError(AppErrorKind.releaseHttp, detail: '${e.runtimeType}'));
    }
  }

  /// GitHub release JSON → [Release].
  static Release parse(Map<String, dynamic> j) {
    final assets = <String, String>{
      for (final a in (j['assets'] as List? ?? const []).whereType<Map<String, dynamic>>())
        if (a['name'] is String && a['browser_download_url'] is String)
          a['name'] as String: a['browser_download_url'] as String,
    };
    final when = DateTime.tryParse((j['published_at'] ?? j['created_at'] ?? '') as String) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final target = (j['target_commitish'] ?? '') as String;
    // target_commitish is a SHA only when CI tagged a commit; skip branch names.
    final sha = RegExp(r'^[0-9a-f]{7,40}$').hasMatch(target) ? target.substring(0, 7) : '';
    return Release(when.toLocal(), sha, Map.unmodifiable(assets));
  }

  @override
  Future<Result<Uint8List>> download(Release release, String name, {void Function(double)? onProgress}) async {
    final url = release.assets[name];
    if (url == null) return Result.error(AppError(AppErrorKind.noAsset, detail: name));
    try {
      return Result.ok(await _releases.download(url, onProgress: onProgress));
    } on ReleaseHttpException catch (e) {
      return Result.error(AppError(AppErrorKind.download, status: e.status));
    } catch (e) {
      return Result.error(AppError(AppErrorKind.download, detail: '${e.runtimeType}'));
    }
  }
}
