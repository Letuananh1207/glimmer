import '../../../../l10n/app_localizations.dart';
import '../../../core/themes/xp_colors.dart';
import '../../../../domain/models/mirror_frame.dart';
import 'channels/agents_channel.dart';
import 'channels/ai_channel.dart';
import 'channels/attention_channel.dart';
import 'channels/claude_channel.dart';
import 'channels/codex_channel.dart';
import 'channels/clock_channel.dart';
import 'channels/forecast_channel.dart';
import 'channels/home_channel.dart';
import 'channels/info_channel.dart';
import 'channels/photo_channel.dart';
import 'channels/setup_channel.dart';
import 'channels/system_channels.dart';
import 'channels/trend_channel.dart';
import 'channels/weather_channel.dart';
import 'xp_canvas.dart';
import 'xp_paint.dart';

/// One device channel drawn in the `DeviceMirror` — the app's copy of `src/channels/ch_<name>.cpp`, pixel for pixel
/// as `design/panel/source/XP-<Name>*.dc.html`.
///
/// [paint] draws the 240 × 240 device screen **except the taskbar** at device pixels on [c] (y 0…213, or the whole
/// screen when [hasTaskbar] is false), from [frame] (state, cards, settings, device clock). Words shown on the device
/// come from [l] (`devXp…` strings). The mirror repaints when the frame changes and once a second.
abstract class MirrorChannel {
  const MirrorChannel();

  /// Night face and full-screen system screens draw no taskbar.
  bool get hasTaskbar => true;

  void paint(XpCanvas c, MirrorFrame frame, AppLocalizations l);
}

/// Stand-in until a channel's painter is written (part 2): its XP window with the device's title and icon.
class PlaceholderChannel extends MirrorChannel {
  const PlaceholderChannel(this.title, this.icon, {this.statusBar = false});

  final String Function(AppLocalizations l, MirrorFrame f) title;
  final XpIcon icon;
  final bool statusBar;

  @override
  void paint(XpCanvas c, MirrorFrame frame, AppLocalizations l) =>
      Xp.window(c, title(l, frame), icon: icon, statusBar: statusBar);
}

/// Night face (`ch_night.cpp`, XP-Night): black, no window, no taskbar; VT323-86 "HH:MM" centred at y 65 and the
/// date "Thứ Tư 25/11" (+ SA / CH in 12-hour mode) JBMono-11 at y 150, both #4D4D4D.
class NightChannel extends MirrorChannel {
  const NightChannel();

  @override
  bool get hasTaskbar => false;

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    c.fill(0, 0, 240, 240, XpColors.black);
    final t = f.deviceNow;
    final synced = f.clockSynced;
    // `ClockFmt::hourField`: "07" (24 h) or " 7" (12 h, space-padded so the digits keep their place).
    final hour = f.h24 ? t.hour.toString().padLeft(2, '0') : '${t.hour % 12 == 0 ? 12 : t.hour % 12}'.padLeft(2);
    final time = synced ? '$hour:${t.minute.toString().padLeft(2, '0')}' : '--:--';
    // Panel P-2026-11-26.17 XP-Night-Saver: the 170×100 block at (14, 22) — the device moves it every minute to a
    // spot the app cannot know, so the mirror keeps the first one. VT323-86 sits in a 70-px line box here, 86 on the
    // design page: +8.
    const bx = 14, by = 22;
    c.text(time, bx, by + 8, XpFont.vt86, XpColors.label);
    if (!synced) return;
    var date = '${l.devXpWeekday('${t.weekday}')} ${t.day}/${t.month}';
    if (!f.h24) date += ' ${t.hour >= 12 ? l.devClockPm : l.devClockAm}';
    c.text(date, bx + 85, by + 86, XpFont.jb11, XpColors.label, align: XpAlign.center);
  }
}

/// Painter of every firmware channel (`kChannels[]` names). Part 2 replaces each [PlaceholderChannel] with the real
/// painter; an unknown name falls back to [fallbackChannel].
final Map<String, MirrorChannel> mirrorChannels = {
  'Attention': const AttentionChannel(),
  'Night': const NightChannel(),
  'Setup': const SetupChannel(),
  'Home': const HomeChannel(),
  'Agents': const AgentsChannel(),
  'Claude': const ClaudeChannel(),
  'Codex': const CodexChannel(),
  'AI': const AiChannel(),
  'Trend': const TrendChannel(),
  'Photo': const PhotoChannel(),
  'Weather': const WeatherChannel(),
  'Forecast': const ForecastChannel(),
  'Clock': const ClockChannel(),
  'Info': const InfoChannel(),
  // System screens (not channels): the device in its setup AP shows the log-on screen.
  MirrorFrame.setupScreen: const SetupModeScreen(),
  MirrorFrame.connectingScreen: const ConnectingScreen(),
  MirrorFrame.otaScreen: const OtaScreen(),
  MirrorFrame.noChannels: const NoChannelsChannel(),
};

/// Channel name the firmware has but the app does not know yet: a bare window titled with the name.
MirrorChannel fallbackChannel(String name) => PlaceholderChannel((_, _) => name, XpIcon.clawd);
