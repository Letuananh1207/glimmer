// The XP programs of panel P-2026-11-28.28…32 (R-DK-24…28): where the device draws their parts (numbers from the
// firmware: `src/channels/ch_taskmgr.cpp`, `src/data/display_core.h`, `ch_display.cpp`, `explorer_core.h`,
// `xp_core.h altTabOrder`) and what a click there does. The app keeps each view and sends it; the device draws.
import '../models/windows.dart';
import '../models/xp_views.dart';

bool _in(int x, int y, int bx, int by, int w, int h) => x >= bx && x < bx + w && y >= by && y < by + h;

/// The device's tab strip (y 26–41): the tab under ([x], [y]) for tabs starting at [starts] with [widths], else null.
int? _tabAt(int x, int y, List<int> starts, List<int> widths) {
  if (y < 26 || y > 41) return null;
  for (var i = 0; i < starts.length; i++) {
    if (x >= starts[i] && x < starts[i] + widths[i]) return i;
  }
  return null;
}

// ── Trình quản lý tác vụ (R-DK-24) ──

const taskMgrProgram = 'TaskMgr';

/// R-DK-24: the rows of Ứng dụng — the open windows but Trình quản lý tác vụ, in opening order, at most 5.
List<String> taskMgrRows(WindowStack w) => [...w.open.where((p) => p != taskMgrProgram)].take(5).toList();

enum TaskMgrHitKind { none, tab, row, endTask, switchTo }

class TaskMgrHit {
  const TaskMgrHit(this.kind, [this.value = -1]);

  static const none = TaskMgrHit(TaskMgrHitKind.none);
  final TaskMgrHitKind kind;

  /// The tab, or the row (−1 = the list's empty part: deselect).
  final int value;
}

/// R-DK-24: what a left click at ([x], [y]) hits on Trình quản lý tác vụ showing [tab] with [rows] rows.
TaskMgrHit taskMgrHit(int x, int y, {required int tab, required int rows}) {
  final t = _tabAt(x, y, const [6, 72, 145], const [66, 73, 38]);
  if (t != null) return TaskMgrHit(TaskMgrHitKind.tab, t);
  if (tab != 0) return TaskMgrHit.none;
  if (_in(x, y, 11, 64, 218, 18 * 5)) {
    final i = (y - 64) ~/ 18;
    return TaskMgrHit(TaskMgrHitKind.row, i < rows ? i : -1);
  }
  if (_in(x, y, 10, 46, 220, 112)) return const TaskMgrHit(TaskMgrHitKind.row, -1);
  if (_in(x, y, 26, 165, 117, 21)) return const TaskMgrHit(TaskMgrHitKind.endTask);
  if (_in(x, y, 147, 165, 82, 21)) return const TaskMgrHit(TaskMgrHitKind.switchTo);
  return TaskMgrHit.none;
}

// ── Alt+Tab (R-DK-25) ──

/// R-DK-25: how long without another Alt+Tab counts as letting Alt go.
const altTabRelease = Duration(seconds: 1);

/// R-DK-25: the box's tiles — the window on top, then the others newest opened first (firmware `altTabOrder`).
List<String> altTabOrder(WindowStack w) {
  final top = w.top;
  return [
    if (top != null && w.open.contains(top)) top,
    for (final p in w.open.reversed)
      if (p != top) p,
  ];
}

/// R-DK-25: the tile chosen after one more Alt+Tab ([sel] null = the box just opened).
int altTabNext(int? sel, int n) {
  if (n <= 0) return -1;
  if (sel == null) return n > 1 ? 1 : 0;
  return (sel + 1) % n;
}

// ── Thuộc tính màn hình (R-DK-26) ──

const displayProgram = 'Display';

enum DisplayHitKind { none, tab, wallpaper, toggleList, saver, closeList, idle, brightness, invert, ok, cancel, apply }

class DisplayHit {
  const DisplayHit(this.kind, [this.value = 0]);

  static const none = DisplayHit(DisplayHitKind.none);
  final DisplayHitKind kind;

  /// The tab / row / brightness %.
  final int value;
}

/// R-DK-26: the brightness the slider gives at [x] (track x 20…127), 5–100.
int displayBrightnessAt(int x) => (((x - 20) * 100 / 107).round()).clamp(5, 100);

