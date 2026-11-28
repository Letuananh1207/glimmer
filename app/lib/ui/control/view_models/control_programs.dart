part of 'control_view_model.dart';

/// The state the app keeps for the XP programs of panel P-2026-11-28.28…32 (R-DK-24…29): the app is the computer —
/// it keeps each window's view, works out clicks and keys, and sends the view; the device draws.
class _XpPrograms {
  TaskMgrView taskMgr = TaskMgrView.fresh;
  DisplayProps? display;
  CalcState calc = CalcState.fresh;
  ExplorerView explorer = const ExplorerView();
  int photos = 0;

  /// R-DK-25: the Alt+Tab box — its tiles and the one chosen (null = closed); [altTimer] = "Alt let go".
  List<String> altOrder = const [];
  int? altSel;
  Timer? altTimer;

  /// R-DK-28: the last left click on Explorer, for the double click.
  DateTime? clickAt;
  int clickX = -99, clickY = -99;
}

extension ControlPrograms on ControlViewModel {
  XpPrograms get _xp => _control.xp;

  /// R-DK-24…28: the view of each program (read by the screen / tests).
  TaskMgrView get taskMgrView => _p.taskMgr;
  DisplayProps? get displayProps => _p.display;
  CalcState get calcState => _p.calc;
  ExplorerView get explorerView => _p.explorer;

  /// R-DK-25: the Alt+Tab box is up.
  bool get altTabOpen => _p.altSel != null;

  /// A program window is being opened: its view starts as XP's would and goes down first (the device draws it).
  void _programOpening(String win) {
    final fresh = !_windows.isOpen(win);
    switch (win) {
      case taskMgrProgram when _xp.taskMgr:
        if (fresh) _p.taskMgr = TaskMgrView.fresh;
        unawaited(_sendTaskMgr());
      case displayProgram when _xp.display:
        if (fresh || _p.display == null) {
          final v = displayValuesOf(_settings);
          _p.display = DisplayProps(saved: v, pending: v, photoWallpaper: _device.state?.wallpaper ?? false);
        }
        unawaited(_sendDisplay());
      case 'Calc' when _xp.calc:
        if (fresh) _p.calc = CalcState.fresh;
        unawaited(_sendCalc());
      case explorerProgram when _xp.explorer:
        unawaited(_sendExplorer());
        if (_p.explorer.place == ExplorerPlace.photos) unawaited(_loadPhotoCount());
    }
  }

  /// R-DK-29: Explorer at [place] (Start › Thiết bị = Máy tính, the desktop Recycle Bin = Thùng rác).
  Future<void> openExplorer(ExplorerPlace place) async {
    _p.explorer = ExplorerView(place: place);
    await openProgram(explorerProgram);
  }

  /// A left click inside the body of a program window on screen (title bar / taskbar are not). True = it was one.
  bool _programTap(String channel, double fx, double fy) {
    final x = fx.round(), y = fy.round();
    if (y < 22 || y > 213) return false;
    switch (channel) {
      case taskMgrProgram when _xp.taskMgr:
        _taskMgrTap(x, y);
      case displayProgram when _xp.display && _p.display != null:
        _displayTap(x, y);
      case 'Calc' when _xp.calc:
        final k = calcKeyAt(x, y);
        if (k == null) return true;
        _calcPress(k);
      case explorerProgram when _xp.explorer:
        _explorerTap(x, y);
      default:
        return false;
    }
    return true;
  }

  // ── Trình quản lý tác vụ (R-DK-24) ──

  void _taskMgrTap(int x, int y) {
    final rows = taskMgrRows(_windows);
    final v = _p.taskMgr;
    final h = taskMgrHit(x, y, tab: v.tab, rows: rows.length);
    switch (h.kind) {
      case TaskMgrHitKind.tab:
        _p.taskMgr = v.copyWith(tab: h.value);
      case TaskMgrHitKind.row:
        _p.taskMgr = v.copyWith(sel: h.value);
      case TaskMgrHitKind.endTask when v.sel >= 0 && v.sel < rows.length:
        _p.taskMgr = v.copyWith(sel: -1);
        unawaited(_windowOff(rows[v.sel], close: true));
      case TaskMgrHitKind.switchTo when v.sel >= 0 && v.sel < rows.length:
        unawaited(openProgram(rows[v.sel]));
        return;
      default:
        return;
    }
    notifyListeners();
    unawaited(_sendTaskMgr());
  }

