import 'package:flutter/foundation.dart';

import '../../../data/repositories/photo/photo_repository.dart';
import '../../../domain/models/app_error.dart';
import '../../../domain/models/device_photo.dart';
import '../../../domain/models/library_photo.dart';
import '../../../domain/rules/library_rules.dart' as rules;
import '../../../domain/use_cases/photo_library_use_case.dart';
import '../../../domain/use_cases/send_photo_use_case.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

/// Tab Ảnh as Kho ảnh (screen_specs §2, design 2026-11-28.11): the phone's library newest first, the device's cache
/// (the [rules.cacheMax] newest) and the photo it is showing, adding a cropped photo from PhotoCrop (spinner tile, error
/// banner + retry with the kept crop) and deleting one (spinner on its tile, error banner + retry).
class LibraryTabViewModel extends ChangeNotifier with SafeNotifier {
  LibraryTabViewModel({
    required PhotoLibraryUseCase library,
    required SendPhotoUseCase send,
    required PhotoRepository photos,
  })  : _library = library,
        _send = send,
        _photos = photos;

  final PhotoLibraryUseCase _library;
  final SendPhotoUseCase _send;
  final PhotoRepository _photos;

  List<LibraryItem>? _items;
  bool _loading = false;
  bool _reloadAfter = false;
  PhotoPixels? _adding;
  PhotoPixels? _addFailed;
  AppError? _addError;
  final _deleting = <int>{};
  int? _deleteFailed;
  AppError? _deleteError;
  bool _askedLost = false;

  /// Newest first; null until the first load answers.
  List<LibraryItem>? get items => _items;

  /// The photo being added (`libraryAdding` tile right after the add tile), null when none.
  PhotoPixels? get adding => _adding;

  /// Photos in the library, the one being added counted (the meta counts it at once).
  int get count => (_items?.length ?? 0) + (_adding != null ? 1 : 0);

  /// `libraryAddError` banner; [retryAdd] sends the kept crop again.
  AppError? get addError => _addError;

  /// Photos being deleted (`libraryDeleting` overlay); the other tiles stay tappable.
  Set<int> get deleting => Set.unmodifiable(_deleting);

  /// `libraryDeleteError` banner; [retryDelete] tries again.
  AppError? get deleteError => _deleteError;

  /// R-AK-3: the device's cache holds this many of the newest.
  int get cacheMax => rules.cacheMax;

  /// R-AK-3: tile [i] (newest first) is in the device's cache — the [rules.cacheMax] newest.
  bool onDevice(int i) => i < rules.cacheMax;

  /// The library photo the device is showing: `photo_source.index` in slideshow order, only while it asks the
  /// phone (online). Null = none of these.
  int? showingId(PhotoSourceInfo? source) {
    if (source == null || !source.online || source.index <= 0) return null;
    for (final it in _items ?? const <LibraryItem>[]) {
      if (it.order == source.index) return it.id;
    }
    return null;
  }

  /// The library (phone storage only, quick). A load asked while one runs runs again after it.
  Future<void> load() async {
    if (_loading) {
      _reloadAfter = true;
      return;
    }
    _loading = true;
    _items = await _library.load();
    _loading = false;
    notifyListeners();
    if (_reloadAfter) {
      _reloadAfter = false;
      await load();
    }
  }

  /// "Thêm vào kho" from PhotoCrop: into the library and the device's cache (R-AK-1, R-AK-3). The device refusing
  /// its copy → the photo is not kept (SendPhotoUseCase) and the banner offers to send the same crop again.
  Future<void> add(PhotoPixels pixels) async {
    if (_adding != null) return;
    _adding = pixels;
    _addFailed = null;
    _addError = null;
    notifyListeners();
    final r = await _send(pixels, side: pixels.width);
    _adding = null;
    if (r is Error<SentPhoto>) {
      _addFailed = pixels;
      _addError = AppError.from(r.error);
    }
    notifyListeners();
    await load();
  }

  Future<void> retryAdd() async {
    final p = _addFailed;
    if (p != null) await add(p);
  }

  /// "Xoá ảnh khỏi kho?" → Xoá. On failure the photo stays and the banner shows.
  Future<void> delete(int id) async {
    if (_deleting.contains(id)) return;
    _deleting.add(id);
    if (_deleteFailed == id) {
      _deleteFailed = null;
      _deleteError = null;
    }
    notifyListeners();
    final r = await _library.delete(id);
    _deleting.remove(id);
    if (r is Error<void>) {
      _deleteFailed = id;
      _deleteError = AppError.from(r.error);
    } else if (_deleteFailed == id) {
      _deleteFailed = null;
      _deleteError = null;
    }
    notifyListeners();
    if (r is Ok<void>) await load();
  }

  Future<void> retryDelete() async {
    final id = _deleteFailed;
    if (id != null) await delete(id);
  }

  /// `PhotoSourceSheet`: the system picker / camera. Ok(null) = the user backed out.
  Future<Result<Uint8List?>> pick(PhotoSource source) => _photos.pick(source);

  /// A photo picked before Android killed the app — asked once per tab, null = none.
  Future<Uint8List?> lostPick() async {
    if (_askedLost) return null;
    _askedLost = true;
    return _photos.retrieveLost();
  }
}
