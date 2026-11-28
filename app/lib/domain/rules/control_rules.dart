// Pure rules of the app remote (tab Điều khiển, design 2026-11-26.5; R-DK-*). Channel names and order follow the
// firmware's `kChannels[]` (src/main.cpp).
import '../models/attention_card.dart';
import '../models/control.dart';
import '../models/device_state.dart';
import '../models/touch.dart';
import 'skill_rules.dart';

/// Every channel of the firmware, in its rotation order (`kChannels[]`).
const deviceChannels = [
  'Attention',
  'Night',
  'Setup',
  'Home',
  'Agents',
  'Claude',
  'Codex',
  'AI',
  'Trend', //
  'Photo', 'Weather', 'Forecast', 'Clock', 'Info', 'Mines',
];

/// Channels that belong to no skill (shown whatever skills are on).
const systemChannels = {'Attention', 'Night', 'Info'};

/// Skill a channel belongs to (dock tab lit on the remote); null = system channel.
String? channelSkill(String channel) => switch (channel) {
  'Photo' => SkillIds.photo,
  'Weather' || 'Forecast' => SkillIds.weather,
  'Clock' => SkillIds.clock,
  'Mines' || 'Calc' => SkillIds.fun,
  'Attention' || 'Night' || 'Info' || 'TaskMgr' || 'Display' || 'Explorer' => null,
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
    case SkillIds.fun:
      return const ['Mines'];
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

/// R-DK-3: commands this firmware has, from the fields `/api/state` reports.
/// Touches (R-DK-10) come with the firmware of the app remote, which reports `paused`.
ControlCaps controlCaps(DeviceState? s) => s == null
    ? ControlCaps.all
    : ControlCaps(
        touch: s.paused != null,
        dismissCard: s.paused != null,
        screen: s.screenOn != null,
        windows: s.windowsApi,
        clock: s.clockApi,
        balloon: s.balloon != null,
        mouse: s.cursorPort != null,
        mines: s.minesApi,
      );

/// The agent card holding the device screen (approval / input on the Attention channel), or null.
AttentionCard? holdingCard(DeviceState? s, List<AttentionCard> cards) {
  if (s == null || s.activeChannel != 'Attention') return null;
  for (final c in cards) {
    if (c.showsInS <= 0 && (c.kind == 'approval' || c.kind == 'input')) return c;
  }
  return null;
}

/// Programs (windows) of the device: the channels that are neither the desktop nor a system screen.
const programChannels = {
  'Claude', 'Codex', 'AI', 'Trend', 'Agents', 'Photo', 'Weather', 'Forecast', 'Clock', 'Info', 'Mines', //
  'TaskMgr', 'Display', 'Calc', 'Explorer', // R-DK-24…29 (panel P-2026-11-28.28…32)
};

bool isProgram(String channel) => programChannels.contains(channel);

/// R-DK-14: firmware of panel P-2026-11-26.17 (XP-Real windows), told by its settings carrying `weatherPlace`.
bool xpReal(Map<String, dynamic>? settings) => settings?.containsKey('weatherPlace') == true;

/// R-DK-14: the window (program) a [channel] belongs to: on XP-Real firmware Forecast is the "Dự báo" tab of the
/// Weather window (one window, one taskbar button); otherwise each program is its own window.
String windowOf(String channel, {required bool real}) => real && channel == 'Forecast' ? 'Weather' : channel;

/// R-DK-9: programs of the enabled [skillsOn], by group, in the sheet's order. Channels whose `show*` flag is off in
/// [settings] are left out (the device answers 404 for them); Info only when `showInfo` is on.
Map<ProgramGroup, List<String>> programsOf(List<String> skillsOn, Map<String, dynamic>? settings) {
  final on = skillsOn.isEmpty ? const [SkillIds.agent] : skillsOn;
  bool shown(String c) {
    final flag = _agentFlag[c] ?? _otherFlag[c];
    return flag == null || settings == null || settings[flag] != false;
  }

  return {
    ProgramGroup.agent: [
      if (on.contains(SkillIds.agent))
        for (final c in const ['Claude', 'Codex', 'AI', 'Trend', 'Agents'])
          if (shown(c)) c,
    ],
    ProgramGroup.other: [
      for (final c in const ['Weather', 'Forecast', 'Clock', 'Photo', 'Mines'])
        // R-DK-14: XP-Real firmware — Dự báo is a tab of Thời tiết, not a program of its own.
        if (on.contains(channelSkill(c)) && shown(c) && !(c == 'Forecast' && xpReal(settings))) c,
    ],
    ProgramGroup.system: [if (settings?['showInfo'] == true) 'Info'],
  };
}

const _otherFlag = {'Weather': 'showWeather', 'Forecast': 'showForecast', 'Clock': 'showClock'};

/// R-DK-24…29: XP windows outside [programsOf] (no Start row / desktop icon) that stay in the window list —
/// Trình quản lý tác vụ, Thuộc tính màn hình, Explorer (system); Máy tính bỏ túi while Giải trí is on.
bool keepsWindow(String program, List<String> skillsOn) =>
    const {'TaskMgr', 'Display', 'Explorer'}.contains(program) ||
    (program == 'Calc' && skillsOn.contains(SkillIds.fun));

/// Every program of [programsOf], flat.
Set<String> programSet(List<String> skillsOn, Map<String, dynamic>? settings) => {
  for (final l in programsOf(skillsOn, settings).values) ...l,
};

/// R-DK-9: the desktop icon a newly installed skill shows selected (its first program).
String? deskProgramOf(String skill) => switch (skill) {
  SkillIds.agent => 'Claude',
  SkillIds.photo => 'Photo',
  SkillIds.weather => 'Weather',
  SkillIds.clock => 'Clock',
  SkillIds.fun => 'Mines',
  _ => null,
};

/// R-DK-7: the device's `autoRotate` must be off (the device shows what the user opened, never rotates).
bool rotationOn(Map<String, dynamic>? settings) => settings?['autoRotate'] == true;
