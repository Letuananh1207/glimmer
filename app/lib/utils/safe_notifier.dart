import 'package:flutter/foundation.dart';

/// For ViewModels whose async work can outlive the screen (flashing, Wi-Fi setup): after [dispose],
/// [notifyListeners] does nothing instead of throwing, so the work runs to the end.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  bool get disposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
