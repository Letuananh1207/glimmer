import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/attention_card.dart';
import 'package:glimmer_app/domain/models/device_photo.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/models/mirror_agents.dart';
import 'package:glimmer_app/domain/rules/mirror_agent_rules.dart';

AttentionCard _card(
  String kind, {
  String id = 'c',
  String agent = 'claude',
  String title = '',
  String body = '',
  String value = '',
  int progress = -1,
  int age = 120,
  int showsIn = 0,
}) => AttentionCard(id, kind, agent, title, value, body, 'glimmer', progress, age, showsInS: showsIn);

DeviceState _state({
  String cred = 'ok',
  bool weather = true,
  int session = 38,
  int? photos,
  List<String> skills = const ['agent', 'weather', 'clock'],
}) => DeviceState.fromJson({
  'ip': '192.168.10.51',
  'skills_on': skills,
  'claude_configured': true,
  'claude_usage': {'session_used': session, 'weekly_used': 12, 'cred': cred},
  'weather_configured': weather,
  if (weather) 'weather': {'valid': true, 'temp_c': 29.4, 'feels_c': 33.0, 'desc': 'Ít mây'},
  'photos': ?photos,
});

void main() {
  group('thẻ Attention', () {
    test('toolAndDetail như firmware', () {
      expect(toolAndDetail('Bash: pio run'), ('Bash', 'pio run'));
      expect(toolAndDetail('Claude wants to use Edit'), ('Edit', ''));
      expect(toolAndDetail('hello'), ('', 'hello'));
    });

    test('duyệt: dòng chi tiết = tool · lệnh, mắt mở to, chờ bạn', () {
      final m = mirrorCardOf(_card('approval', title: 'APPROVAL NEEDED', body: 'Bash: pio run', value: 'x'));
      expect(m.lead, 'Bash · pio run');
      expect(m.body, '');
      expect(m.ownTitle, isNull);
      expect(m.eyes, ClawdEyes.wide);
      expect(m.waits, isTrue);
    });

    test('"Claude finished" → finished; câu hỏi không thân → waiting', () {
      final done = mirrorCardOf(_card('success', title: 'DONE', body: 'Claude finished'));
      expect((done.bodyForm, done.body, done.eyes), (CardBody.finished, 'Claude', ClawdEyes.happy));
      final q = mirrorCardOf(_card('input', body: 'Claude is waiting for your input'));
      expect(q.bodyForm, CardBody.waiting);
      expect(mirrorCardOf(_card('error', title: 'Build hỏng')).ownTitle, 'Build hỏng');
    });

    test('giữ màn: duyệt/câu hỏi khi ghim, thẻ khác 30 s đầu; thẻ Codex chưa tới giờ bị ẩn', () {
      final cards = [
        _card('approval', id: 'a', age: 500),
        _card('success', id: 'b', age: 10),
        _card('info', id: 'c', age: 40),
        _card('input', id: 'd', showsIn: 20),
      ];
      expect(screenHolders(cards).map((c) => c.id), ['a', 'b']);
      expect(screenHolders(cards, pin: false).map((c) => c.id), ['b']);
      final m = attentionOf(cards, null)!;
      expect((m.index, m.count, m.kind), (0, 2, CardKind.approval));
      expect(attentionOf([_card('info', age: 99)], null)!.count, 1);
      expect(attentionOf(const [], null), isNull);
    });
  });

  group('danh sách Tác tử', () {
    test('dòng đầu chờ bạn được chọn; tiêu đề hook và tiến độ', () {
      final l = agentsListOf([
        _card('approval', body: 'Bash: x'),
        _card('progress', title: 'TESTS RUN', progress: 64),
        _card('success', title: 'DONE'),
      ]);
      expect(l.rows.map((r) => r.title), [RowTitle.needYou, RowTitle.own, RowTitle.hookDone]);
      expect(l.rows.first.selected, isTrue);
      expect(l.rows.first.suffix, 'Bash');
      expect((l.rows[1].text, l.rows[1].suffix), ('Tests run', '64%'));
      expect((l.total, l.approvals, l.inputs, l.more), (3, 1, 0, 0));
    });

    test('> 3 thẻ: 2 dòng + phần còn lại; không tiêu đề → chữ của loại', () {
      final l = agentsListOf([for (var i = 0; i < 5; i++) _card('warning', id: '$i')]);
      expect((l.rows.length, l.more), (2, 3));
      expect(l.rows.first.title, RowTitle.kindWord);
      expect(l.rows.first.selected, isFalse);
    });

    test('shortDurationOf như TimeUtil::shortDuration', () {
      expect(shortDurationOf(150), (2, DurUnit.minutes));
      expect(shortDurationOf(5400), (2, DurUnit.hours));
      expect(shortDurationOf(3 * 86400), (3, DurUnit.days));
      expect(shortDurationOf(-5), (0, DurUnit.minutes));
    });
  });

  group('desktop, cài đặt, ảnh', () {
    test('nhãn Claude: số của phiên / tuần; khóa lỗi hoặc chưa có số → tên trơn', () {
      expect(desktopOf(_state(), null).claudePct, 38);
      expect(desktopOf(_state(), {'claudeWeeklyHero': true}).claudePct, 12);
      expect(desktopOf(_state(cred: 'rejected'), null).claudePct, isNull);
      expect(desktopOf(_state(session: -1), null).claudePct, isNull);
      expect(desktopOf(_state(), null).codexPct, isNull);
    });

    test('bóng thời tiết: °C / °F làm tròn, không vị trí → không bóng', () {
      final d = desktopOf(_state(), null);
      expect((d.balloon, d.temp, d.feels, d.desc), (true, 29, 33, 'Ít mây'));
      expect(desktopOf(_state(), {'useFahrenheit': true}).temp, 85);
      expect(desktopOf(_state(weather: false), null).balloon, isFalse);
    });

    test('cài đặt: số bước còn lại theo khóa và vị trí', () {
      final s = setupOf(_state(weather: false), {'codexToken': ''});
      expect((s.claude, s.codex, s.weather, s.left, s.ip), (true, false, false, 2, '192.168.10.51'));
    });

    test('ảnh: ảnh đầu tiên có bản sao của app, số ảnh theo thiết bị', () {
      final jpeg = Uint8List.fromList([1]);
      final g = PhotoGallery(const PhotoInfo(photos: [DevicePhoto('p1.jpg', 1), DevicePhoto('p2.jpg', 1)]), [
        const GalleryPhoto(DevicePhoto('p1.jpg', 1), null),
        GalleryPhoto(const DevicePhoto('p2.jpg', 1), jpeg),
      ]);
      final p = mirrorPhotoOf(2, g);
      expect((p.count, p.index, p.jpeg), (2, 1, jpeg));
      expect(mirrorPhotoOf(null, g).count, 2);
      expect(mirrorPhotoOf(0, null).empty, isTrue);
      expect(mirrorPhotoOf(3, null).jpeg, isNull);
    });
  });
}