  Future<void> _sendTaskMgr() => _control.programView('taskmgr', _p.taskMgr.toJson());

  // ── Thuộc tính màn hình (R-DK-26) ──

  void _displayTap(int x, int y) {
    final p = _p.display!;
    final h = displayHit(x, y, p);
    switch (h.kind) {
      case DisplayHitKind.none:
        return;
      case DisplayHitKind.ok:
        unawaited(_displayOk());
      case DisplayHitKind.cancel:
        unawaited(closeTop());
      case DisplayHitKind.apply:
        unawaited(_displaySave());
      default:
        _p.display = displayEdit(p, h);
        notifyListeners();
        unawaited(_sendDisplay());
    }
  }

  /// OK: saved, then the window closes (XP).
  Future<void> _displayOk() async {
    await _sendDisplay(down: 0);
    if (await _displaySave()) await closeTop();
  }

  /// Áp dụng: the pending values become the device's settings; the window stays. False = not saved.
  Future<bool> _displaySave() async {
    final p = _p.display;
    if (p == null) return false;
    if (p.dirty) {
      final values = p.pending.toSettings();
      final r = await _control.saveSettings(values);
      if (r is Error<ControlOutcome>) return false;
      _settings = {...?_settings, ...values};
      _p.display = p.copyWith(saved: p.pending);
      notifyListeners();
    }
    await _sendDisplay();
    return true;
  }

  Future<void> _sendDisplay({int down = -1}) async {
    final p = _p.display;
    if (p != null) await _control.programView('display', displayBody(p, down: down));
  }

  // ── Máy tính bỏ túi (R-DK-27) ──

  /// How long a clicked key stays drawn pressed.
  static const calcKeyDown = Duration(milliseconds: 150);

  void _calcPress(CalcKey k) {
    _p.calc = calcPress(_p.calc, k);
    notifyListeners();
    unawaited(_control.programView('calc', calcBody(_p.calc, down: k)));
    Timer(calcKeyDown, () => unawaited(_sendCalc()));
  }

  Future<void> _sendCalc() => _control.programView('calc', calcBody(_p.calc));

  // ── Explorer (R-DK-28) ──

  void _explorerTap(int x, int y) {
    final now = _now();
    final last = _p.clickAt;
    final double = last != null && isDoubleClick(_p.clickX, _p.clickY, x, y, now.difference(last));
    _p.clickAt = double ? null : now;
    _p.clickX = x;
    _p.clickY = y;
    final v = _p.explorer;
    final h = explorerHit(x, y, v, photos: _p.photos, trash: _xp.trash);
    switch (h.kind) {
      case ExplorerHitKind.openPhotos when double:
        _p.explorer = const ExplorerView(place: ExplorerPlace.photos);
        unawaited(_loadPhotoCount());
      case ExplorerHitKind.item:
        _p.explorer = v.copyWith(sel: h.value);
        if (double && h.value >= 0 && v.place == ExplorerPlace.photos) {
          unawaited(_explorerOpenPhoto());
          return;
        }
      case ExplorerHitKind.restore:
        _p.explorer = v.copyWith(sel: -1);
        notifyListeners();
        unawaited(_control.programView('explorer', explorerBody(_p.explorer, doIt: 'restore')..['sel'] = v.sel));
        return;
      case ExplorerHitKind.empty:
        _p.explorer = v.copyWith(confirmEmpty: true);
      case ExplorerHitKind.yes:
        _p.explorer = v.copyWith(confirmEmpty: false, sel: -1);
        notifyListeners();
        unawaited(_control.programView('explorer', explorerBody(_p.explorer, doIt: 'empty')));
        return;
      case ExplorerHitKind.no:
        _p.explorer = v.copyWith(confirmEmpty: false);
      default:
        return;
    }
    notifyListeners();
    unawaited(_sendExplorer());
  }

