// The app remote (tab Điều khiển, design 2026-11-26.5 / .6): commands, the device's answers, what the firmware supports.

/// A command of the remote. Names stay English (logs, tests); the UI turns them into words.
/// [open] / [minimize] / [close] / [desktop] are touches on the device screen (R-DK-7/8), sent as `/api/channel {name}`.
enum ControlCommand { open, minimize, close, desktop, screenOff, screenOn, dismissCard, brightness, night, refresh }

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
  const ControlOutcome({this.active, this.screenOn, this.matched = true});

  /// Channel the device shows after the command (channel commands only).
  final String? active;
  final bool? screenOn;

  /// The device did what the app expected; false → the app follows the device and tells the user.
  final bool matched;
}

/// Commands the connected firmware has (R-DK-3), known from the fields of `/api/state`.
class ControlCaps {
  const ControlCaps({
    this.touch = false,
    this.screen = false,
    this.dismissCard = false,
    this.windows = false,
    this.balloon = false,
    this.clock = false,
    this.mouse = false,
    this.mines = false,
  });

  /// Everything (current firmware).
  static const all = ControlCaps(
    mines: true,
    mouse: true,
    clock: true,
    touch: true,
    screen: true,
    dismissCard: true,
    windows: true,
    balloon: true,
  );

  /// The device draws the app's open windows on its taskbar and context menus (R-DK-11).
  final bool windows;

  /// The Ngày và Giờ window takes touches (R-DK-16).
  final bool clock;

  /// The mouse pointer, menu hover and the power button (R-DK-17…21: `cursor` in `/api/state`).
  final bool mouse;

  /// The firmware draws Dò mìn (R-DK-23: `mines` in `/api/state`).
  final bool mines;

  /// The desktop's tray balloon comes and goes, the app shows / hides it (R-DK-13, `balloon` reported).
  final bool balloon;

  /// Touches on the device screen (R-DK-10): the firmware of the app remote (`paused` reported).
  final bool touch;
  final bool screen, dismissCard;

  bool supports(ControlCommand c) => switch (c) {
    ControlCommand.minimize || ControlCommand.close || ControlCommand.desktop => touch,
    ControlCommand.screenOff || ControlCommand.screenOn => screen,
    ControlCommand.dismissCard => dismissCard,
    _ => true,
  };

  /// What the remote has but this firmware lacks, in screen order (old-firmware banner).
  List<ControlCommand> get missing => [if (!touch) ControlCommand.minimize, if (!screen) ControlCommand.screenOff];
}
