// One picture of the device screen for the app's DeviceMirror (tab Điều khiển, design 2026-11-26.5). Built by
// `mirrorFrameOf` (domain/rules/mirror_rules.dart); painted by ui/control/widgets/device_mirror/.
import 'attention_card.dart';
import 'device_state.dart';
import 'mirror_agents.dart';
import 'mirror_ambient.dart';
import 'touch.dart';
import 'usage_mirror.dart';
import 'windows.dart';

export 'mirror_agents.dart';
export 'mirror_ambient.dart';

/// Icon of a taskbar button (`XPCore::Btn`): the skill of its window (agent windows = Clawd, Info = the info icon).
enum TaskButton { claude, photo, weather, clock, info }

/// What the taskbar shows (design 2026-11-26.7, panel P-2026-11-26.14): one button per open window, in opening order,
/// at most [max]; the top window's button pressed; no slide progress.
class TaskbarModel {
  const TaskbarModel({
    this.programs = const [],
    this.buttons = const [],
    this.active,
    this.flash = false,
    this.badge = 0,
  });

  static const max = 4;

  /// The window of each button (program / channel name), in opening order.
  final List<String> programs;

  /// Icon of each button, parallel to [programs].
  final List<TaskButton> buttons;

  /// Index of the pressed button (the top window, when it shows); null = none (desktop, cards, Info…).
  final int? active;

  /// Claude button lit orange: a card that needs the user holds the screen.
  final bool flash;

  /// Agents waiting (badge on the Claude button, 0 = none, > 9 shows '+').
  final int badge;
}

/// One picture of the device screen, from `/api/state` (R-DK-6) — everything a [MirrorChannel] painter reads.
/// Built by `mirrorFrameOf` from `ControlViewModel` (optimistic [channel] while a command is on its way, R-DK-1).
class MirrorFrame {
  const MirrorFrame({
    required this.channel,
    required this.state,
    this.cards = const [],
    this.settings,
    required this.deviceNow,
    this.h24 = true,
    this.taskbar = const TaskbarModel(),
    this.screenOff = false,
    this.ambient = const MirrorAmbient(),
    this.usage = const UsageMirror(),
    this.agents = const AgentsMirror(),
    this.windows = WindowStack.empty,
    this.menu,
  });

  /// Pseudo channel of the setup-AP "log-on" screen (`XP-SetupMode`).
  static const setupScreen = 'SetupMode';

  /// Pseudo channels of the welcome ("connecting", `XP-Connecting`) and "đang cập nhật..." (`XP-OtaProgress`)
  /// screens. `/api/state` cannot report them (the device does not answer while on them), so no frame is built
  /// with them yet; the painters exist for when the app flashes or reconnects the device.
  static const connectingScreen = 'Connecting', otaScreen = 'OtaProgress';

  /// `active_channel` when no channel is on (`XP-NoChannels`).
  static const noChannels = 'none';

  /// Channel on the device screen (`active_channel`, or the optimistic one; [setupScreen] in the setup AP).
  final String channel;
  final DeviceState state;

  /// Attention queue (`GET /push`).
  final List<AttentionCard> cards;

  /// `/api/settings` (null until loaded): `clock24h`, `tzMinutes`, `useFahrenheit`, `userName`, `show*`…
  final Map<String, dynamic>? settings;

  /// Device-local wall clock at the last state read; year 1970 = clock not set (shows "--:--").
  final DateTime deviceNow;
  final bool h24;
  final TaskbarModel taskbar;

  /// Backlight off (`screen_on: false`): the mirror shows the dark "screen off" plate.
  final bool screenOff;

  /// Weather / Forecast / Clock / Info values (`ambientOf`).
  final MirrorAmbient ambient;

  /// Claude / Codex / AI hôm nay / Xu hướng windows (`usageMirrorOf`).
  final UsageMirror usage;

  /// Attention / Agents / Home / Setup / Photo values (`agentsMirrorOf`).
  final AgentsMirror agents;

  /// The app's open windows (taskbar, the selected desktop icon `sel`), design 2026-11-26.7.
  final WindowStack windows;

  /// The context menu over the screen (R-DK-11), or null.
  final MenuView? menu;

  bool get clockSynced => deviceNow.year > 2000;

  /// The night face (no window, no taskbar).
  bool get night => channel == 'Night';

  /// Tray clock "14:32" / "2:32CH" / "--:--".
  String get trayClock {
    if (!clockSynced) return '--:--';
    final m = deviceNow.minute.toString().padLeft(2, '0');
    if (h24) return '${deviceNow.hour.toString().padLeft(2, '0')}:$m';
    final h = deviceNow.hour % 12 == 0 ? 12 : deviceNow.hour % 12;
    return '$h:$m${deviceNow.hour >= 12 ? 'CH' : 'SA'}';
  }
}