  /// Nhấp đúp / Enter on a photo: the Photo window shows it (`do: open`, then the window comes up).
  Future<void> _explorerOpenPhoto() async {
    notifyListeners();
    await _control.programView('explorer', explorerBody(_p.explorer, doIt: 'open'));
    await openProgram('Photo');
  }

  Future<void> _sendExplorer() => _control.programView('explorer', explorerBody(_p.explorer));

  /// Ảnh của tôi lists the device's photos then its samples (`/api/photos`).
  Future<void> _loadPhotoCount() async {
    final r = await _device.photos();
    if (r case Ok(:final value)) {
      _p.photos = value.photos.length + value.samples;
      notifyListeners();
    }
  }

  // ── Keys (R-DK-25…28) ──

  /// A key for the program window on screen / the Alt+Tab box; true = it was handled here.
  Future<bool> _programKey(ControlKey key) async {
    if (_p.altSel != null) {
      if (key == ControlKey.altTab) {
        _altTabStep();
      } else if (key == ControlKey.escape) {
        await _altTabEnd(commit: false);
      } else {
        await _altTabEnd(commit: true);
        return false;
      }
      return true;
    }
    if (key == ControlKey.altTab && _xp.altTab) {
      if (_windows.open.isEmpty) return true;
      _p.altOrder = altTabOrder(_windows);
      _p.altSel = null;
      _altTabStep();
      return true;
    }
    if (_menu != null || _startOpen) return false;
    switch (channel) {
      case displayProgram when _xp.display && _p.display != null:
        if (key == ControlKey.escape) {
          await closeTop();
          return true;
        }
        if (key == ControlKey.enter) {
          await _displayOk();
          return true;
        }
      case 'Calc' when _xp.calc:
        if (key == ControlKey.enter) {
          _calcPress(CalcKey.equals);
          return true;
        }
        if (key == ControlKey.escape) {
          _calcPress(CalcKey.c);
          return true;
        }
      case taskMgrProgram when _xp.taskMgr && _p.taskMgr.tab == 0:
        final rows = taskMgrRows(_windows);
        final v = _p.taskMgr;
        if ((key == ControlKey.down || key == ControlKey.up) && rows.isNotEmpty) {
          final d = key == ControlKey.down ? 1 : -1;
          _p.taskMgr = v.copyWith(sel: v.sel < 0 ? 0 : (v.sel + d).clamp(0, rows.length - 1));
          notifyListeners();
          await _sendTaskMgr();
          return true;
        }
        if (key == ControlKey.enter && v.sel >= 0 && v.sel < rows.length) {
          await openProgram(rows[v.sel]);
          return true;
        }
      case explorerProgram when _xp.explorer && _p.explorer.place == ExplorerPlace.photos:
        final (dx, dy) = switch (key) {
          ControlKey.left => (-1, 0),
          ControlKey.right => (1, 0),
          ControlKey.up => (0, -1),
          ControlKey.down => (0, 1),
          _ => (0, 0),
        };
        if (dx != 0 || dy != 0) {
          _p.explorer = explorerMove(_p.explorer, dx, dy, _p.photos);
          notifyListeners();
          await _sendExplorer();
          return true;
        }
        if (key == ControlKey.enter && _p.explorer.sel >= 0) {
          await _explorerOpenPhoto();
          return true;
        }
    }
    return false;
  }

  // ── Alt+Tab (R-DK-25) ──

  void _altTabStep() {
    final n = _p.altOrder.length;
    _p.altSel = altTabNext(_p.altSel, n);
    _p.altTimer?.cancel();
    _p.altTimer = Timer(altTabRelease, () => unawaited(_altTabEnd(commit: true)));
    notifyListeners();
    unawaited(_control.altTab(_p.altSel));
  }

  /// Alt let go ([commit]: the chosen window comes to the top) or Esc.
  Future<void> _altTabEnd({required bool commit}) async {
    _p.altTimer?.cancel();
    _p.altTimer = null;
    final sel = _p.altSel;
    _p.altSel = null;
    notifyListeners();
    await _control.altTab(null);
    if (!commit || sel == null || sel < 0 || sel >= _p.altOrder.length) return;
    final win = _p.altOrder[sel];
    if (win != _shownWindow) await openProgram(win);
  }
}
