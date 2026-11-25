import 'dart:developer' as dev;
import 'dart:typed_data';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/device_photo.dart';
import '../../../utils/result.dart';
import '../../services/photo_picker_service.dart';
import '../../services/photo_store_service.dart';
import 'photo_repository.dart';

class PhotoRepositoryLocal implements PhotoRepository {
  PhotoRepositoryLocal({required PhotoStoreService store, required PhotoPickerService picker})
      : _store = store,
        _picker = picker;

  final PhotoStoreService _store;
  final PhotoPickerService _picker;

  @override
  Future<Result<Uint8List?>> pick(PhotoSource source) async {
    try {
      return Result.ok(await _picker.pick(camera: source == PhotoSource.camera));
    } on Exception catch (e) {
      return Result.error(AppError.from(e));
    }
  }

  @override
  Future<Uint8List?> retrieveLost() async {
    try {
      return await _picker.retrieveLost();
    } on Exception catch (e) {
      dev.log('retrieveLost: $e', name: 'photos');
      return null;
    }
  }

  // Copies are a convenience: a broken file or folder never blocks the Ảnh tab, it just shows no preview.
  @override
  Future<Uint8List?> copyOf(DevicePhoto photo) async {
    try {
      final b = await _store.read(_safe(photo.name));
      return b != null && b.length == photo.size ? b : null;
    } on Exception catch (e) {
      dev.log('copyOf ${photo.name}: $e', name: 'photos');
      return null;
    }
  }

  @override
  Future<void> saveCopy(String name, Uint8List jpeg) => _quiet(() => _store.write(_safe(name), jpeg));

  @override
  Future<void> removeCopy(String name) => _quiet(() => _store.delete(_safe(name)));

  @override
  Future<void> prune(Iterable<String> onDevice) => _quiet(() async {
        final keep = onDevice.map(_safe).toSet();
        for (final n in await _store.list()) {
          if (!keep.contains(n)) await _store.delete(n);
        }
      });

  /// Device names are "p3.jpg"; never let one leave the folder.
  static String _safe(String name) => name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  static Future<void> _quiet(Future<void> Function() f) async {
    try {
      await f();
    } on Exception catch (e) {
      dev.log('photo copy: $e', name: 'photos');
    }
  }
}
