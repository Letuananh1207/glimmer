// Ngày và Giờ touched like XP (panel P-2026-11-26.22, R-DK-16) — the app's reading of a touch on the firmware's
// layout (`ch_clock.cpp`); the shared geometry is in models/clock_view.dart. Pure, unit-tested.
import '../models/clock_view.dart';

/// What a touch on the Ngày và Giờ window does.
enum ClockHitKind {
  none,
  tab,
  monthList,
  yearUp,
  yearDown,
  day,
  pickMonth,
  zoneList,
  pickZone,
  scrollUp,
  scrollDown,
  closeList,
  sync,
}

class ClockHit {
  const ClockHit(this.kind, [this.value = 0]);

  static const none = ClockHit(ClockHitKind.none);

  final ClockHitKind kind;

  /// The tab, day, month (1–12) or zone index.
  final int value;

  @override
  bool operator ==(Object other) => other is ClockHit && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => 'ClockHit($kind, $value)';
}

bool _in(double x, double y, int rx, int ry, int rw, int rh) => x >= rx && x < rx + rw && y >= ry && y < ry + rh;

/// Tabs from x 6: Ngày và giờ 87, Múi giờ 59, Internet 66 wide (y 26–41).
const _tabX = [6, 93, 152, 218];

/// R-DK-16: what a touch at ([x], [y]) (device px) on the Clock window hits, given [view] and the device's [year] /
/// [month] of today (for the calendar of today's month) — the firmware's layout (`ch_clock.cpp`).
ClockHit clockHitAt(double x, double y, ClockView view, {required int year, required int month}) {
  if (y >= 26 && y < 42) {
    for (var i = 0; i < 3; i++) {
      if (x >= _tabX[i] && x < _tabX[i + 1]) return ClockHit(ClockHitKind.tab, i);
    }
    return ClockHit.none;
  }
  switch (view.tab) {
    case ClockTab.date:
      if (view.list == ClockList.month) return _listHit(x, y, 14, 78, 67, view, ClockHitKind.pickMonth, 1);
      if (_in(x, y, 14, 62, 67, 16)) return const ClockHit(ClockHitKind.monthList);
      if (_in(x, y, 112, 60, 20, 10)) return const ClockHit(ClockHitKind.yearUp);
      if (_in(x, y, 112, 70, 20, 10)) return const ClockHit(ClockHitKind.yearDown);
      if (_in(x, y, 13, 98, 112, 78)) {
        final i = ((y - 98) ~/ 13) * 7 + (x - 13) ~/ 16;
        final vy = view.year ?? year, vm = view.month ?? month;
        final lead = (DateTime(vy, vm).weekday - 1) % 7;
        final n = DateTime(vy, vm + 1, 0).day;
        final d = i - lead + 1;
        return d >= 1 && d <= n ? ClockHit(ClockHitKind.day, d) : ClockHit.none;
      }
    case ClockTab.zone:
      if (view.list == ClockList.zone) return _listHit(x, y, 12, 68, 216, view, ClockHitKind.pickZone, 0);
      if (_in(x, y, 12, 50, 216, 18)) return const ClockHit(ClockHitKind.zoneList);
    case ClockTab.net:
      if (_in(x, y, 125, 98, 103, 21)) return const ClockHit(ClockHitKind.sync);
  }
  return ClockHit.none;
}

/// A touch while a drop-down list (x, y, w × 119) is open: a row picks (value = index + [base]), the scroll buttons
/// scroll, anywhere outside closes it (XP).
ClockHit _listHit(double x, double y, int lx, int ly, int w, ClockView view, ClockHitKind pick, int base) {
  const h = 2 + listRows * listRowH;
  if (!_in(x, y, lx, ly, w, h)) return const ClockHit(ClockHitKind.closeList);
  final sbx = lx + w - 11;
  if (x >= sbx) {
    if (y < ly + 11) return const ClockHit(ClockHitKind.scrollUp);
    if (y >= ly + h - 11) return const ClockHit(ClockHitKind.scrollDown);
    return ClockHit.none;
  }
  final r = (y - ly - 1) ~/ listRowH;
  final i = view.top + r;
  return r >= 0 && r < listRows && i < listCount(view.list) ? ClockHit(pick, i + base) : ClockHit.none;
}
