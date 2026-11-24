import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/clawd_mood.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/models/project.dart';
import 'package:glimmer_app/domain/models/release.dart';
import 'package:glimmer_app/domain/rules/board_rules.dart';
import 'package:glimmer_app/domain/rules/time_rules.dart';
import 'package:glimmer_app/domain/rules/update_rules.dart';
import 'package:glimmer_app/domain/rules/usage_rules.dart';
import 'package:glimmer_app/utils/durations.dart';

DeviceState _s({bool key = true, String cred = 'ok', bool stale = false, int lastOk = 0, int time = 1795500000}) =>
    DeviceState.fromJson({
      'time': time,
      'claude_configured': key,
      'claude_usage': {'cred': cred, 'stale': stale, 'last_ok': lastOk},
    });

void main() {
  test('R-DUNG-1 usage colour by % remaining', () {
    expect(usageLevel(38), UsageLevel.ok);
    expect(usageLevel(49), UsageLevel.ok);
    expect(usageLevel(50), UsageLevel.low);
    expect(usageLevel(60), UsageLevel.low);
    expect(usageLevel(80), UsageLevel.critical);
    expect(usageLevel(92), UsageLevel.critical);
    expect(usageLevel(-1), UsageLevel.unknown);
  });

  test('R-DUNG-2 usage meta priority', () {
    expect(usageMeta(_s(key: false, cred: 'blocked')).kind, UsageMetaKind.noKey);
    expect(usageMeta(_s(cred: 'expired', stale: true)).kind, UsageMetaKind.keyBad);
    expect(usageMeta(_s(cred: 'rejected')).kind, UsageMetaKind.keyBad);
    expect(usageMeta(_s(cred: 'blocked', stale: true)).kind, UsageMetaKind.blocked);
    final stale = usageMeta(_s(stale: true, lastOk: 1795500000 - 1500));
    expect((stale.kind, stale.ageS), (UsageMetaKind.stale, 1500));
    final fresh = usageMeta(_s(lastOk: 1795500000 - 120));
    expect((fresh.kind, fresh.ageS), (UsageMetaKind.fresh, 120));
    expect(usageMeta(_s(lastOk: 100, time: 5)).kind, UsageMetaKind.none, reason: 'clock not synced');
    expect(usageMeta(_s()).kind, UsageMetaKind.none);
  });

  test('R-DUNG-3 countdown and ago use the English unit letters, like the panel', () {
    const now = 1795500000;
    expect(spanShort(secondsUntil(now + 4 * 86400 + 3 * 3600, now)!), '4d 3h');
    expect(spanShort(secondsUntil(now + 2 * 3600 + 14 * 60, now)!), '2h 14m');
    expect(spanShort(secondsUntil(now + 12 * 60, now)!), '12m');
    expect(secondsUntil(now - 5, now), 0);
    expect(secondsUntil(0, now), isNull);
    expect(secondsUntil(now + 60, 5), isNull);
    expect(agoShort(45), '45s');
    expect(agoShort(12 * 60), '12m');
    expect(agoShort(3 * 3600), '3h');
    expect(agoShort(3 * 86400), '3d');
  });

  test('R-PRJ-1 board: shown only, most urgent first', () {
    Project p(String name, String state, {bool shown = true}) => Project(name, 'claude', state, '', 0, 0, shown);
    final rows = boardRows([p('a', 'done'), p('b', 'working'), p('c', 'approval'), p('d', 'input', shown: false)]);
    expect(rows.map((r) => r.project), ['c', 'b', 'a']);
  });

  test('R-PRJ-2 Clawd mood follows the most urgent project state', () {
    expect(moodFor([]), ClawdMood.sleep);
    expect(moodFor(['done', 'approval']), ClawdMood.wide);
    expect(moodFor(['done', 'error']), ClawdMood.sad);
    expect(moodFor(['working']), ClawdMood.open);
    expect(moodFor(['input']), ClawdMood.open);
    expect(moodFor(['done']), ClawdMood.happy);
  });

  test('R-TB-1 update available only past 30 min of slack', () {
    final build = DateTime(2026, 11, 25, 10);
    Release r(int minutes) => Release(build.add(Duration(minutes: minutes)), '', const {});
    expect(updateAvailable(build, r(20)), isFalse);
    expect(updateAvailable(build, r(31)), isTrue);
    expect(updateAvailable(null, r(60)), isFalse);
    expect(updateAvailable(build, null), isFalse);
  });

  test('R-TB-2 a restore file must be a glimmer config.json', () {
    expect(isGlimmerConfig({'wifi_ssid': 'Nha'}), isTrue);
    expect(isGlimmerConfig({'a': 1}), isFalse);
  });
}
