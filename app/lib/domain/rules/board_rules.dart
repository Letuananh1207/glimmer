// Bảng project ở Tổng quan và biểu cảm Clawd — giống firmware.
import '../models/attention_card.dart';
import '../models/clawd_mood.dart';
import '../models/project.dart';

const _order = ['approval', 'input', 'error', 'working', 'done'];

/// R-PRJ-1: chỉ project `shown`, xếp approval → input → error → working → done.
List<Project> boardRows(List<Project> all) =>
    List.unmodifiable(all.where((p) => p.shown).toList()
      ..sort((a, b) => _order.indexOf(a.state).compareTo(_order.indexOf(b.state))));

/// R-PRJ-2: biểu cảm theo hàng gấp nhất — trống → ngủ, approval → mắt to, error → buồn,
/// working/input → mắt mở, còn lại → vui.
ClawdMood moodFor(List<String> states) {
  if (states.isEmpty) return ClawdMood.sleep;
  if (states.contains('approval')) return ClawdMood.wide;
  if (states.contains('error')) return ClawdMood.sad;
  if (states.contains('working') || states.contains('input')) return ClawdMood.open;
  return ClawdMood.happy;
}

/// Agents waiting on the user — visible approval / input cards, like the firmware's `countWaiting`
/// (badge on the Agent dock tab and the Màn hình nav tab).
int agentsWaiting(List<AttentionCard> cards) =>
    cards.where((c) => c.showsInS <= 0 && (c.kind == 'approval' || c.kind == 'input')).length;

/// Badge text: hidden (null) at 0, "9+" above 9.
String? badgeText(int n) => n <= 0 ? null : (n > 9 ? '9+' : '$n');
