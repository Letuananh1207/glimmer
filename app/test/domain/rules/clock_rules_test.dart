import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/clock_view.dart';
import 'package:glimmer_app/domain/rules/clock_rules.dart';

ClockHit _hit(double x, double y, [ClockView v = ClockView.today]) => clockHitAt(x, y, v, year: 2026, month: 11);

void main() {
  test('R-DK-16 geometry shared with the firmware', () {
    expect(gmtParen(420), '(GMT+07:00)');
    expect(gmtParen(-180), '(GMT-03:00)');
    expect(gmtParen(330), '(GMT+05:30)');
    expect(mapColumn(420), 21);
    expect(mapColumn(0), 14);
    expect(mapColumn(-480), 5);
    expect(mapIsLand(1, 20), isTrue);
    expect(mapIsLand(5, 21), isTrue);
    expect(mapIsLand(1, 0), isFalse);
    expect(listTopFor(ClockList.month, 10), 3);
    expect(listTopFor(ClockList.month, 1), 0);
    expect(listThumb(ClockList.month, 0, 89, 97), (89, 72));
  });

  test('R-DK-16 tabs, month field, year spin, days', () {
    expect(_hit(30, 34), const ClockHit(ClockHitKind.tab, 0));
    expect(_hit(120, 34), const ClockHit(ClockHitKind.tab, 1));
    expect(_hit(180, 34), const ClockHit(ClockHitKind.tab, 2));
    expect(_hit(40, 70), const ClockHit(ClockHitKind.monthList));
    expect(_hit(121, 65), const ClockHit(ClockHitKind.yearUp));
    expect(_hit(121, 74), const ClockHit(ClockHitKind.yearDown));
    // November 2026 starts on a Sunday: the first row is 26..31 of October, then 1.
    expect(_hit(13 + 16 * 6 + 4, 100), const ClockHit(ClockHitKind.day, 1));
    expect(_hit(13 + 4, 100), ClockHit.none, reason: 'a day of the previous month');
    expect(_hit(13 + 16 * 3 + 4, 98 + 13 * 4 + 3), const ClockHit(ClockHitKind.day, 26));
  });

  test('R-DK-16 an open list: rows pick, scroll buttons scroll, outside closes', () {
    const m = ClockView(list: ClockList.month, top: 3);
    expect(_hit(30, 79 + 13 * 7 + 2, m), const ClockHit(ClockHitKind.pickMonth, 11));
    expect(_hit(74, 82, m), const ClockHit(ClockHitKind.scrollUp));
    expect(_hit(74, 190, m), const ClockHit(ClockHitKind.scrollDown));
    expect(_hit(200, 120, m), const ClockHit(ClockHitKind.closeList));
    const z = ClockView(tab: ClockTab.zone, list: ClockList.zone, top: 3);
    expect(_hit(60, 69 + 13 * 6 + 2, z), const ClockHit(ClockHitKind.pickZone, 9));
    expect(_hit(60, 58, const ClockView(tab: ClockTab.zone)), const ClockHit(ClockHitKind.zoneList));
    expect(_hit(170, 108, const ClockView(tab: ClockTab.net)), const ClockHit(ClockHitKind.sync));
  });

  test('R-DK-16 the body sent down (POST /api/clock)', () {
    expect(ClockView.today.toJson(), {'tab': 0, 'year': 0, 'month': 0, 'day': 0, 'list': 'none', 'top': 0});
    expect(const ClockView(tab: ClockTab.date, year: 2027, month: 3, list: ClockList.month, top: 2).toJson(), {
      'tab': 0,
      'year': 2027,
      'month': 3,
      'day': 0,
      'list': 'month',
      'top': 2,
    });
  });
}
