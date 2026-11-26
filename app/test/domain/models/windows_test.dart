import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/windows.dart';

void main() {
  test('R-DK-7 opening puts a window on top, in opening order', () {
    final w = WindowStack.empty.opened('Claude').opened('Weather');
    expect(w.open, ['Claude', 'Weather']);
    expect(w.top, 'Weather');
    final again = w.opened('Claude');
    expect(again.open, ['Weather', 'Claude']);
    expect(again.top, 'Claude');
  });

  test('R-DK-8 minimize: the desktop shows, the window stays (taskbar button)', () {
    final w = WindowStack.empty.opened('Claude').minimize('Claude');
    expect(w.top, isNull);
    expect(w.open, ['Claude']);
    expect(w.minimized, {'Claude'});
    expect(w.opened('Claude').minimized, isEmpty);
  });

  test('R-DK-8 close: gone, the window before it comes up; none left → desktop', () {
    final w = WindowStack.empty.opened('Claude').opened('Weather').close('Weather');
    expect(w.open, ['Claude']);
    expect(w.top, 'Claude');
    expect(w.close('Claude').top, isNull);
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

  test('R-DK-9 only keeps the windows of installed programs', () {
    final w = WindowStack.empty.opened('Clock').opened('Claude').minimize('Claude').only((p) => p != 'Clock');
    expect(w.open, ['Claude']);
    expect(w.minimized, {'Claude'});
    expect(WindowStack.empty.opened('Clock').only((p) => p != 'Clock').top, isNull);
  });
}
