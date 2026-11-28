// The XP programs of panel P-2026-11-28.28…32 as the app keeps them (R-DK-24…28): the app is the computer, the
// device draws these views.

/// Trình quản lý tác vụ (R-DK-24): the tab and the selected row of Ứng dụng (−1 none).
class TaskMgrView {
  const TaskMgrView({this.tab = 0, this.sel = -1});

  static const fresh = TaskMgrView();

  /// 0 Ứng dụng, 1 Hiệu năng, 2 Mạng.
  final int tab;
  final int sel;

  TaskMgrView copyWith({int? tab, int? sel}) => TaskMgrView(tab: tab ?? this.tab, sel: sel ?? this.sel);

  Map<String, Object?> toJson() => {'tab': tab, 'sel': sel};

  @override
  bool operator ==(Object other) => other is TaskMgrView && other.tab == tab && other.sel == sel;

  @override
  int get hashCode => Object.hash(tab, sel);
}

/// Thuộc tính màn hình (R-DK-26): the tab, the values being edited, the saved ones they started from, the mode list.
class DisplayProps {
  const DisplayProps({
    this.tab = 0,
    required this.saved,
    required this.pending,
    this.list = false,
    this.photoWallpaper = false,
  });

  /// 0 Màn nền, 1 Bảo vệ màn hình, 2 Cài đặt.
  final int tab;
  final DisplayValues saved, pending;

  /// Bảo vệ màn hình: the mode list is open.
  final bool list;

  /// A wallpaper photo is on the device: the third row "Ảnh của bạn".
  final bool photoWallpaper;

  /// Áp dụng can be pressed.
  bool get dirty => pending != saved;

  DisplayProps copyWith({int? tab, DisplayValues? saved, DisplayValues? pending, bool? list}) => DisplayProps(
        tab: tab ?? this.tab,
        saved: saved ?? this.saved,
        pending: pending ?? this.pending,
        list: list ?? this.list,
        photoWallpaper: photoWallpaper,
      );
}

/// The five settings Thuộc tính màn hình edits.
class DisplayValues {
  const DisplayValues({
    required this.wallpaper,
    required this.saver,
    required this.brightness,
    required this.invert,
    required this.idleDim,
  });

  /// `wallpaperMode`: 0 (Không), 1 Đồi xanh, 2 Ảnh của bạn.
  final int wallpaper;

  /// `nightMode` 0–3.
  final int saver;

  /// `brightness` 5–100.
  final int brightness;
  final bool invert, idleDim;

  DisplayValues copyWith({int? wallpaper, int? saver, int? brightness, bool? invert, bool? idleDim}) => DisplayValues(
        wallpaper: wallpaper ?? this.wallpaper,
        saver: saver ?? this.saver,
        brightness: brightness ?? this.brightness,
        invert: invert ?? this.invert,
        idleDim: idleDim ?? this.idleDim,
      );

  /// `POST /api/settings` keys.
  Map<String, Object?> toSettings() => {
        'wallpaperMode': wallpaper,
        'nightMode': saver,
        'brightness': brightness,
        'invertDisplay': invert,
        'idleDim': idleDim,
      };

  @override
  bool operator ==(Object other) =>
      other is DisplayValues &&
      other.wallpaper == wallpaper &&
      other.saver == saver &&
      other.brightness == brightness &&
      other.invert == invert &&
      other.idleDim == idleDim;

  @override
  int get hashCode => Object.hash(wallpaper, saver, brightness, invert, idleDim);
}

/// Explorer's places (R-DK-28).
enum ExplorerPlace { computer, photos, trash }

/// Explorer (R-DK-28): the place, the selected item (−1 none), the first thumbnail row shown, the confirm box.
class ExplorerView {
  const ExplorerView({this.place = ExplorerPlace.computer, this.sel = -1, this.top = 0, this.confirmEmpty = false});

  final ExplorerPlace place;
  final int sel;
  final int top;

  /// "Dọn sạch Thùng rác?" is up.
  final bool confirmEmpty;

  ExplorerView copyWith({ExplorerPlace? place, int? sel, int? top, bool? confirmEmpty}) => ExplorerView(
        place: place ?? this.place,
        sel: sel ?? this.sel,
        top: top ?? this.top,
        confirmEmpty: confirmEmpty ?? this.confirmEmpty,
      );

  @override
  bool operator ==(Object other) =>
      other is ExplorerView &&
      other.place == place &&
      other.sel == sel &&
      other.top == top &&
      other.confirmEmpty == confirmEmpty;

  @override
  int get hashCode => Object.hash(place, sel, top, confirmEmpty);
}
