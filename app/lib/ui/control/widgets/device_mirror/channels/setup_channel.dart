import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';

/// Setup — first-run checklist (`ch_setup.cpp`, XP-Setup): window "Cài đặt", head 12B (12, 30), "Còn N bước nữa
/// là xong." (12, 48), three XP checkboxes every 22 px from y 72, group box "Mở trong trình duyệt" (10, 150,
/// 220×40) with the underlined glimmer.local link (18, 159) and the IP right-aligned at 222.
class SetupChannel extends MirrorChannel {
  const SetupChannel();

  static const _host = 'glimmer.local';
  static const _tickY = [6, 7, 8, 7, 6, 5, 4];

  void _check(XpCanvas c, int y, bool done, String item) {
    const bx = 14;
    c.outline(bx, y, 13, 13, XpColors.checkBox);
    c.fill(bx + 1, y + 1, 11, 11, XpColors.white);
    if (done) {
      for (var i = 0; i < _tickY.length; i++) {
        c.fill(bx + 4 + i, y + _tickY[i], 1, 3, XpColors.check);
      }
    }
    c.text(item, 34, y, XpFont.jb11, done ? XpColors.muted : XpColors.black);
  }

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final s = f.agents.setup;
    Xp.window(c, l.devXpTitleSetup);
    c.text(l.devXpSetupHead, 12, 31, XpFont.jb12b, XpColors.black);
    c.text(l.devXpSetupLeft(s.left), 12, 48, XpFont.jb11, XpColors.label);
    _check(c, 72, s.claude, l.devXpSetupClaude);
    _check(c, 94, s.codex, l.devXpSetupCodex);
    _check(c, 116, s.weather, l.devXpSetupWeather);
    Xp.groupBox(c, 10, 150, 220, 40, l.devXpSetupOpen);
    c.text(_host, 18, 160, XpFont.jb12b, XpColors.link);
    c.hLine(18, 173, c.textWidth(_host, XpFont.jb12b).round(), XpColors.link);
    c.text(s.ip, 222, 176, XpFont.jb11, XpColors.muted, align: XpAlign.right);
  }
}
