import 'package:flutter/foundation.dart';

import '../../../data/repositories/photo/photo_repository.dart';
import '../../../domain/models/app_error.dart';
import '../../../domain/models/device_photo.dart';
import '../../../domain/use_cases/delete_photo_use_case.dart';
import '../../../domain/use_cases/load_photos_use_case.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

/// Tab Ảnh of Màn hình (screen_specs §2, 2026-11-25.4): the device's photos with the app's copies as thumbnails,
/// deleting one (spinner on its tile, error banner + retry), and picking a new one for PhotoCrop.
class PhotoTabViewModel extends ChangeNotifier with SafeNotifier {
  PhotoTabViewModel({
    required LoadPhotosUseCase loadPhotos,
    required DeletePhotoUseCase deletePhoto,
    required PhotoRepository photos,
  })  : _load = loadPhotos,
        _delete = deletePhoto,
        _photos = photos;

  final LoadPhotosUseCase _load;
  final DeletePhotoUseCase _delete;
  final PhotoRepository _photos;

  PhotoGallery? _gallery;
  bool _loading = false;
  bool _reloadAfter = false;
  AppError? _loadError;
  final _deleting = <String>{};
  String? _failed;
  AppError? _deleteError;
  bool _askedLost = false;

  /// Null until the first load answers.
  PhotoGallery? get gallery => _gallery;
  bool get loading => _loading;

  /// The last load failed (the old gallery, if any, stays up).
  AppError? get loadError => _loadError;

  /// Limits for the crop screen; firmware defaults before the first load.
  PhotoInfo get info => _gallery?.info ?? const PhotoInfo();

  /// Photos being deleted (`photoDeleting` overlay); the other tiles stay tappable.
  Set<String> get deleting => Set.unmodifiable(_deleting);

  /// `photoDeleteError` banner; [retryDelete] tries [failedName] again.
  AppError? get deleteError => _deleteError;
  String? get failedName => _failed;

  /// First open of the tab: load once (later loads come from [load] / refresh).
  void loadIfNeeded() {
    if (_gallery == null && !_loading && _loadError == null) load();
  }

  /// GET /api/photos + the app's copies. A load asked while one runs runs again after it (a delete or upload
  /// may have changed the list meanwhile).
  Future<void> load() async {
    if (_loading) {
      _reloadAfter = true;
      return;
    }
    _loading = true;
    notifyListeners();
    final r = await _load();
    _loading = false;
    switch (r) {
      case Ok(:final value):
        _gallery = value;
        _loadError = null;
      case Error(:final error):
        _loadError = AppError.from(error);
    }
    notifyListeners();
    if (_reloadAfter) {
      _reloadAfter = false;
      await load();
    }
  }

  /// `DeletePhotoDialog` "Xoá". On success the gallery reloads; on failure the banner shows.
  Future<void> delete(String name) async {
    if (_deleting.contains(name)) return;
    _deleting.add(name);
    if (_failed == name) _clearDeleteError();
    notifyListeners();
    final r = await _delete(name);
    _deleting.remove(name);
    if (r is Error<int>) {
      _failed = name;
      _deleteError = AppError.from(r.error);
    } else if (_failed == name) {
      _clearDeleteError();
    }
    notifyListeners();
    if (r is Ok<int>) await load();
  }

  Future<void> retryDelete() async {
    final name = _failed;
    if (name != null) await delete(name);
  }

  void _clearDeleteError() {
    _failed = null;
    _deleteError = null;
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
