import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/models/usage_mirror.dart';
import 'package:glimmer_app/domain/rules/usage_mirror_rules.dart';

const _now = 1795676159;

BoardRow _row(String state) => BoardRow('p', state, '', DevSpan.unknown);

void main() {
  group('spans like TimeUtil', () {
    test('countdown', () {
      expect(countdownSpan(0, _now), DevSpan.unknown);
      expect(countdownSpan(_now + 100, 5), DevSpan.unknown);
      expect(countdownSpan(_now - 1, _now), const DevSpan(SpanKind.now));
      expect(countdownSpan(_now + 14 * 60 + 5, _now), const DevSpan(SpanKind.minutes, 14));
      expect(countdownSpan(_now + 2 * 3600 + 14 * 60, _now), const DevSpan(SpanKind.hoursMinutes, 2, 14));
      expect(countdownSpan(_now + 3 * 86400 + 13 * 3600, _now), const DevSpan(SpanKind.days, 4));
    });

    test('short duration', () {
      expect(shortSpan(-5), const DevSpan(SpanKind.minutes, 0));
      expect(shortSpan(14 * 60), const DevSpan(SpanKind.minutes, 14));
      expect(shortSpan(5400), const DevSpan(SpanKind.hours, 2));
      expect(shortSpan(172800 + 43200), const DevSpan(SpanKind.days, 3));
    });
  });

  test('stale: 3 refresh intervals with a 15-minute floor', () {
    expect(staleAt(_now - 901, _now, 1), isTrue);
    expect(staleAt(_now - 899, _now, 1), isFalse);
    expect(staleAt(_now - 1000, _now, 10), isFalse);
    expect(staleAt(0, _now, 5), isFalse);
    expect(staleAt(_now - 5000, 100, 5), isFalse);
  });

  test('title meta priority: bad key > stale > expiring > vendor > label', () {
    TitleMeta m({String cred = 'ok', int lastOk = _now, int jwt = 0, String vendor = '', String label = ''}) =>
        titleMetaOf(
          cred: credKind(cred),
          lastOk: lastOk,
          now: _now,
          refreshMin: 5,
          jwtExp: jwt,
          vendorLevel: vendor,
          vendorOk: _now - 60,
          label: label,
        );
    expect(m(cred: 'rejected', lastOk: _now - 9999).kind, MetaKind.keyBad);
    expect(m(cred: 'blocked').kind, MetaKind.blocked);
    expect(m(lastOk: _now - 1800).kind, MetaKind.stale);
    expect(m(lastOk: _now - 1800).span, const DevSpan(SpanKind.minutes, 30));
    expect(m(cred: 'expiring', jwt: _now + 2 * 86400).kind, MetaKind.expiring);
    expect(m(vendor: 'critical').kind, MetaKind.major);
    expect(m(vendor: 'operational', label: 'GPT-5').label, 'GPT-5');
    expect(m().kind, MetaKind.none);
  });

  test('message box kind', () {
    expect(credCardOf(CredKind.ok, '').kind, CredCardKind.offline);
    expect(credCardOf(CredKind.ok, 'Mất mạng', code: -1).kind, CredCardKind.offline);
    expect(credCardOf(CredKind.ok, 'HTTP 503', code: 503).kind, CredCardKind.upstream);
    expect(credCardOf(CredKind.expired, '', expiresAt: _now, tzMinutes: 420).expiry, isNotNull);
    expect(credCardOf(CredKind.expired, '').expiry, isNull);
    expect(usageView(false, CredKind.checking, ''), UsageView.loading);
    expect(usageView(false, CredKind.rejected, ''), UsageView.card);
    expect(usageView(true, CredKind.rejected, ''), UsageView.data);
  });

  test('Clawd follows the most urgent row; asleep when empty or all done', () {
    expect(clawdPoseOf(const []).asleep, isTrue);
    expect(clawdPoseOf([_row('done')]).asleep, isTrue);
    expect(clawdPoseOf([_row('approval')]).mood, ClawdMood.wide);
    expect(clawdPoseOf([_row('error')]).mood, ClawdMood.sad);
    expect(clawdPoseOf([_row('working')]).walk, isTrue);
    expect(clawdPoseOf([_row('input')]).mood, ClawdMood.open);
  });

  test('advice: reset credit > use-it-or-lose-it > most room > both low', () {
    AiAdvice? a(double cl, double cx, {int clReset = 0, int cxReset = 0, int clCredits = 0}) => aiAdvice(
      now: _now,
      claudeLeft: cl,
      claudeReset: clReset,
      claudeCredits: clCredits,
      claudeUsable: true,
      codexLeft: cx,
      codexReset: cxReset,
      codexCredits: 0,
      codexUsable: false,
    );
    expect(
      aiAdvice(
        now: _now,
        claudeLeft: 50,
        claudeReset: 0,
        claudeCredits: 0,
        claudeUsable: false,
        codexLeft: null,
        codexReset: 0,
        codexCredits: 0,
        codexUsable: false,
      ),
      isNull,
    );
    expect(a(10, 80, clCredits: 2)!.kind, AdviceKind.resets);
    final soon = a(30, 80, clReset: _now + 3600);
    expect((soon!.kind, soon.claude), (AdviceKind.use, true));
    expect(a(30, 80)!.claude, isFalse);
    expect(a(10, 12)!.kind, AdviceKind.bothLow);
  });

  test('frame from /api/state: Claude rows, Codex resets, Trend weekdays', () {
    final s = DeviceState.fromJson({
      'time': _now,
      'claude_configured': true,
      'codex_configured': true,
      'claude_valid': true,
      'claude_usage': {'weekly_used': 38, 'session_used': 12, 'weekly_reset': _now + 3600, 'cred': 'ok'},
      'projects': [
        {'project': 'a', 'state': 'working', 'age_s': 60, 'shown': true},
        {'project': 'b', 'state': 'done', 'age_s': 60, 'shown': false},
      ],
      'sources': {
        'codex': {
          'valid': true,
          'cred': 'ok',
          'resets': {'left': 1, 'usable': true, 'ends_at': _now + 30 * 86400},
        },
      },
    });
    final m = usageMirrorOf(s, const {'claudeWeeklyHero': true, 'tzMinutes': 420});
    expect(m.claude.heroUsed, 38);
    expect(m.claude.heroLevel, UsageLevel.ok);
    expect(m.claude.rows.map((r) => r.project), ['a']);
    expect(m.claude.clawd.mood, ClawdMood.open);
    expect(m.codex.view, UsageView.data);
    expect(m.codex.resets.until, isNotNull);
    expect(m.ai.claude.used, 38);
    expect(m.ai.codex.mode, AiMode.value);
    expect(m.trend.blocks.length, 2);
    expect(m.trend.weekdays.length, 7);
    expect(m.trend.haveDays, isNull);
  });
}
