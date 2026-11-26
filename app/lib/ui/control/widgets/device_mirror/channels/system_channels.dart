import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';
import 'system_bits.dart';

/// Name of the device's setup network (firmware `SETUP_AP_SSID`) and its mDNS address (`MDNS_HOSTNAME`.local).
const _setupAp = 'glimmer-setup';
const _mdns = 'glimmer.local';

/// Welcome background (`welcomeChrome`, XP-Connecting / -SetupMode / -OtaProgress): xpWelcome, dark bands
/// y 0–29 and 207–239, light line y 30, orange edge y 205–206 fading to the sides.
void _welcomeChrome(XpCanvas c) {
  c.fill(0, 31, 240, 174, XpColors.welcome);
  c.fill(0, 0, 240, 30, XpColors.welcomeBand);
  c.hLine(0, 30, 240, XpColors.welcomeLine);
  c.fill(0, 207, 240, 33, XpColors.welcomeBand);
  const edge = [
    (0, 40, XpColors.bandEdge),
    (40, 40, XpColors.bandEdgeWarm),
    (80, 80, XpColors.welcomeOrange),
    (160, 40, XpColors.bandEdgeWarm),
    (200, 40, XpColors.bandEdge),
  ];
  for (final (x, w, col) in edge) {
    c.fill(x, 205, w, 2, col);
  }
}

/// Italic word with its shadow (+1, +1).
void _italic(XpCanvas c, List<int> bits, int w, int h, int x, int y) {
  SystemBits.draw(c, bits, w, h, x + 1, y + 1, XpColors.welcomeShadow);
  SystemBits.draw(c, bits, w, h, x, y, XpColors.white);
}

/// Full-screen system screen: no window, no taskbar.
abstract class _SystemScreen extends MirrorChannel {
  const _SystemScreen();

  @override
  bool get hasTaskbar => false;
}

/// Log-on screen of the setup AP (`Display::drawSetupMode`, XP-SetupMode): flag ×2 + italic "Window" + "xp" +
/// "Để bắt đầu, / kết nối Wi-Fi" on the left, divider x 116, the selected "user" tile (Clawd picture,
/// "glimmer-" / "setup", the AP address) on the right, red power button + "Cài đặt Wi-Fi" bottom left.
class SetupModeScreen extends _SystemScreen {
  const SetupModeScreen();

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    _welcomeChrome(c);
    Xp.flag(c, 70, 74, scale: 2);
    _italic(c, SystemBits.window, 63, 12, 12, 102);
    c.text('xp', 81, 103, XpFont.jb11, XpColors.welcomeOrange);
    c.text(l.devXpSetupLine1, 14, 126, XpFont.jb11, XpColors.white);
    c.text(l.devXpSetupLine2, 14, 140, XpFont.jb11, XpColors.white);
    c.vLine(116, 40, 30, XpColors.dividerFade);
    c.vLine(116, 70, 100, XpColors.divider);
    c.vLine(116, 170, 30, XpColors.dividerFade);
    c.fill(124, 86, 112, 50, XpColors.userSel);
    c.hLine(124, 86, 112, XpColors.userSelHi);
    c.fill(130, 92, 24, 24, XpColors.white);
    c.fill(132, 94, 20, 20, XpColors.userPic);
    Xp.clawd(c, 133, 99);
    // Like a long XP user name, the AP name wraps after its dash: "glimmer-" / "setup".
    final dash = _setupAp.indexOf('-');
    c.text(_setupAp.substring(0, dash + 1), 158, 93, XpFont.jb12b, XpColors.white);
    c.text(_setupAp.substring(dash + 1), 158, 107, XpFont.jb12b, XpColors.white);
    final ip = f.state.ip.isEmpty ? '192.168.4.1' : f.state.ip;
    c.text(ip, 158, 121, XpFont.jb11, XpColors.welcomeSub);
    c.fill(8, 218, 14, 14, XpColors.white);
    c.fill(9, 219, 12, 12, XpColors.close);
    c.fill(14, 221, 2, 5, XpColors.white);
    c.fill(11, 223, 1, 5, XpColors.white);
    c.fill(18, 223, 1, 5, XpColors.white);
    c.fill(12, 228, 6, 1, XpColors.white);
    c.text(l.devXpSetupPower, 28, 219, XpFont.jb11, XpColors.white);
  }
}

/// Welcome while joining Wi-Fi (`Display::drawConnecting`, XP-Connecting): only the italic "welcome".
class ConnectingScreen extends _SystemScreen {
  const ConnectingScreen();

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    _welcomeChrome(c);
    _italic(c, SystemBits.welcome, 71, 12, 70, 106);
  }
}

/// Firmware being flashed (`Display::drawOtaProgress`, XP-OtaProgress): italic "đang cập nhật..." + one warning.
class OtaScreen extends _SystemScreen {
  const OtaScreen();

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    _welcomeChrome(c);
    _italic(c, SystemBits.updating, 158, 17, 20, 96);
    c.text(l.devXpOtaWarn, 120, 130, XpFont.jb11, XpColors.white, align: XpAlign.center);
  }
}

/// No channel on (`XP::drawNoChannels`, XP-NoChannels): window "glimmer" + info dialog with the web address; the
/// taskbar stays.
class NoChannelsChannel extends MirrorChannel {
  const NoChannelsChannel();

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    Xp.window(c, 'glimmer');
    Xp.dialog(c, XpDialog.info, l.devXpNoChannelsHead, [l.devXpNoChannelsLine], link: _mdns);
  }
}
