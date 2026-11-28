import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/windows.dart';
import 'package:glimmer_app/domain/models/xp_views.dart';
import 'package:glimmer_app/domain/rules/xp_program_rules.dart';

WindowStack _open(List<String> programs) {
  var w = WindowStack.empty;
  for (final p in programs) {
    w = w.opened(p);
  }
  return w;
}

const _values = DisplayValues(wallpaper: 2, saver: 0, brightness: 80, invert: true, idleDim: true);

void main() {
  group('R-DK-24 Trình quản lý tác vụ', () {
    test('rows = the open windows but itself, opening order, ≤ 5', () {
      expect(taskMgrRows(_open(['Claude', 'Photo', 'TaskMgr', 'Clock'])), ['Claude', 'Photo', 'Clock']);
      expect(taskMgrRows(_open(['a', 'b', 'c', 'd', 'e', 'f'])), hasLength(5));
    });

    test('tabs, rows, empty list, buttons', () {
      TaskMgrHit hit(int x, int y, {int tab = 0, int rows = 2}) => taskMgrHit(x, y, tab: tab, rows: rows);
      expect((hit(10, 30).kind, hit(10, 30).value), (TaskMgrHitKind.tab, 0));
      expect(hit(100, 35).value, 1);
      expect(hit(160, 35).value, 2);
      expect(hit(190, 35).kind, TaskMgrHitKind.none, reason: 'right of Mạng');
      expect((hit(100, 82).kind, hit(100, 82).value), (TaskMgrHitKind.row, 1));
      expect(hit(100, 110).value, -1, reason: 'below the last row → deselect');
      expect(hit(50, 170).kind, TaskMgrHitKind.endTask);
      expect(hit(200, 170).kind, TaskMgrHitKind.switchTo);
      expect(hit(50, 170, tab: 1).kind, TaskMgrHitKind.none, reason: 'only on Ứng dụng');
      expect(const TaskMgrView(tab: 1, sel: 0).toJson(), {'tab': 1, 'sel': 0});
    });
  });

  group('R-DK-25 Alt+Tab', () {
    test('order: the window on top, then newest opened first', () {
      final w = _open(['Claude', 'Photo', 'Clock']);
      expect(altTabOrder(w), ['Clock', 'Photo', 'Claude']);
      expect(altTabOrder(w.opened('Claude')), ['Claude', 'Clock', 'Photo']);
      expect(altTabOrder(WindowStack.empty), isEmpty);
    });

    test('first press picks the second tile (one window → itself); then round', () {
      expect(altTabNext(null, 3), 1);
      expect(altTabNext(null, 1), 0);
      expect(altTabNext(1, 3), 2);
      expect(altTabNext(2, 3), 0);
      expect(altTabNext(null, 0), -1);
    });
  });

  group('R-DK-26 Thuộc tính màn hình', () {
    DisplayProps props({int tab = 0, bool list = false, bool photo = true}) =>
        DisplayProps(tab: tab, saved: _values, pending: _values, list: list, photoWallpaper: photo);

    test('tabs, wallpaper rows (Ảnh của bạn only with a photo), buttons; Áp dụng only when changed', () {
      expect(displayHit(10, 30, props()).value, 0);
      expect(displayHit(100, 30, props()).value, 1);
      expect(displayHit(200, 30, props()).value, 2);
      expect((displayHit(120, 70, props()).kind, displayHit(120, 70, props()).value), (DisplayHitKind.wallpaper, 0));
      expect(displayHit(120, 100, props()).value, 2);
      expect(displayHit(120, 100, props(photo: false)).kind, DisplayHitKind.none);
      expect(displayHit(60, 195, props()).kind, DisplayHitKind.ok);
      expect(displayHit(120, 195, props()).kind, DisplayHitKind.cancel);
      expect(displayHit(180, 195, props()).kind, DisplayHitKind.none, reason: 'nothing changed');
      final changed = displayEdit(props(), displayHit(120, 85, props()));
      expect((changed.pending.wallpaper, changed.dirty), (1, true));
      expect(displayHit(180, 195, changed).kind, DisplayHitKind.apply);
    });

    test('saver: the field opens the list; a row picks and closes; elsewhere only closes', () {
      final open = displayEdit(props(tab: 1), displayHit(150, 68, props(tab: 1)));
      expect(open.list, isTrue);
      final picked = displayEdit(open, displayHit(150, 115, open));
      expect((picked.pending.saver, picked.list), (2, false));
      final closed = displayEdit(open, displayHit(30, 190, open));
      expect((closed.list, closed.pending.saver), (false, 0), reason: 'OK under the list does not fire');
      final idle = displayEdit(props(tab: 1), displayHit(20, 155, props(tab: 1)));
      expect(idle.pending.idleDim, isFalse);
    });

    test('brightness slider (x 20…127 → 0…100, kept 5–100), invert', () {
      expect(displayBrightnessAt(73), 50);
      expect(displayBrightnessAt(14), 5);
      expect(displayBrightnessAt(133), 100);
      final p = displayEdit(props(tab: 2), displayHit(73, 145, props(tab: 2)));
      expect(p.pending.brightness, 50);
      expect(displayEdit(props(tab: 2), displayHit(170, 162, props(tab: 2))).pending.invert, isFalse);
    });

    test('bodies: /api/display and the settings OK / Áp dụng save; start from /api/settings', () {
      expect(displayBody(props(), down: 0), {
        'tab': 0, 'wall': 2, 'saver': 0, 'list': false, 'bright': 80, 'invert': true, 'idle': true, 'down': 0, //
      });
      expect(_values.toSettings(), {
        'wallpaperMode': 2, 'nightMode': 0, 'brightness': 80, 'invertDisplay': true, 'idleDim': true, //
      });
      final v = displayValuesOf({'wallpaperMode': 1, 'nightMode': 2, 'brightness': 40, 'invertDisplay': false});
      expect((v.wallpaper, v.saver, v.brightness, v.invert, v.idleDim), (1, 2, 40, false, true));
    });
  });

  group('R-DK-28 Explorer', () {
    test('Máy tính: Ảnh của tôi', () {
      expect(explorerHit(100, 130, const ExplorerView(), photos: 8, trash: 0).kind, ExplorerHitKind.openPhotos);
      expect(explorerHit(100, 170, const ExplorerView(), photos: 8, trash: 0).kind, ExplorerHitKind.none);
    });

    test('Ảnh của tôi: thumbnail cells from the top row; empty cell → deselect; arrows scroll', () {
      const v = ExplorerView(place: ExplorerPlace.photos);
      expect(explorerHit(70, 40, v, photos: 10, trash: 0).value, 1);
      expect(explorerHit(70, 110, v, photos: 10, trash: 0).value, 5);
      expect(explorerHit(70, 110, v.copyWith(top: 1), photos: 10, trash: 0).value, 9);
      expect(explorerHit(130, 110, v.copyWith(top: 1), photos: 10, trash: 0).value, -1);
      var m = explorerMove(v, 0, 1, 10);
      expect((m.sel, m.top), (0, 0), reason: 'nothing selected → the first');
      m = explorerMove(explorerMove(m, 0, 1, 10), 0, 1, 10);
      expect((m.sel, m.top), (8, 1));
      expect(explorerMove(m, 1, 0, 10).sel, 9);
      expect(explorerMove(m.copyWith(sel: 9), 1, 0, 10).sel, 9, reason: 'stops at the last');
    });

    test('Thùng rác: rows, Khôi phục needs a row, Dọn sạch needs items; the box Có / Không', () {
      const v = ExplorerView(place: ExplorerPlace.trash);
      expect(explorerHit(100, 75, v, photos: 0, trash: 2).value, 0);
      expect(explorerHit(100, 120, v, photos: 0, trash: 2).value, -1);
      expect(explorerHit(180, 35, v, photos: 0, trash: 2).kind, ExplorerHitKind.none);
      expect(explorerHit(180, 35, v.copyWith(sel: 1), photos: 0, trash: 2).kind, ExplorerHitKind.restore);
      expect(explorerHit(50, 35, v, photos: 0, trash: 2).kind, ExplorerHitKind.empty);
      expect(explorerHit(50, 35, v, photos: 0, trash: 0).kind, ExplorerHitKind.none);
      final box = v.copyWith(confirmEmpty: true);
      expect(explorerHit(80, 140, box, photos: 0, trash: 2).kind, ExplorerHitKind.yes);
      expect(explorerHit(150, 140, box, photos: 0, trash: 2).kind, ExplorerHitKind.no);
      expect(explorerBody(box, doIt: 'empty'), {'place': 'trash', 'sel': -1, 'top': 0, 'confirm': 'empty', 'do': 'empty'});
      expect(explorerBody(v).containsKey('do'), isFalse);
    });

    test('double click: ≤ 500 ms and ≤ 4 px', () {
      expect(isDoubleClick(10, 10, 13, 12, const Duration(milliseconds: 400)), isTrue);
      expect(isDoubleClick(10, 10, 16, 10, const Duration(milliseconds: 100)), isFalse);
      expect(isDoubleClick(10, 10, 10, 10, const Duration(milliseconds: 600)), isFalse);
    });
  });
}