/// R-DK-26: what a left click at ([x], [y]) hits on Thuộc tính màn hình [p].
DisplayHit displayHit(int x, int y, DisplayProps p) {
  // The open mode list lies over the page: a row picks, anything else only closes it.
  if (p.tab == 1 && p.list) {
    if (_in(x, y, 97, 80, 130, 64)) return DisplayHit(DisplayHitKind.saver, (y - 80) ~/ 16);
    return const DisplayHit(DisplayHitKind.closeList);
  }
  final t = _tabAt(x, y, const [6, 63, 176], const [57, 113, 57]);
  if (t != null) return DisplayHit(DisplayHitKind.tab, t);
  if (_in(x, y, 53, 187, 49, 21)) return const DisplayHit(DisplayHitKind.ok);
  if (_in(x, y, 106, 187, 49, 21)) return const DisplayHit(DisplayHitKind.cancel);
  if (_in(x, y, 159, 187, 70, 21)) return p.dirty ? const DisplayHit(DisplayHitKind.apply) : DisplayHit.none;
  switch (p.tab) {
    case 0:
      final rows = p.photoWallpaper ? 3 : 2;
      if (_in(x, y, 97, 63, 130, 16 * rows)) return DisplayHit(DisplayHitKind.wallpaper, (y - 63) ~/ 16);
    case 1:
      if (_in(x, y, 96, 61, 132, 18)) return const DisplayHit(DisplayHitKind.toggleList);
      if (_in(x, y, 16, 152, 168, 14)) return const DisplayHit(DisplayHitKind.idle);
    default:
      if (_in(x, y, 14, 136, 120, 22)) return DisplayHit(DisplayHitKind.brightness, displayBrightnessAt(x));
      if (_in(x, y, 148, 158, 78, 14)) return const DisplayHit(DisplayHitKind.invert);
  }
  return DisplayHit.none;
}

/// R-DK-26: [p] after a click on [h] that only edits (tab, values, the list); OK / Hủy / Áp dụng are the caller's.
DisplayProps displayEdit(DisplayProps p, DisplayHit h) {
  final v = p.pending;
  return switch (h.kind) {
    DisplayHitKind.tab => p.copyWith(tab: h.value, list: false),
    DisplayHitKind.wallpaper => p.copyWith(pending: v.copyWith(wallpaper: h.value)),
    DisplayHitKind.toggleList => p.copyWith(list: !p.list),
    DisplayHitKind.saver => p.copyWith(pending: v.copyWith(saver: h.value), list: false),
    DisplayHitKind.closeList => p.copyWith(list: false),
    DisplayHitKind.idle => p.copyWith(pending: v.copyWith(idleDim: !v.idleDim)),
    DisplayHitKind.brightness => p.copyWith(pending: v.copyWith(brightness: h.value)),
    DisplayHitKind.invert => p.copyWith(pending: v.copyWith(invert: !v.invert)),
    _ => p,
  };
}

/// R-DK-26: `POST /api/display` — [down] = the button held (0 OK, 1 Hủy, 2 Áp dụng, −1 none).
Map<String, Object?> displayBody(DisplayProps p, {int down = -1}) => {
      'tab': p.tab,
      'wall': p.pending.wallpaper,
      'saver': p.pending.saver,
      'list': p.list,
      'bright': p.pending.brightness,
      'invert': p.pending.invert,
      'idle': p.pending.idleDim,
      'down': down,
    };

/// R-DK-26: the values Thuộc tính màn hình starts from — the device's `/api/settings`.
DisplayValues displayValuesOf(Map<String, dynamic>? settings) {
  int n(String k, int d) => settings?[k] is num ? (settings![k] as num).toInt() : d;
  bool b(String k, bool d) => settings?[k] is bool ? settings![k] as bool : d;
  return DisplayValues(
    wallpaper: n('wallpaperMode', 2).clamp(0, 2),
    saver: n('nightMode', 0).clamp(0, 3),
    brightness: n('brightness', 100).clamp(5, 100),
    invert: b('invertDisplay', true),
    idleDim: b('idleDim', true),
  );
}

// ── Explorer (R-DK-28) ──

const explorerProgram = 'Explorer';

