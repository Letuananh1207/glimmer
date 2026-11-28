// The device's "Ngày và Giờ" window as the user touched it on the app (panel P-2026-11-26.22, R-DK-16) — the same
// state the firmware keeps (`ClockCore::View`, POST /api/clock).

/// Pages of XP's Date and Time Properties.
enum ClockTab { date, zone, net }

/// The drop-down list open on the page.
enum ClockList { none, month, zone }

/// Tab, the month / year on view (null = today's), a chosen day (null = none), the open list and its first row.
class ClockView {
  const ClockView({
    this.tab = ClockTab.date,
    this.year,
    this.month,
    this.day,
    this.list = ClockList.none,
    this.top = 0,
  });

  static const today = ClockView();

  final ClockTab tab;
  final int? year, month, day;
  final ClockList list;
  final int top;

  ClockView copyWith({
    ClockTab? tab,
    int? year,
    int? month,
    int? day,
    bool clearDay = false,
    ClockList? list,
    int? top,
  }) => ClockView(
    tab: tab ?? this.tab,
    year: year ?? this.year,
    month: month ?? this.month,
    day: clearDay ? null : (day ?? this.day),
    list: list ?? this.list,
    top: top ?? this.top,
  );

  /// `POST /api/clock` body (0 = today's / none on the device).
  Map<String, Object?> toJson() => {
    'tab': tab.index,
    'year': year ?? 0,
    'month': month ?? 0,
    'day': day ?? 0,
    'list': list.name,
    'top': top,
  };

  @override
  bool operator ==(Object other) =>
      other is ClockView &&
      other.tab == tab &&
      other.year == year &&
      other.month == month &&
      other.day == day &&
      other.list == list &&
      other.top == top;

  @override
  int get hashCode => Object.hash(tab, year, month, day, list, top);

  @override
  String toString() => 'ClockView($tab, $year/$month/$day, $list@$top)';
}

// ── Geometry shared with the firmware's `clock_core.h` (the mirror draws it, the rules read touches on it) ──

/// The time zones the device lists, in its order (`ClockCore::kZoneMin`); names are `devXpZoneName` by index.
const clockZones = [-480, -300, -180, 0, 60, 180, 240, 330, 420, 480, 540, 600];

/// "(GMT+07:00)" of an offset in minutes.
String gmtParen(int tzMin) {
  final a = tzMin.abs();
  return '(GMT${tzMin < 0 ? '-' : '+'}${(a ~/ 60).toString().padLeft(2, '0')}:${(a % 60).toString().padLeft(2, '0')})';
}

/// Column of the world map (27 columns) the zone's middle longitude falls in.
int mapColumn(int tzMin) => ((((tzMin * 10 ~/ 4) + 1800) * 3 + 200) ~/ 400).clamp(0, 26);

/// Land cells of the map (token themeXP.dateTime.p22.zone.landRows): column ranges per row.
const mapLand = [
  [(4, 8), (9, 12), (18, 24)], [(1, 8), (10, 11), (14, 26)], [(3, 9), (13, 25)], [(4, 8), (13, 23), (24, 24)], //
  [(5, 7), (12, 22)], [(6, 7), (12, 17), (19, 19), (21, 22)], [(8, 10), (14, 16), (21, 23)], //
  [(8, 10), (15, 16), (23, 24)], [(8, 10), (15, 16), (22, 25)], [(8, 9), (24, 24), (26, 26)], [(8, 8)],
];

bool mapIsLand(int row, int col) => mapLand[row].any((s) => col >= s.$1 && col <= s.$2);

/// Drop-down lists: 9 rows of 13 px.
const listRows = 9, listRowH = 13;
int listCount(ClockList l) => switch (l) {
  ClockList.month => 12,
  ClockList.zone => clockZones.length,
  ClockList.none => 0,
};
int listMaxTop(ClockList l) => (listCount(l) - listRows).clamp(0, 99);

/// First row shown when [l] opens on row [sel] (XP keeps the chosen row in view).
int listTopFor(ClockList l, int sel) => (sel - 4).clamp(0, listMaxTop(l));

/// Scroll bar thumb (top, height) in a track [y0, y0 + h).
(int, int) listThumb(ClockList l, int top, int y0, int h) {
  final n = listCount(l);
  final th = n > listRows ? h * listRows ~/ n : h;
  final m = listMaxTop(l);
  return (y0 + (m == 0 ? 0 : (h - th) * top ~/ m), th);
}
