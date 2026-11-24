import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A file the user picked.
class PickedFile {
  const PickedFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// App documents folder, the system share sheet and the file picker.
class FileService {
  /// Write [text] to `<documents>/<name>`; returns the path.
  Future<String> writeDocument(String name, String text) async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/$name');
    await f.writeAsString(text);
    return f.path;
  }

  Future<void> share(String path, String text) =>
      SharePlus.instance.share(ShareParams(files: [XFile(path)], text: text));

  /// Pick one file with extension [ext]; null when cancelled.
  Future<PickedFile?> pick(String ext) async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: [ext]);
    if (picked.isEmpty) return null;
    final file = picked.first;
    return PickedFile(file.name, await file.xFile.readAsBytes());
  }
}
