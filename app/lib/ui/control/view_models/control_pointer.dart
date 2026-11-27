part of 'control_view_model.dart';

/// R-DK-17…21: the app as the computer's mouse, keyboard and power button (plan
/// docs/tasks/2026-11-27-app-la-chuot-ban-phim-nguon.md). Clicks and keys go through the same commands as the old
/// touches on the mirror ([ControlViewModel.tap], [ControlViewModel.hold], R-DK-7…16); the pointer itself goes to the
/// device over UDP, at most every [pointerSendEvery], only on change.
extension ControlPointer on ControlViewModel {
  /// ~30 datagrams a second at most (R-DK-17).
  static const pointerSendEvery = Duration(milliseconds: 33);

  Cursor get cursor => _cursor;

  /// The "computer": the power button pressed and on its way, else the device's (old firmware: always on).
  PowerState get power => _pendingPower ?? _device.state?.power ?? PowerState.on;

  /// R-DK-21: the firmware has the mouse, keyboard and power button.
  bool get mouseReady => mode == ControlMode.normal && caps.mouse;

  /// Pointer and keys do something: the mouse firmware, the computer on, the screen lit, not the night face.
  bool get pointerUsable => mouseReady && power.running && usable;

  /// Start is open on the device (Windows key / a click on start).
  bool get startOpen => _startOpen;

  /// The finger moved ([dx], [dy]) dp on the trackpad in [dt]: the pointer follows (R-DK-17), a menu under it lights
  /// the item (R-DK-18).
  void movePointer(double dx, double dy, Duration dt) {
    if (!pointerUsable) return;
    final moved = moveCursor(_cursor, dx, dy, dt);
    _cursor = moved.copyWith(shape: cursorShapeAt(moved, frame, menu: _menu, waiting: _sending == ControlCommand.open));
    final m = _menu;
    if (m != null) {
      final x = _cursor.px.toDouble(), y = _cursor.py.toDouble();
      final item = menuContains(m, x, y) ? menuItemAt(m, x, y) : null;
      if (item != _lit) {
        _lit = item;
        unawaited(_control.menu(m, hover: item));
      }
    }
    _sendPointer();
  }

  /// The latest pointer now, or once [pointerSendEvery] has passed since the last datagram.
  void _sendPointer() {
    final last = _cursorSentAt;
    final wait = last == null ? Duration.zero : pointerSendEvery - _now().difference(last);
    if (wait <= Duration.zero) {
      _cursorTimer?.cancel();
      _cursorTimer = null;
      _cursorSentAt = _now();
      unawaited(_control.cursor(_cursor));
    } else {
      _cursorTimer ??= Timer(wait, () {
        _cursorTimer = null;
        _sendPointer();
      });
    }
  }

  /// R-DK-18: left click (a tap on the trackpad or its left button) = the old tap, where the pointer is.
  Future<void> clickLeft() async {
    if (!pointerUsable) return;
    final hadMenu = _menu != null;
    final t = tap(_cursor.px.toDouble(), _cursor.py.toDouble());
    if (hadMenu) _lit = null;
    if (t.kind == TouchKind.start) await _toggleStart();
  }

  /// R-DK-18: right click = the old hold (R-DK-11), where the pointer is.
  Future<void> clickRight() async {
    if (!pointerUsable) return;
    _lit = null;
    await hold(_cursor.px.toDouble(), _cursor.py.toDouble());
  }

  /// R-DK-19: a control key.
  Future<void> pressKey(ControlKey key) async {
    if (!pointerUsable) return;
    final a = keyAction(
      key,
      windows: _windows,
      channel: channel,
      shownWindow: _shownWindow,
      menu: _menu,
      lit: _lit,
      startOpen: _startOpen,
      deskPrograms: [
        for (final i in frame?.agents.desktop.icons ?? const <DeskIcon>[]) ?i.program,
      ],
    );
    switch (a.kind) {
      case KeyActionKind.toggleStart:
        await _toggleStart();
      case KeyActionKind.closeMenu:
        if (_startOpen) {
          _startOpen = false;
          notifyListeners();
          await startMenu(false);
        } else {
          _lit = null;
          await closeMenu();
        }
      case KeyActionKind.open:
        await openProgram(a.program!);
      case KeyActionKind.closeTop:
        await closeTop();
      case KeyActionKind.hover:
        final m = _menu;
        if (m == null) return;
        _lit = a.item;
        await _control.menu(m, hover: a.item);
      case KeyActionKind.choose:
        final m = _menu;
        if (m != null) _menuDo(m, a.item!);
        _lit = null;
      case KeyActionKind.select:
        _windows = _windows.select(a.program);
        _pushWindows();
        notifyListeners();
      case KeyActionKind.none:
        break;
    }
  }

  Future<void> _toggleStart() async {
    _startOpen = !_startOpen;
    _lit = null;
    notifyListeners();
    await startMenu(_startOpen);
  }

  /// R-DK-20: the power button. Off → the device shuts down, the pointer and keys stop. On → it boots to a bare
  /// desktop, as a fresh start of the app (R-DK-7): no window, pointer in the middle.
  Future<void> pressPower() async {
    if (!mouseReady) return;
    final on = !(power == PowerState.on || power == PowerState.booting);
    _pendingPower = on ? PowerState.booting : PowerState.shutting;
    if (on) {
      _windows = WindowStack.empty;
      _menu = null;
      _lit = null;
      _startOpen = false;
      _cursor = Cursor.home;
      _cursorSentAt = null;
    }
    notifyListeners();
    await _control.power(on);
    _pendingPower = null;
    notifyListeners();
  }
}
