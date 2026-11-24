import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/api/models.dart';
import 'package:glimmer_app/ui/clawd.dart';
import 'package:glimmer_app/ui/theme.dart';

void main() {
  test('state JSON from the firmware parses, including usage and the board', () {
    final s = DeviceState.fromJson({
      'fw': '0.22.0-glimmer',
      'build': 'Nov 25 2026 10:21:07',
      'wifi': 'connected',
      'ip': '192.168.100.40',
      'ssid': 'Anh Viet',
      'rssi': -48,
      'uptime_s': 120,
      'heap': 26000,
      'maxblk': 24000,
      'heap_refusals': 0,
      'time': 1795500000,
      'claude_configured': true,
      'claude_usage': {
        'session_used': -1,
        'weekly_used': 66,
        'session_reset': 0,
        'weekly_reset': 1795579199,
        'last_ok': 1795499900,
        'stale': false,
        'cred': 'ok',
      },
      'projects': [
        {'project': 'glimmer', 'agent': 'claude', 'state': 'approval', 'detail': 'Bash', 'age_s': 30, 'idle_s': 5, 'shown': true},
      ],
    });
    expect(s.usage.weeklyUsed, 66);
    expect(s.usage.sessionUsed, -1);
    expect(s.projects.single.detail, 'Bash');
    expect(s.inSetupMode, isFalse);
    expect(s.buildTime, DateTime(2026, 11, 25, 10, 21, 7));
  });

  test('missing fields fall back instead of throwing (older firmware)', () {
    final s = DeviceState.fromJson({'fw': 'x', 'wifi': 'ap'});
    expect(s.inSetupMode, isTrue);
    expect(s.usage.weeklyUsed, -1);
    expect(s.projects, isEmpty);
    expect(s.clockSynced, isFalse);
  });

  test('countdown and ago use the English unit letters, like the panel', () {
    const now = 1795500000;
    expect(countdown(now + 4 * 86400 + 3 * 3600, now), '4d 3h');
    expect(countdown(now + 2 * 3600 + 14 * 60, now), '2h 14m');
    expect(countdown(now + 12 * 60, now), '12m');
    expect(countdown(now - 5, now), 'ngay');
    expect(countdown(0, now), '--');
    expect(ago(45), '45s');
    expect(ago(12 * 60), '12m');
  });

  test('Clawd mood follows the most urgent project state', () {
    expect(moodFor([]), ClawdMood.sleep);
    expect(moodFor(['done', 'approval']), ClawdMood.wide);
    expect(moodFor(['done', 'error']), ClawdMood.sad);
    expect(moodFor(['working']), ClawdMood.open);
    expect(moodFor(['done']), ClawdMood.happy);
  });

  test('usage colour matches the device (by % remaining)', () {
    expect(G.usage(38), G.mint);
    expect(G.usage(60), G.amber);
    expect(G.usage(92), G.coral);
    expect(G.usage(-1), G.muted);
  });
}
