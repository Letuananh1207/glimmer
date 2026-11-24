import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../domain/models/app_error.dart';
import '../../../domain/models/attention_card.dart';
import '../../../domain/models/clawd_mood.dart';
import '../../../domain/models/device_state.dart';
import '../../../domain/models/project.dart';
import '../../../domain/rules/board_rules.dart';
import '../../../domain/rules/time_rules.dart';
import '../../../domain/rules/usage_rules.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

/// One usage row (week or 5-hour session).
class UsageRowData {
  const UsageRowData(this.used, this.level, this.resetInS);

  /// % used, -1 = unknown.
  final int used;

  /// Colour (R-DUNG-1); [UsageLevel.unknown] also when the data is stale (R-DUNG-4).
  final UsageLevel level;

  /// Seconds until it resets (R-DUNG-3): null unknown, 0 now.
  final int? resetInS;
}

/// Màn Tổng quan: mức dùng Claude, bảng project, thẻ trên màn hình (screen_specs §2).
class DashboardViewModel extends ChangeNotifier with SafeNotifier {
  DashboardViewModel({required DeviceRepository device}) : _device = device {
    _device.addListener(_update);
    _update();
  }

  final DeviceRepository _device;

  List<Project> _rows = const [];

  /// Đang tải: chưa có trạng thái nào từ thiết bị.
  DeviceState? get state => _device.state;

  /// R-PRJ-1.
  List<Project> get rows => _rows;

  /// R-PRJ-2.
  ClawdMood get mood => moodFor([for (final p in _rows) p.state]);
  bool get walking => _rows.any((p) => p.state == 'working');

  List<AttentionCard> get cards => _device.cards;

  /// Line under the header: the last refresh error, else "cards need a token" (R-KN-4).
  AppError? get error => _device.error;
  bool get cardsNeedToken => _device.cardsNeedToken;

  UsageMeta get meta => usageMeta(_device.state!);

  UsageRowData get week => _row(_device.state!.usage.weeklyUsed, _device.state!.usage.weeklyReset);
  UsageRowData get session => _row(_device.state!.usage.sessionUsed, _device.state!.usage.sessionReset);

  UsageRowData _row(int used, int reset) {
    final s = _device.state!;
    return UsageRowData(used, s.usage.stale ? UsageLevel.unknown : usageLevel(used), secondsUntil(reset, s.time));
  }

  void _update() {
    _rows = boardRows(_device.state?.projects ?? const []);
    notifyListeners();
  }

  Future<void> refresh() => _device.refresh();

  /// Run [f]; on success refresh. The View shows the done / error message.
  Future<Result<void>> _act(Future<Result<void>> Function() f) async {
    final r = await f();
    if (r is Ok) await _device.refresh();
    return r;
  }

  Future<Result<void>> clearProjects() => _act(_device.clearProjects);
  Future<Result<void>> clearCard(String id) => _act(() => _device.clearCard(id));
  Future<Result<void>> clearAllCards() => _act(_device.clearAllCards);
  Future<Result<void>> refreshNow() => _act(_device.refreshNow);
  Future<Result<void>> showClaude() => _act(() => _device.showChannel('Claude'));

  @override
  void dispose() {
    _device.removeListener(_update);
    super.dispose();
  }
}
