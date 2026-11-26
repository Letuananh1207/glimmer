// Pure rules of the app remote (tab Điều khiển, design 2026-11-26.5; R-DK-*). Channel names and order follow the
// firmware's `kChannels[]` (src/main.cpp).
import '../models/attention_card.dart';
import '../models/control.dart';
import '../models/device_state.dart';
import 'skill_rules.dart';

/// Every channel of the firmware, in its rotation order (`kChannels[]`).
const deviceChannels = [
  'Attention', 'Night', 'Setup', 'Home', 'Agents', 'Claude', 'Codex', 'AI', 'Trend', //
  'Photo', 'Weather', 'Forecast', 'Clock', 'Info',
];

/// Channels that belong to no skill (shown whatever skills are on).
const systemChannels = {'Attention', 'Night', 'Info'};

/// Skill a channel belongs to (dock tab lit on the remote); null = system channel.
String? channelSkill(String channel) => switch (channel) {
  'Photo' => SkillIds.photo,
  'Weather' || 'Forecast' => SkillIds.weather,
  'Clock' => SkillIds.clock,
  'Attention' || 'Night' || 'Info' => null,
  _ => SkillIds.agent,
};

/// `/api/settings` flag that turns an agent channel on (`show*`).
const _agentFlag = {
  'Home': 'showHome',
  'Agents': 'showAgents',
  'Claude': 'showClaude',
  'Codex': 'showCodex',
  'AI': 'showAiDash',
  'Trend': 'showTrend',
};

/// Channels to ask for, in order, when the remote jumps to [skill]: the skill's first channel. Agent channels follow
/// their `show*` flags in [settings] (unknown settings → Claude first). A 404 answer means "not on" → try the next.
List<String> jumpCandidates(String skill, Map<String, dynamic>? settings) {
  switch (skill) {
    case SkillIds.photo:
      return const ['Photo'];
    case SkillIds.weather:
      return const ['Weather', 'Forecast'];
    case SkillIds.clock:
      return const ['Clock'];
  }
  const order = ['Claude', 'Codex', 'Home', 'Agents', 'AI', 'Trend'];
  if (settings == null) return order;
  final on = [
    for (final c in order)
      if (settings[_agentFlag[c]] == true) c,
  ];
  return [
    ...on,
    for (final c in order)
      if (!on.contains(c)) c,
  ];
}

/// Channels the device most likely rotates through (to show the next / previous one at once, R-DK-1): channels of
/// the enabled skills in firmware order (agent ones by their `show*` flag when [settings] are known) plus Info when on.
List<String> rotationGuess(DeviceState s, Map<String, dynamic>? settings) {
  final skills = s.skillsOn.isEmpty ? const [SkillIds.agent] : s.skillsOn;
  bool rotates(String c) {
    if (c == 'Info') return settings?['showInfo'] == true;
    if (systemChannels.contains(c) || c == 'Setup') return false;
    if (!skills.contains(channelSkill(c))) return false;
    final flag = _agentFlag[c];
    return flag == null || settings == null || settings[flag] == true;
  }

  return [
    for (final c in deviceChannels)
      if (rotates(c)) c,
  ];
}

/// The channel [step] places after [current] in [order] (−1 = previous); null when [current] is not in it.
String? stepChannel(List<String> order, String current, int step) {
  final i = order.indexOf(current);
  if (i < 0 || order.isEmpty) return null;
  return order[(i + step) % order.length];
}

/// R-DK-3: commands this firmware has, from the fields `/api/state` reports.
ControlCaps controlCaps(DeviceState? s) => s == null
    ? ControlCaps.all
    : ControlCaps(
        prev: s.paused != null,
        pause: s.paused != null,
        dismissCard: s.paused != null,
        screen: s.screenOn != null,
        slide: s.slideLeftMs != null,
      );

/// The agent card holding the device screen (approval / input on the Attention channel), or null.
AttentionCard? holdingCard(DeviceState? s, List<AttentionCard> cards) {
  if (s == null || s.activeChannel != 'Attention') return null;
  for (final c in cards) {
    if (c.showsInS <= 0 && (c.kind == 'approval' || c.kind == 'input')) return c;
  }
  return null;
}

/// Share 0…1 of the current slide already shown; [leftMs] = time left now, [slideMs] its length. 0 when unknown.
double slideProgress(int slideMs, int leftMs) {
  if (slideMs <= 0) return 0;
  final done = (slideMs - leftMs.clamp(0, slideMs)) / slideMs;
  return done.clamp(0.0, 1.0);
}

/// Whole seconds left, rounded up (the channel line "đổi kênh sau N s").
int secondsLeft(int leftMs) => leftMs <= 0 ? 0 : (leftMs + 999) ~/ 1000;
