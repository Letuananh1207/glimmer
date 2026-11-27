import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Files of the photo library (R-AK-1): `<app documents>/library/<id>.jpg` + `library.json` (the list, docs/backend).
class PhotoLibraryService {
  /// [root] = folder to use instead of the app documents folder (tests).
  PhotoLibraryService({Directory? root}) : _root = root;

  final Directory? _root;

  Future<Directory> _dir() async {
    final base = _root ?? await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/library');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// The list as stored (`[{id, added, size, cachedAs?}]`); empty when there is none or it is unreadable.
  Future<List<Map<String, dynamic>>> readIndex() async {
    final f = File('${(await _dir()).path}/library.json');
    if (!await f.exists()) return [];
    try {
      final j = jsonDecode(await f.readAsString());
      return j is List ? j.whereType<Map<String, dynamic>>().toList() : [];
    } on FormatException {
      return [];
    }
  }

  /// Replace the list (written to a temp file, then renamed: a crash leaves the old one).
  Future<void> writeIndex(List<Map<String, Object?>> entries) async {
    final d = await _dir();
    final tmp = File('${d.path}/library.json.tmp');
    await tmp.writeAsString(jsonEncode(entries), flush: true);
    await tmp.rename('${d.path}/library.json');
  }

  Future<Uint8List?> read(int id) async {
    final f = File('${(await _dir()).path}/$id.jpg');
    return await f.exists() ? f.readAsBytes() : null;
  }

  Future<void> write(int id, Uint8List bytes) async =>
      File('${(await _dir()).path}/$id.jpg').writeAsBytes(bytes, flush: true);

  Future<void> delete(int id) async {
    final f = File('${(await _dir()).path}/$id.jpg');
    if (await f.exists()) await f.delete();
  }
}
