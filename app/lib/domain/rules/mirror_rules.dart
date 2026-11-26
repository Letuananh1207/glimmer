import '../models/attention_card.dart';
import '../models/device_photo.dart';
import '../models/device_state.dart';
import '../models/mirror_frame.dart';
import '../models/touch.dart';
import '../models/windows.dart';
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
  WindowStack windows = WindowStack.empty,
  MenuView? menu,
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
    taskbar: taskbarOf(state, shown, cards, windows),
    screenOff: state.screenOn == false,
    ambient: ambientOf(state, settings, epoch, epoch > 0 ? deviceLocal(epoch, tz) : DateTime.utc(1970)),
    usage: usageMirrorOf(state, settings),
    agents: agentsMirrorOf(state, cards, settings, gallery: gallery),
    windows: windows,
    menu: menu,
  );
}

/// Taskbar while [channel] shows (design 2026-11-26.7): the open [windows] in opening order (the last
/// [TaskbarModel.max]), the top one pressed when it is on screen; the Claude button carries the badge and lights orange
/// on a card that needs the user.
TaskbarModel taskbarOf(DeviceState state, String channel, List<AttentionCard> cards, WindowStack windows) {
  final open = windows.open;
  final programs = open.length > TaskbarModel.max ? open.sublist(open.length - TaskbarModel.max) : open;
  final buttons = [
    for (final p in programs)
      switch (channelSkill(p)) {
        _ when p == 'Info' => TaskButton.info,
        SkillIds.photo => TaskButton.photo,
        SkillIds.weather => TaskButton.weather,
        SkillIds.clock => TaskButton.clock,
        _ => TaskButton.claude,
      },
  ];
  final top = windows.top;
  final i = top != null && top == channel ? programs.indexOf(top) : -1;
  final flash =
      channel == 'Attention' &&
      cards.any((c) => c.showsInS <= 0 && (c.kind == 'approval' || c.kind == 'input' || c.kind == 'error'));
  return TaskbarModel(
    programs: programs,
    buttons: buttons,
    active: i < 0 ? null : i,
    flash: flash,
    badge: agentsWaiting(cards),
  );
}
