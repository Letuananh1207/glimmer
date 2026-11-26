import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/windows.dart';

void main() {
  test('R-DK-7 opening puts a window on top; activating keeps its taskbar place (XP)', () {
    final w = WindowStack.empty.opened('Claude').opened('Weather');
    expect(w.open, ['Claude', 'Weather']);
    expect(w.top, 'Weather');
    final again = w.opened('Claude');
    expect(again.open, ['Claude', 'Weather'], reason: 'taskbar order = opening order');
    expect(again.z, ['Weather', 'Claude']);
    expect(again.top, 'Claude');
  });

  test('R-DK-8 minimize: the desktop shows, the window stays (taskbar button)', () {
    final w = WindowStack.empty.opened('Claude').minimize('Claude');
    expect(w.top, isNull);
    expect(w.open, ['Claude']);
    expect(w.minimized, {'Claude'});
    expect(w.opened('Claude').minimized, isEmpty);
  });

  test('R-DK-8 close: gone, the most recently active window comes up; none left → desktop', () {
    final w = WindowStack.empty.opened('Claude').opened('Weather').opened('Clock').opened('Claude');
    final c = w.close('Claude');
    expect(c.open, ['Weather', 'Clock']);
    expect(c.top, 'Clock', reason: 'activated before Claude');
    expect(c.close('Clock').close('Weather').top, isNull);
  });

  test('R-DK-8 close skips minimized windows', () {
    final w = WindowStack.empty.opened('Claude').minimize('Claude').opened('Clock').opened('Weather');
    final c = w.close('Weather');
    expect(c.top, 'Clock');
    expect(c.close('Clock').top, isNull);
    expect(c.close('Clock').open, ['Claude']);
  });

  test('Start → Desktop minimizes every window', () {
    final w = WindowStack.empty.opened('Claude').opened('Clock').minimizeAll();
    expect(w.top, isNull);
    expect(w.minimized, {'Claude', 'Clock'});
  });

  test('R-DK-9 only keeps the windows of installed programs; a selected icon goes with them', () {
    final w = WindowStack.empty.opened('Clock').opened('Claude').minimize('Claude').select('Clock');
    final k = w.only((p) => p != 'Clock');
    expect(k.open, ['Claude']);
    expect(k.minimized, {'Claude'});
    expect(k.sel, isNull);
    expect(WindowStack.empty.opened('Clock').only((p) => p != 'Clock').top, isNull);
  });

  test('R-DK-9 the selected icon: kept by minimize, cleared by opening a window', () {
    final w = WindowStack.empty.select('Clock');
    expect(w.sel, 'Clock');
    expect(w.opened('Claude').sel, isNull);
    expect(w.opened('Claude').minimize('Claude').select('Clock').minimize('Claude').sel, 'Clock');
  });

  test('R-DK-7 the list sent down (POST /api/windows)', () {
    final w = WindowStack.empty.opened('Claude').opened('Weather').minimize('Claude');
    expect(w.toJson(), {
      'open': ['Claude', 'Weather'],
      'top': 'Weather',
      'min': ['Claude'],
      'sel': null,
    });
  });
}