/// R-DK-28: two left clicks this close in time and place are a double click.
const doubleClickTime = Duration(milliseconds: 500);
const doubleClickSlop = 4;

/// R-DK-28: Ảnh của tôi — 4 thumbnails a row, 2 rows on screen.
const explorerCols = 4, explorerRowsShown = 2;

/// R-DK-28: Thùng rác rows on screen.
const trashRowsShown = 6;

enum ExplorerHitKind { none, openPhotos, item, empty, restore, yes, no }

class ExplorerHit {
  const ExplorerHit(this.kind, [this.value = -1]);

  static const none = ExplorerHit(ExplorerHitKind.none);
  final ExplorerHitKind kind;

  /// The photo / bin row (−1 = an empty part: deselect).
  final int value;
}

/// R-DK-28: what a left click at ([x], [y]) hits on Explorer [v] with [photos] photos in Ảnh của tôi and [trash]
/// items in the bin.
ExplorerHit explorerHit(int x, int y, ExplorerView v, {required int photos, required int trash}) {
  if (v.confirmEmpty) {
    if (_in(x, y, 58, 134, 56, 21)) return const ExplorerHit(ExplorerHitKind.yes);
    if (_in(x, y, 126, 134, 56, 21)) return const ExplorerHit(ExplorerHitKind.no);
    return ExplorerHit.none;
  }
  switch (v.place) {
    case ExplorerPlace.computer:
      if (_in(x, y, 8, 118, 222, 34)) return const ExplorerHit(ExplorerHitKind.openPhotos);
    case ExplorerPlace.photos:
      if (!_in(x, y, 2, 22, 236, 174)) return ExplorerHit.none;
      final col = (x - 6) ~/ 57, row = (y - 28) ~/ 72;
      if (x >= 6 && y >= 28 && col < explorerCols && row < explorerRowsShown) {
        final i = (v.top + row) * explorerCols + col;
        return ExplorerHit(ExplorerHitKind.item, i < photos ? i : -1);
      }
      return const ExplorerHit(ExplorerHitKind.item, -1);
    case ExplorerPlace.trash:
      if (_in(x, y, 6, 26, 136, 21)) return trash > 0 ? const ExplorerHit(ExplorerHitKind.empty) : ExplorerHit.none;
      if (_in(x, y, 146, 26, 75, 21)) {
        return trash > 0 && v.sel >= 0 ? const ExplorerHit(ExplorerHitKind.restore) : ExplorerHit.none;
      }
      if (_in(x, y, 7, 70, 226, 18 * trashRowsShown)) {
        final i = (y - 70) ~/ 18;
        return ExplorerHit(ExplorerHitKind.item, i < trash ? i : -1);
      }
      if (_in(x, y, 7, 53, 226, 138)) return const ExplorerHit(ExplorerHitKind.item, -1);
  }
  return ExplorerHit.none;
}

/// R-DK-28: Ảnh của tôi — [v] after an arrow key ([dx], [dy] cells) among [photos]; the rows scroll to keep the
/// selection in sight. Nothing selected → the first photo.
ExplorerView explorerMove(ExplorerView v, int dx, int dy, int photos) {
  if (photos <= 0) return v;
  final sel = v.sel < 0 ? 0 : (v.sel + dx + dy * explorerCols).clamp(0, photos - 1);
  final row = sel ~/ explorerCols;
  final top = row < v.top ? row : (row >= v.top + explorerRowsShown ? row - explorerRowsShown + 1 : v.top);
  return v.copyWith(sel: sel, top: top);
}

/// R-DK-28: `POST /api/explorer` for [v], with the command [doIt] (`open`, `restore`, `empty`) when there is one.
Map<String, Object?> explorerBody(ExplorerView v, {String? doIt}) => {
      'place': v.place.name,
      'sel': v.sel,
      'top': v.top,
      'confirm': v.confirmEmpty ? 'empty' : 'none',
      'do': ?doIt,
    };

/// R-DK-28: two left clicks at ([x0], [y0]) then ([x1], [y1]), [gap] apart, are a double click.
bool isDoubleClick(int x0, int y0, int x1, int y1, Duration gap) =>
    gap <= doubleClickTime && (x1 - x0).abs() <= doubleClickSlop && (y1 - y0).abs() <= doubleClickSlop;
