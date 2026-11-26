/// Lets the UI stop a long call (a photo upload) it started. The callee checks [cancelled] between steps and
/// may register [onCancel] to abort at once.
class CancelToken {
  bool _cancelled = false;
  void Function()? _onCancel;

  bool get cancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _onCancel?.call();
  }

  /// Called once on [cancel] (replaces an earlier one).
  set onCancel(void Function()? f) => _onCancel = f;
}
