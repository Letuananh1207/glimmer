import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/models/mirror_frame.dart';
import 'package:glimmer_app/domain/models/usage_mirror.dart';
import 'package:glimmer_app/domain/rules/mirror_rules.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/ai_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/claude_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/codex_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/trend_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/mirror_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/xp_canvas.dart';

final _vi = lookupAppLocalizations(const Locale('vi'));
const _now = 1795676159;
const _settings = {'tzMinutes': 420, 'refreshMin': 5, 'claudeWeeklyHero': true};

/// Records every string the painter writes.
class _Rec extends XpCanvas {
  _Rec(super.canvas);

  final texts = <String>[];

  @override
  void text(
    String s,
    num x,
    num y,
    XpFont f,
    Color color, {
    XpAlign align = XpAlign.left,
    double? maxWidth,
    Color? shadow,
    FontStyle? fontStyle,
  }) {
    texts.add(maxWidth == null ? s : fit(s, f, maxWidth));
    super.text(s, x, y, f, color, align: align, maxWidth: maxWidth, shadow: shadow, fontStyle: fontStyle);
  }
}

Map<String, dynamic> _usage({String cred = 'ok', int lastOk = _now - 120, bool stale = false}) => {
  'session_used': 12,
  'weekly_used': 38,
  'session_reset': _now + 2 * 3600 + 14 * 60,
  'weekly_reset': _now + 4 * 86400,
  'last_ok': lastOk,
  'stale': stale,
  'cred': cred,
};

DeviceState _state({
  bool valid = true,
  String err = '',
  Map<String, dynamic>? usage,
  List<Map<String, dynamic>> projects = const [],
  Map<String, dynamic> codex = const {'valid': false, 'cred': 'checking'},
  bool codexConfigured = true,
}) => DeviceState.fromJson({
  'fw': '0.23.0-glimmer',
  'wifi': 'connected',
  'ip': '192.168.10.51',
  'time': _now,
  'claude_configured': true,
  'codex_configured': codexConfigured,
  'claude_valid': valid,
  'claude_err': err,
  'claude_usage': usage ?? _usage(),
  'projects': projects,
  'sources': {
    'claude': {'valid': valid, 'code': err == 'Mất mạng' ? -1 : 200},
    'codex': codex,
  },
});

Map<String, dynamic> _proj(String name, String state, {String detail = '', int age = 120}) => {
  'project': name,
  'agent': 'claude',
  'state': state,
  'detail': detail,
  'age_s': age,
  'idle_s': 1,
  'shown': true,
};

List<String> _paint(String name, DeviceState s, {Map<String, dynamic> settings = _settings, MirrorFrame? frame}) {
  final f = frame ?? mirrorFrameOf(s, channel: name, settings: settings, now: DateTime(2026));
  final rec = ui.PictureRecorder();
  final c = _Rec(Canvas(rec));
  mirrorChannels[name]!.paint(c, f, _vi);
  rec.endRecording().dispose();
  return c.texts;
}

