import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';
import 'desk_wallpaper.dart';

/// Home — the XP desktop (`ch_home.cpp`, XP-Desktop): wallpaper 240×214, no window; icon column centred on x 40
/// (Clawd, command window, photo, trash ×2, cells 48 tall from y 8) with white labels + black shadow
/// ("Claude 38%", "Codex", "Ảnh", "Thùng rác"); the weather balloon 136×50 at (100, 150) pointing at the tray clock.
///
/// The user's wallpaper JPEG (`/api/state.wallpaper`) cannot be read back from the device, so the mirror always
/// draws the fallback wallpaper.
class HomeChannel extends MirrorChannel {
  const HomeChannel();

  // Terminal 16×10, ">_" 6×3 and trash 14×10 (bit w−1−x = pixel x), as ch_home.cpp.
  static const _term = [0xFFFF, 0x8001, 0xFFFF, 0x8001, 0xA001, 0x9001, 0xA701, 0x8001, 0x8001, 0xFFFF];
  static const _prompt = [0x20, 0x10, 0x27];
  static const _trash = [0x07F8, 0x0FFC, 0x1FFE, 0x0AA8, 0x0AA8, 0x0AA8, 0x0AA8, 0x0AA8, 0x0AA8, 0x07FC];

  static const _colX = 40, _labelMax = 80.0;
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

  void _icons(XpCanvas c) {
    Xp.clawd(c, 22, 9, scale: 2);
    c.bits(_rows(_term, 16), 24, 56, XpColors.white, scale: 2);
    c.fill(26, 62, 28, 12, XpColors.black);
    c.bits(_rows(_prompt, 6), 28, 64, XpColors.bar, scale: 2);
    Xp.drawIcon(c, XpIcon.photo, 24, 104, XpColors.white, scale: 2);
    c.bits(_rows(_trash, 14), 26, 152, XpColors.deskDDE6EE, scale: 2);
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
    _icons(c);
    final labels = [
      d.claudePct == null ? 'Claude' : 'Claude ${d.claudePct}%',
      d.codexPct == null ? 'Codex' : 'Codex ${d.codexPct}%',
      l.devXpTitlePhoto,
      l.devXpDeskTrash,
    ];
    for (var i = 0; i < labels.length; i++) {
      final y = 8 + 48 * i + 24;
      c.text(
        labels[i],
        _colX,
        y,
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
