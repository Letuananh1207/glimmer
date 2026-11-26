import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Files of the app's photo copies: `<app documents>/photos/<name>` (docs/backend/README.md).
class PhotoStoreService {
  /// [root] = folder to use instead of the app documents folder (tests).
  PhotoStoreService({Directory? root}) : _root = root;

  final Directory? _root;

  Future<Directory> _dir() async {
    final base = _root ?? await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/photos');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// File names in the folder.
  Future<List<String>> list() async {
    final d = await _dir();
    return [
      await for (final e in d.list())
        if (e is File) e.uri.pathSegments.last,
    ];
  }

  /// Bytes of [name]; null when it is not there.
  Future<Uint8List?> read(String name) async {
    final f = File('${(await _dir()).path}/$name');
    return await f.exists() ? f.readAsBytes() : null;
  }

  Future<void> write(String name, Uint8List bytes) async =>
      File('${(await _dir()).path}/$name').writeAsBytes(bytes, flush: true);

  Future<void> delete(String name) async {
    final f = File('${(await _dir()).path}/$name');
    if (await f.exists()) await f.delete();
  }
}
