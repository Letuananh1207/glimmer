import 'dart:typed_data';

import '../../../domain/models/release.dart';
import '../../../utils/result.dart';

/// Firmware builds from the GitHub `latest` release. Failures are [AppError]s.
abstract class ReleaseRepository {
  /// GitHub repo the builds come from.
  String get repo;

  Future<Result<Release>> latest();

  /// Download the asset [name] of [release].
  Future<Result<Uint8List>> download(Release release, String name, {void Function(double)? onProgress});
}
