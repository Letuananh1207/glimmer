import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';
import 'desk_wallpaper.dart';

/// Home — the XP desktop (`ch_home.cpp`, XP-Desktop, panel P-2026-11-26.14 XP-Desk): wallpaper 240×214, no window;
/// one icon ×2 per program of the enabled skills (`DesktopView.icons`: column x 40 then x 120, cells 48 tall from
/// y 8) with white labels + black shadow ("Claude 38%", "Codex", "Ảnh", "Thùng rác", "Thời tiết", "Đồng hồ"); the
/// weather balloon 136×50 at (100, 150) pointing at the tray clock (weather skill on, a location set).
///
/// The user's wallpaper JPEG (`/api/state.wallpaper`) cannot be read back from the device, so the mirror always
/// draws the fallback wallpaper.
class HomeChannel extends MirrorChannel {
  const HomeChannel();

  // Terminal 16×10, ">_" 6×3 and trash 14×10 (bit w−1−x = pixel x), as ch_home.cpp.
  static const _term = [0xFFFF, 0x8001, 0xFFFF, 0x8001, 0xA001, 0x9001, 0xA701, 0x8001, 0x8001, 0xFFFF];
  static const _prompt = [0x20, 0x10, 0x27];
  static const _trash = [0x07F8, 0x0FFC, 0x1FFE, 0x0AA8, 0x0AA8, 0x0AA8, 0x0AA8, 0x0AA8, 0x0AA8, 0x07FC];

  static const _labelMax = 80.0;
  static const _balX = 100, _balY = 150, _balW = 136, _balH = 50, _tailX = 206, _tailY = 199;
  static const _lineX = 106, _lineW = 128.0;

  static List<String> _rows(List<int> words, int w) => [
    for (final r in words) [for (var x = 0; x < w; x++) (r >> (w - 1 - x)) & 1 == 1 ? '#' : '.'].join(),
  ];

  static void wallpaper(XpCanvas c) {
    const s = DeskWallpaper.runs;
    var x = 0, y = 0;
    for (var i = 0; i + 4 <= s.length; i += 4) {
      final idx = int.parse(s.substring(i, i + 2), radix: 16);
      final len = int.parse(s.substring(i + 2, i + 4), radix: 16);
      c.fill(x, y, len, 1, DeskWallpaper.palette[idx]);
      x += len;
      if (x >= DeskWallpaper.width) {
        x = 0;
        y++;
      }
    }
  }

  /// Icon of [program] (null = trash) ×2 in the cell at ([cx], [y]).
  void _icon(XpCanvas c, String? program, int cx, int y, {bool sel = false}) {
    final white = sel ? XpColors.selectIcon : XpColors.white;
    switch (program) {
      case 'Claude':
        Xp.clawd(c, cx - 18, y + 1, scale: 2, color: sel ? XpColors.selectClawd : PanelColors.clawd);
      case 'Codex':
        c.bits(_rows(_term, 16), cx - 16, y, white, scale: 2);
        c.fill(cx - 14, y + 6, 28, 12, XpColors.black);
        c.bits(_rows(_prompt, 6), cx - 12, y + 8, XpColors.bar, scale: 2);
      case 'Photo':
        Xp.drawIcon(c, XpIcon.photo, cx - 16, y, white, scale: 2);
      case 'Weather':
        Xp.drawIcon(c, XpIcon.weather, cx - 16, y - 6, white, scale: 2);
      case 'Clock':
        Xp.drawIcon(c, XpIcon.clock, cx - 16, y - 6, white, scale: 2);
      default:
        c.bits(_rows(_trash, 14), cx - 14, y, sel ? XpColors.selectIcon : XpColors.deskDDE6EE, scale: 2);
    }
  }

  /// XP selection: white text on xpSelect (+1 px each side, 13 tall), no shadow, dotted white border around it.
  void _selectedLabel(XpCanvas c, String label, int cx, int y) {
    final tw = c.textWidth(label, XpFont.jb11).round();
    final bx = cx - tw ~/ 2 - 1, bw = tw + 2;
    const bh = 13;
    c.fill(bx, y, bw, bh, XpColors.select);
    for (var k = 0; k < bw + 2; k += 2) {
      c.pixel(bx - 1 + k, y - 1, XpColors.white);
      c.pixel(bx - 1 + k, y + bh, XpColors.white);
    }
    for (var k = 0; k < bh + 2; k += 2) {
      c.pixel(bx - 1, y - 1 + k, XpColors.white);
      c.pixel(bx + bw, y - 1 + k, XpColors.white);
    }
    c.text(label, cx, y, XpFont.jb11, XpColors.white, align: XpAlign.center, maxWidth: _labelMax);
  }

  void _balloon(XpCanvas c, DesktopView d, AppLocalizations l) {
    c.fill(_balX, _balY, _balW, _balH, XpColors.black);
    c.fill(_balX + 1, _balY + 1, _balW - 2, _balH - 2, XpColors.infoBar);
    for (var k = 0; k < 7; k++) {
      final w = 8 - k;
      c.hLine(_tailX, _tailY + k, w, XpColors.infoBar);
      c.pixel(_tailX, _tailY + k, XpColors.black);
      c.pixel(_tailX + w - 1, _tailY + k, XpColors.black);
    }
    Xp.drawIcon(c, XpIcon.weather, 106, 155, XpColors.amber);
    c.text(l.devXpTitleWeather, 126, 156, XpFont.jb12b, XpColors.black);
    final t = d.temp;
    if (t == null) {
      c.text(l.devXpDeskNoWeather, _lineX, 172, XpFont.jb11, XpColors.dim, maxWidth: _lineW);
      return;
    }
    c.text(l.devXpDeskNow(t, d.desc), _lineX, 172, XpFont.jb11, XpColors.black, maxWidth: _lineW);
    final fl = d.feels;
    if (fl != null) c.text(l.devXpDeskFeels(fl), _lineX, 185, XpFont.jb11, XpColors.label, maxWidth: _lineW);
  }

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final d = f.agents.desktop;
    wallpaper(c);
    for (final ic in d.icons) {
      final sel = ic.program != null && ic.program == f.windows.sel;
      _icon(c, ic.program, ic.cx, ic.y, sel: sel);
      final label = switch (ic.program) {
        'Claude' => d.claudePct == null ? 'Claude' : 'Claude ${d.claudePct}%',
        'Codex' => d.codexPct == null ? 'Codex' : 'Codex ${d.codexPct}%',
        'Photo' => l.devXpTitlePhoto,
        'Weather' => l.devXpTitleWeather,
        'Clock' => l.devXpTitleClock,
        _ => l.devXpDeskTrash,
      };
      if (sel) {
        _selectedLabel(c, label, ic.cx, ic.y + 24);
        continue;
      }
      c.text(
        label,
        ic.cx,
        ic.y + 24,
        XpFont.jb11,
        XpColors.white,
        align: XpAlign.center,
        maxWidth: _labelMax,
        shadow: XpColors.black,
      );
    }
    if (d.balloon) _balloon(c, d, l);
  }
}
