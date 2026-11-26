import '../../data/repositories/device/device_repository.dart';
import '../../utils/result.dart';
import '../models/app_error.dart';
import '../models/control.dart';
import '../rules/control_rules.dart';

/// The app remote (tab Điều khiển, R-DK-1…5): sends one command, once, and says whether the device did what was
/// asked. Optimistic display is the caller's; this only reconciles (R-DK-1: no automatic retry). A command the
/// firmware lacks is refused without sending (R-DK-3).
class ControlDeviceUseCase {
  ControlDeviceUseCase({required DeviceRepository device}) : _device = device;

  final DeviceRepository _device;

  /// R-DK-3: what the connected firmware supports.
  ControlCaps get caps => controlCaps(_device.state);

  Result<ControlOutcome>? _refuse(ControlCommand c) =>
      caps.supports(c) ? null : Result.error(AppError(AppErrorKind.controlUnsupported, detail: c.name));

  /// Next / previous channel. [expected] = the channel the app showed at once (a guess: any answer is followed,
  /// only "nothing moved" counts as not done).
  Future<Result<ControlOutcome>> step(ControlCommand c, {required String from}) async {
    assert(c == ControlCommand.next || c == ControlCommand.prev);
    final refused = _refuse(c);
    if (refused != null) return refused;
    final r = await _device.channel(action: c == ControlCommand.next ? 'next' : 'prev');
    return switch (r) {
      Ok(:final value) => Result.ok(
        ControlOutcome(
          active: value.active,
          paused: value.paused,
          matched: value.active.isNotEmpty && value.active != from,
        ),
      ),
      Error(:final error) => Result.error(error),
    };
  }

  /// Jump to the first channel of [skill] (`{"name"}`); a 404 means that channel is off → the skill's next one.
  /// [settings] = `/api/settings` (agent channels follow their `show*` flags).
  Future<Result<ControlOutcome>> jump(String skill, {Map<String, dynamic>? settings}) async {
    Result<ChannelAnswer>? last;
    final names = jumpCandidates(skill, settings);
    for (final name in names) {
      last = await _device.channel(name: name);
      final e = last is Error<ChannelAnswer> ? last.error : null;
      if (e is AppError && e.kind == AppErrorKind.http && e.status == 404) continue;
      break;
    }
    return switch (last!) {
      Ok(:final value) => Result.ok(
        ControlOutcome(active: value.active, paused: value.paused, matched: channelSkill(value.active) == skill),
      ),
      Error(:final error) => Result.error(error),
    };
  }

  /// R-DK-4: hold / release the rotation for now (never `autoRotate`).
  Future<Result<ControlOutcome>> pause(bool hold) async {
    final c = hold ? ControlCommand.pause : ControlCommand.resume;
    final refused = _refuse(c);
    if (refused != null) return refused;
    final r = await _device.channel(action: c.name);
    return switch (r) {
      Ok(:final value) => Result.ok(
        ControlOutcome(active: value.active, paused: value.paused, matched: value.paused == hold),
      ),
      Error(:final error) => Result.error(error),
    };
  }

  /// Backlight off / on now.
  Future<Result<ControlOutcome>> screen(bool on) async {
    final refused = _refuse(on ? ControlCommand.screenOn : ControlCommand.screenOff);
    if (refused != null) return refused;
    final r = await _device.setScreen(on);
    return switch (r) {
      Ok(:final value) => Result.ok(ControlOutcome(screenOn: value, matched: value == on)),
      Error(:final error) => Result.error(error),
    };
  }

  /// R-DK-2: take card [id] off the device screen; nothing is answered for the agent.
  Future<Result<ControlOutcome>> dismissCard(String id) async {
    final refused = _refuse(ControlCommand.dismissCard);
    if (refused != null) return refused;
    final r = await _device.clearCard(id);
    if (r is Error<void>) return Result.error(r.error);
    await _device.refresh();
    return const Result.ok(ControlOutcome());
  }

  /// R-DK-5: brightness 5…100, sent once on release like Cài đặt.
  Future<Result<ControlOutcome>> brightness(int pct) => _setting({'brightness': pct.clamp(5, 100)});

  /// Night mode of Cài đặt (`nightMode`): 0 off, 1 dim, 2 clock face, 3 dark.
  Future<Result<ControlOutcome>> nightMode(int mode) => _setting({'nightMode': mode});

  Future<Result<ControlOutcome>> _setting(Map<String, dynamic> change) async {
    final r = await _device.saveSettings(change);
    return switch (r) {
      Ok() => const Result.ok(ControlOutcome()),
      Error(:final error) => Result.error(error),
    };
  }

  /// "Làm mới số liệu": the device fetches its sources now, then the app re-reads its state.
  Future<Result<ControlOutcome>> refreshData() async {
    final r = await _device.refreshNow();
    if (r is Error<void>) return Result.error(r.error);
    await _device.refresh();
    return const Result.ok(ControlOutcome());
  }
}