/// Real JetBrains Mono / VT323 metrics (the painters fit text by width, like the firmware).
Future<void> _loadFonts() async {
  final jb = FontLoader('JetBrainsMono')
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Bold.ttf'));
  final vt = FontLoader(XpCanvas.vt323)..addFont(rootBundle.load('assets/fonts/VT323-Regular.ttf'));
  await Future.wait([jb.load(), vt.load()]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);

  test('sổ kênh: Claude / Codex / AI / Trend là painter thật', () {
    expect(mirrorChannels['Claude'], isA<ClaudeChannel>());
    expect(mirrorChannels['Codex'], isA<CodexChannel>());
    expect(mirrorChannels['AI'], isA<AiChannel>());
    expect(mirrorChannels['Trend'], isA<TrendChannel>());
  });

  group('Claude', () {
    test('bình thường: hero tuần, đếm ngược, nhóm phiên, bảng project', () {
      final t = _paint(
        'Claude',
        _state(
          projects: [
            _proj('glimmer', 'approval', detail: 'Bash'),
            _proj('TieuMac3d', 'working', age: 300),
            _proj('api', 'done', age: 3600),
            _proj('thừa', 'done'),
          ],
        ),
      );
      expect(t, containsAll(['Claude', 'Hạn mức tuần', '38', '%', '4NG', 'Phiên 5 giờ', '12% · 2G 14P']));
      expect(t, containsAll(['glimmer', 'Cần duyệt · Bash', '2P', 'Đang chạy', '5P', 'Xong', '1G']));
      expect(t, isNot(contains('thừa')));
    });

    test('dữ liệu cũ: tiêu đề "· cũ 14P"', () {
      final t = _paint('Claude', _state(usage: _usage(lastOk: _now - 14 * 60 - 30 - 900, stale: true)));
      expect(t.first, startsWith('Claude · cũ'));
    });

    test('khóa hết hạn còn số: "khóa lỗi" + dải vàng + 2 dòng', () {
      final t = _paint(
        'Claude',
        _state(
          usage: _usage(cred: 'expired'),
          projects: [_proj('a', 'working'), _proj('b', 'working'), _proj('c', 'working')],
        ),
      );
      expect(t.first, 'Claude · khóa lỗi');
      expect(t, contains('Khóa hết hạn · glimmer.local'));
      expect(t.where((s) => s == 'c'), isEmpty);
    });

    test('chưa có project: Clawd ngủ, dòng giữa ô', () {
      final t = _paint('Claude', _state());
      expect(t, contains('Chưa có hoạt động project'));
    });

    test('đang tải / từ chối / mất mạng / lỗi upstream / bị chặn', () {
      expect(_paint('Claude', _state(valid: false, usage: _usage(cred: 'checking'))), contains('Đang tải...'));
      expect(
        _paint('Claude', _state(valid: false, usage: _usage(cred: 'rejected'))),
        containsAll(['Khóa bị từ chối', 'claude.ai từ chối khóa.', 'glimmer.local', '192.168.10.51']),
      );
      expect(
        _paint(
          'Claude',
          _state(
            valid: false,
            err: 'Mất mạng',
            usage: _usage(cred: 'ok'),
          ),
        ),
        containsAll(['Mất mạng', 'Không tới được claude.ai.', 'Đang tự động thử lại...']),
      );
      expect(
        _paint(
          'Claude',
          _state(
            valid: false,
            err: 'HTTP 503',
            usage: _usage(cred: 'ok'),
          ),
        ),
        containsAll(['Không đọc được', 'HTTP 503']),
      );
      expect(
        _paint('Claude', _state(valid: false, usage: _usage(cred: 'blocked'))),
        containsAll(['Claude · bị chặn', 'Bị chặn', 'Khóa vẫn tốt.']),
      );
    });
  });

  group('Codex', () {
    test('đang tải', () => expect(_paint('Codex', _state()), contains('Đang tải...')));

    test('token hết hạn: hộp thoại có ngày', () {
      final t = _paint('Codex', _state(codex: {'valid': false, 'cred': 'expired', 'expires_at': _now - 86400}));
      expect(t, containsAll(['Codex · khóa lỗi', 'Token hết hạn', 'Nhập token mới tại:']));
      expect(t.any((s) => s.startsWith('Hết hạn ngày ')), isTrue);
    });

    test('có dữ liệu: khung đủ, số chưa có thì "--", lượt đặt lại từ sources', () {
      final t = _paint(
        'Codex',
        _state(
          codex: {
            'valid': true,
            'cred': 'ok',
            'last_ok': _now - 60,
            'resets': {'left': 2, 'usable': true, 'ends_at': _now + 3 * 86400},
          },
        ),
      );
      expect(t, containsAll(['Hạn mức', '--', 'đặt lại sau', 'Đã dùng', 'Đặt lại tuần', 'còn 2 · 3NG']));
    });

    test('cũ + token bị từ chối còn số: dải vàng', () {
      final t = _paint('Codex', _state(codex: {'valid': true, 'cred': 'rejected', 'last_ok': _now - 3600}));
      expect(t, contains('Bị từ chối · glimmer.local')); // the long form is 217 px > 203
      expect(t, contains('Chưa có lượt'));
    });

    test('đầy đủ số (khi firmware gửi): tín dụng, tag, nhịp tuần', () {
      final s = _state();
      final base = mirrorFrameOf(s, channel: 'Codex', settings: _settings, now: DateTime(2026));
      final f = MirrorFrame(
        channel: 'Codex',
        state: s,
        deviceNow: base.deviceNow,
        usage: const UsageMirror(
          codex: CodexMirror(
            view: UsageView.data,
            heroLabel: WindowLabel(WindowKind.week),
            heroUsed: 41,
            heroReset: DevSpan(SpanKind.days, 3),
            credits: 4.2,
            secLabel: WindowLabel(WindowKind.hours, 5),
            secReset: DevSpan(SpanKind.hoursMinutes, 2, 14),
            secTag: 'SPARK',
            secKnown: true,
            resets: ResetCredits(left: 2, span: DevSpan(SpanKind.days, 3)),
            pace: CodexPace.atReset(70),
          ),
        ),
      );
      final t = _paint('Codex', s, frame: f);
      expect(t, containsAll(['Hạn mức tuần', '41', 'tín dụng', r'$4.20', '3NG', 'Phiên 5 giờ', 'Spark', '2G 14P']));
      expect(t, containsAll(['còn 2 · 3NG', '~70% khi đặt lại']));
    });
  });

  group('AI hôm nay', () {
    test('Codex đang tải: "--", "Đang tải...", CL đếm ngược', () {
      final t = _paint('AI', _state());
      expect(t, containsAll(['AI hôm nay', 'Tín dụng Codex còn', '--', '38%', 'Đang tải...', 'CL 4NG · CX --']));
    });

    test('khóa Claude lỗi: "Khóa" + lý do ở thanh trạng thái', () {
      final t = _paint(
        'AI',
        _state(
          usage: _usage(cred: 'rejected'),
          codex: {'valid': true, 'cred': 'ok'},
        ),
      );
      expect(t, containsAll(['Khóa', 'Khóa Claude bị từ chối']));
    });

    test('bị chặn: "Chặn"', () {
      final t = _paint('AI', _state(codex: {'valid': true, 'cred': 'blocked'}));
      expect(t, containsAll(['Chặn', 'chatgpt.com chặn máy này']));
    });
  });

  group('Xu hướng', () {
    test('lịch sử chưa có trong /api/state: khung, thứ, không chú thích', () {
      final t = _paint('Trend', _state());
      expect(t, containsAll(['Xu hướng', '7 ngày · % hạn mức tuần', 'T2', 'CN']));
      expect(t, isNot(contains('Claude')));
    });

    test('khóa lỗi: thanh trạng thái nói lý do', () {
      expect(_paint('Trend', _state(usage: _usage(cred: 'expired'))), contains('Khóa Claude hết hạn'));
    });

    test('có lịch sử (khi firmware gửi): chú thích, Hôm nay, Đỉnh; đang thu thập', () {
      final s = _state();
      final days = mirrorFrameOf(s, settings: _settings, now: DateTime(2026)).usage.trend.weekdays;
      MirrorFrame frame(List<double?> a, List<double?> b) => MirrorFrame(
        channel: 'Trend',
        state: s,
        deviceNow: DateTime(2026),
        usage: UsageMirror(
          trend: TrendMirror(
            blocks: [
              TrendBlock(claude: true, burn: a),
              TrendBlock(claude: false, burn: b),
            ],
            weekdays: days,
          ),
        ),
      );
      final full = _paint('Trend', s, frame: frame([5.9, 10, 4, 1.9, 15, 7.9, 4.4], [2.5, 4.4, 6.9, 9, 3.4, 1.5, 1.9]));
      expect(full, containsAll(['Claude', 'Codex', 'Hôm nay CL 4 · CX 2']));
      expect(full.any((t) => t.startsWith('Đỉnh ')), isTrue);
      final two = _paint(
        'Trend',
        s,
        frame: frame([null, null, null, null, null, 3, 4], [null, null, null, null, null, null, 1]),
      );
      expect(two, containsAll(['Đang thu thập...', 'Có 2 / 7 ngày']));
    });
  });
}
