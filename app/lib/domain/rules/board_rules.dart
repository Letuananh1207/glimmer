// Bảng project ở Tổng quan và biểu cảm Clawd — giống firmware.
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
