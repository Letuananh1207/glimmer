// The app remote (tab Điều khiển, design 2026-11-26.5): commands, the device's answers, what the firmware supports.

/// A button of the remote. Names stay English (logs, tests); the UI turns them into words.
enum ControlCommand { prev, next, pause, resume, jump, screenOff, screenOn, dismissCard, brightness, night, refresh }

/// Answer of `POST /api/channel`: the channel the device shows now and whether rotation is held.
class ChannelAnswer {
  const ChannelAnswer(this.active, this.paused);

  factory ChannelAnswer.fromJson(Map<String, dynamic> j) => ChannelAnswer(
    j['active'] is String ? j['active'] as String : '',
    j['paused'] is bool ? j['paused'] as bool : null,
  );

  final String active;
  final bool? paused;
}

/// What a control command came back with (R-DK-1).
class ControlOutcome {
  const ControlOutcome({this.active, this.paused, this.screenOn, this.matched = true});

  /// Channel the device shows after the command (channel commands only).
  final String? active;
  final bool? paused;
  final bool? screenOn;

  /// The device did what the app expected; false → the app follows the device and tells the user.
  final bool matched;
}

/// Commands the connected firmware has (R-DK-3), known from the fields of `/api/state`.
class ControlCaps {
  const ControlCaps({
    this.prev = false,
    this.pause = false,
    this.screen = false,
    this.dismissCard = false,
    this.slide = false,
  });

  /// Everything (current firmware).
  static const all = ControlCaps(prev: true, pause: true, screen: true, dismissCard: true, slide: true);

  final bool prev, pause, screen, dismissCard;

  /// `slide_left_ms` is reported (channel line countdown).
  final bool slide;

  bool supports(ControlCommand c) => switch (c) {
    ControlCommand.prev => prev,
    ControlCommand.pause || ControlCommand.resume => pause,
    ControlCommand.screenOff || ControlCommand.screenOn => screen,
    ControlCommand.dismissCard => dismissCard,
    _ => true,
  };

  /// Buttons the remote has but this firmware lacks, in button order (old-firmware banner).
  List<ControlCommand> get missing => [
    if (!prev) ControlCommand.prev,
    if (!pause) ControlCommand.pause,
    if (!screen) ControlCommand.screenOff,
  ];
}
