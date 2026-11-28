import 'dart:async';
import 'dart:developer' as dev;
import 'dart:typed_data';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/library_photo.dart';
import '../../../domain/rules/library_rules.dart';
import '../../../utils/result.dart';
import '../../services/photo_library_service.dart';
import 'photo_library_repository.dart';

class PhotoLibraryRepositoryLocal implements PhotoLibraryRepository {
  PhotoLibraryRepositoryLocal({required PhotoLibraryService files, DateTime Function() now = DateTime.now})
    : _files = files,
      _now = now;

  final PhotoLibraryService _files;
  final DateTime Function() _now;
  List<LibraryPhoto>? _photos;
  Future<void> _lock = Future.value();

  /// One change at a time (the server reads while the app adds).
  Future<T> _locked<T>(Future<T> Function() f) {
    final run = _lock.then((_) => f());
    _lock = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<List<LibraryPhoto>> _load() async {
    if (_photos != null) return _photos!;
    try {
      _photos = (await _files.readIndex()).map(LibraryPhoto.fromJson).where((p) => p.id > 0).toList();
    } on Exception catch (e) {
      dev.log('library index: $e', name: 'photos');
      _photos = [];
    }
    return _photos!;
  }

  Future<void> _save() => _files.writeIndex([for (final p in _photos!) p.toJson()]);

  @override
  Future<List<LibraryPhoto>> list() => _locked(() async => libraryOrder(await _load()));

  @override
  Future<Result<LibraryPhoto>> add(Uint8List jpeg, {String? cachedAs}) => _locked(() async {
    try {
      final all = await _load();
      final id = all.fold<int>(0, (m, p) => p.id > m ? p.id : m) + 1;
      await _files.write(id, jpeg);
      final p = LibraryPhoto(id: id, added: _now(), size: jpeg.length, cachedAs: cachedAs);
      _photos = [...all, p];
      await _save();
      return Result.ok(p);
    } on Exception catch (e) {
      return Result.error(AppError.from(e));
    }
  });

  @override
  Future<void> remove(int id) => _locked(() async {
    final all = await _load();
    if (!all.any((p) => p.id == id)) return;
    _photos = [
      for (final p in all)
        if (p.id != id) p,
    ];
    await _quiet(() async {
      await _save();
      await _files.delete(id);
    });
  });

  @override
  Future<LibraryPhoto?> byDeviceName(String deviceName) => _locked(() async {
    for (final p in await _load()) {
      if (p.cachedAs == deviceName) return p;
    }
    return null;
  });

  @override
  Future<Uint8List?> bytes(int id) async {
    try {
      return await _files.read(id);
    } on Exception catch (e) {
      dev.log('library read $id: $e', name: 'photos');
      return null;
    }
  }

  @override
  Future<void> setCached(int id, String? deviceName) => _locked(() async {
    final all = await _load();
    _photos = [
      for (final p in all)
        if (p.id == id)
          p.withCache(deviceName)
        else if (deviceName != null && p.cachedAs == deviceName)
          p.withCache(null)
        else
          p,
    ];
    await _quiet(_save);
  });

  static Future<void> _quiet(Future<void> Function() f) async {
    try {
      await f();
    } on Exception catch (e) {
      dev.log('library: $e', name: 'photos');
    }
  }
}
