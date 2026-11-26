import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/attention_card.dart';
import 'package:glimmer_app/domain/models/device_photo.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/rules/mirror_rules.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/agents_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/attention_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/home_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/photo_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/setup_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/mirror_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/xp_canvas.dart';

final _vi = lookupAppLocalizations(const Locale('vi'));
const _now = 1795676157;

DeviceState _state(
  String channel, {
  bool claude = true,
  String cred = 'ok',
  bool weather = true,
  bool weatherValid = true,
  int? photos,
}) => DeviceState.fromJson({
  'fw': '0.23.0-glimmer',
  'wifi': 'connected',
  'ip': '192.168.10.51',
  'time': _now,
  'active_channel': channel,
  'skills_on': ['agent', 'photo', 'weather', 'clock'],
  'claude_configured': claude,
  'claude_usage': {'session_used': 38, 'weekly_used': 12, 'cred': cred},
  'weather_configured': weather,
  if (weather) 'weather': {'valid': weatherValid, 'temp_c': 29.4, 'feels_c': 33, 'desc': 'Ít mây'},
  'photos': ?photos,
});

AttentionCard _card(
  String kind, {
  String id = 'c',
  String agent = 'claude',
  String title = '',
  String body = '',
  String value = '',
  String project = 'glimmer',
  int progress = -1,
  int age = 120,
}) => AttentionCard(id, kind, agent, title, value, body, project, progress, age);

void _paint(
  String name,
  DeviceState s, {
  List<AttentionCard> cards = const [],
  Map<String, dynamic>? settings,
  PhotoGallery? gallery,
  MirrorChannel? painter,
}) {
  final frame = mirrorFrameOf(
    s,
    channel: name,
    cards: cards,
    settings: settings,
    now: DateTime(2026),
    gallery: gallery,
  );
  final rec = ui.PictureRecorder();
  (painter ?? mirrorChannels[name]!).paint(XpCanvas(Canvas(rec)), frame, _vi);
  rec.endRecording().dispose();
}

void main() {
  test('sổ kênh: Attention / Agents / Home / Setup / Photo là painter thật', () {
    expect(mirrorChannels['Attention'], isA<AttentionChannel>());
    expect(mirrorChannels['Agents'], isA<AgentsChannel>());
    expect(mirrorChannels['Home'], isA<HomeChannel>());
    expect(mirrorChannels['Setup'], isA<SetupChannel>());
    expect(mirrorChannels['Photo'], isA<PhotoChannel>());
  });

  group('Attention', () {
    final s = _state('Attention');
    test('mọi loại thẻ vẽ được', () {
      for (final c in [
        _card('approval', body: 'Bash: pio run -e nodemcuv2 với một lệnh rất là dài không vừa một dòng'),
        _card('input', agent: 'codex', age: 30),
        _card('success', title: 'DONE', body: 'Claude finished'),
        _card('error', title: 'Build hỏng', body: 'exit 1'),
        _card('progress', title: 'Tests', progress: 64),
        _card('progress'),
        _card('warning', agent: 'other', project: ''),
        _card('info', value: '42', body: 'x'),
      ]) {
        _paint('Attention', s, cards: [c]);
      }
    });
    test('nhiều thẻ giữ màn, hàng đợi trống', () {
      _paint(
        'Attention',
        s,
        cards: [
          _card('approval', id: 'a'),
          _card('input', id: 'b'),
        ],
      );
      _paint('Attention', s);
    });
  });

  group('Agents', () {
    final s = _state('Agents');
    test('thường, rảnh, nhiều hơn 3, trống', () {
      _paint(
        'Agents',
        s,
        cards: [
          _card('approval', body: 'Bash: x'),
          _card('progress', progress: 64),
          _card('success'),
        ],
      );
      _paint(
        'Agents',
        s,
        cards: [
          _card('progress', title: 'TESTS', progress: 64),
          _card('success', title: 'DONE'),
        ],
      );
      _paint(
        'Agents',
        s,
        cards: [for (var i = 0; i < 5; i++) _card('info', id: '$i', title: 'Thẻ số $i')],
      );
      _paint('Agents', s);
    });
  });

  test('Home: có số, khóa lỗi, chưa có thời tiết, không vị trí', () {
    _paint('Home', _state('Home'));
    _paint('Home', _state('Home', cred: 'rejected'), settings: {'claudeWeeklyHero': true, 'useFahrenheit': true});
    _paint('Home', _state('Home', weatherValid: false));
    _paint('Home', _state('Home', weather: false, claude: false));
  });

  test('Setup: còn 3 bước, đã xong một phần', () {
    _paint('Setup', _state('Setup', claude: false, weather: false));
    _paint('Setup', _state('Setup'), settings: {'codexToken': '***'});
  });

  test('Photo: trống, có ảnh không bản xem, có bản xem chưa giải mã', () {
    _paint('Photo', _state('Photo', photos: 0));
    _paint('Photo', _state('Photo', photos: 3));
    final g = PhotoGallery(const PhotoInfo(photos: [DevicePhoto('p1.jpg', 3)]), [
      GalleryPhoto(const DevicePhoto('p1.jpg', 3), Uint8List.fromList([1, 2, 3])),
    ]);
    _paint('Photo', _state('Photo', photos: 1), gallery: g);
  });

  testWidgets('Photo: vẽ bản sao của app khi có ảnh đã giải mã', (t) async {
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(const Rect.fromLTWH(0, 0, 4, 4), Paint());
    final img = await t.runAsync(() => rec.endRecording().toImage(4, 4));
    final g = PhotoGallery(const PhotoInfo(photos: [DevicePhoto('p1.jpg', 3)]), [
      GalleryPhoto(const DevicePhoto('p1.jpg', 3), Uint8List.fromList([1, 2, 3])),
    ]);
    _paint(
      'Photo',
      _state('Photo', photos: 2),
      gallery: g,
      painter: PhotoChannel(image: img),
    );
    expect(withPhoto(mirrorChannels, img)['Photo'], isA<PhotoChannel>());
    expect(withPhoto(mirrorChannels, null), same(mirrorChannels));
    img!.dispose();
  });
}
