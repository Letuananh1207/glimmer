import '../models/attention_card.dart';
import '../models/device_photo.dart';
import '../models/device_state.dart';
import '../models/mirror_frame.dart';
import 'ambient_rules.dart';
import 'board_rules.dart';
import 'control_rules.dart';
import 'mirror_agent_rules.dart';
import 'skill_rules.dart';
import 'time_rules.dart';
import 'usage_mirror_rules.dart';

/// Builds the frame of [state] showing [channel] (default: the device's), [now] = phone time.
MirrorFrame mirrorFrameOf(
  DeviceState state, {
  String? channel,
  List<AttentionCard> cards = const [],
  Map<String, dynamic>? settings,
  required DateTime now,
  double slideProgress = 0,
  PhotoGallery? gallery,
}) {
  final shown = state.inSetupMode ? MirrorFrame.setupScreen : (channel ?? state.activeChannel);
  final tz = (settings?['tzMinutes'] as num?)?.toInt() ?? 0;
  final epoch = state.clockSynced ? state.time : 0;
  return MirrorFrame(
    channel: shown,
    state: state,
    cards: cards,
    settings: settings,
    deviceNow: epoch > 0 ? deviceLocal(epoch, tz) : DateTime(1970),
    h24: settings?['clock24h'] != false,
    taskbar: taskbarOf(state, shown, cards, slideProgress),
    screenOff: state.screenOn == false,
    ambient: ambientOf(state, settings, epoch, epoch > 0 ? deviceLocal(epoch, tz) : DateTime.utc(1970)),
    usage: usageMirrorOf(state, settings),
    agents: agentsMirrorOf(state, cards, settings, gallery: gallery),
  );
}

/// Taskbar of [state] while [channel] shows (firmware `barState`).
TaskbarModel taskbarOf(DeviceState state, String channel, List<AttentionCard> cards, double slideProgress) {
  final on = state.skillsOn.isEmpty ? const [SkillIds.agent] : state.skillsOn;
  final buttons = [
    if (on.contains(SkillIds.agent)) TaskButton.claude,
    if (on.contains(SkillIds.photo)) TaskButton.photo,
    if (on.contains(SkillIds.weather)) TaskButton.weather,
    if (on.contains(SkillIds.clock)) TaskButton.clock,
  ];
  final active = switch (channelSkill(channel)) {
    _ when channel == 'Info' || channel == 'Home' || channel == 'Night' => null,
    SkillIds.photo => TaskButton.photo,
    SkillIds.weather => TaskButton.weather,
    SkillIds.clock => TaskButton.clock,
    _ => TaskButton.claude,
  };
  final flash =
      channel == 'Attention' &&
      cards.any((c) => c.showsInS <= 0 && (c.kind == 'approval' || c.kind == 'input' || c.kind == 'error'));
  final accent = channel == 'Codex'
      ? TaskAccent.lilac
      : switch (active) {
          TaskButton.photo => TaskAccent.mint,
          TaskButton.weather => TaskAccent.sky,
          TaskButton.clock => TaskAccent.amber,
          _ => TaskAccent.coral,
        };
  return TaskbarModel(
    buttons: buttons,
    active: active,
    flash: flash,
    badge: agentsWaiting(cards),
    progress: flash ? 0 : slideProgress,
    accent: accent,
  );
}
