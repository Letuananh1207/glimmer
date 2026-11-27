import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/rules/start_rules.dart';

const _four = ['agent', 'photo', 'weather', 'clock'];
const _all = ['agent', 'photo', 'weather', 'clock', 'fun'];

StartPick _at(
  int x,
  int y, {
  List<String> skills = _four,
  bool all = false,
  bool agents = false,
  List<String> recent = const [],
}) => startPickAt(x, y, skillsOn: skills, all: all, showAgents: agents, recent: recent);

void main() {
  group('R-DK-22 left column', () {
    test('Claude, Codex pinned; 3 rows of 20 from y 99: nothing opened yet → Ảnh, Thời tiết, Đồng hồ', () {
      expect(_at(60, 50), const StartPick(StartPickKind.program, program: 'Claude'));
      expect(_at(60, 80), const StartPick(StartPickKind.program, program: 'Codex'));
      expect(_at(30, 105), const StartPick(StartPickKind.program, program: 'Photo'));
      expect(_at(30, 125), const StartPick(StartPickKind.program, program: 'Weather'));
      expect(_at(30, 145), const StartPick(StartPickKind.program, program: 'Clock'));
      expect(_at(30, 160), StartPick.none);
    });

    test('the programs opened last come first (start_recent), installed only, then the fill order', () {
      expect(startRecentRows(['Mines', 'Trend'], _all), ['Mines', 'Trend', 'Photo']);
      expect(startRecentRows(['Mines', 'Claude'], _four), ['Photo', 'Weather', 'Clock'], reason: 'fun off, Claude pinned');
      expect(_at(30, 105, skills: _all, recent: ['Mines']), const StartPick(StartPickKind.program, program: 'Mines'));
      expect(_at(30, 125, skills: _all, recent: ['Mines']), const StartPick(StartPickKind.program, program: 'Photo'));
    });

    test('without Agent the rows start at y 38', () {
      expect(
        _at(30, 45, skills: const ['weather', 'clock']),
        const StartPick(StartPickKind.program, program: 'Weather'),
      );
      expect(_at(30, 65, skills: const ['weather', 'clock']), const StartPick(StartPickKind.program, program: 'Clock'));
      expect(_at(30, 85, skills: const ['weather', 'clock']), StartPick.none);
    });

    test('Tất cả chương trình toggles its sub-menu', () {
      expect(_at(60, 175), const StartPick(StartPickKind.toggleAll));
    });
  });

  group('R-DK-22 All Programs sub-menu (P-2026-11-27.25)', () {
    test('every installed program, (144, top, 96 wide); too tall → moved up until the bottom is ≤ 213', () {
      // Everything + Agents: 9 programs → (144, 2, 96 × 211); rows from y 4.
      expect(_at(190, 10, skills: _all, all: true, agents: true), const StartPick(StartPickKind.program, program: 'Claude'));
      expect(_at(190, 4 + 20 * 2 + 5, skills: _all, all: true, agents: true),
          const StartPick(StartPickKind.program, program: 'AI'));
      expect(_at(190, 4 + 20 * 4 + 5, skills: _all, all: true, agents: true),
          const StartPick(StartPickKind.program, program: 'Agents'));
      expect(_at(190, 4 + 20 * 8 + 5, skills: _all, all: true, agents: true),
          const StartPick(StartPickKind.program, program: 'Mines'));
      expect(_at(190, 4 + 20 * 9 + 7 + 5, skills: _all, all: true, agents: true),
          const StartPick(StartPickKind.appScreen, screen: AppScreen.skills));
      // Without Agents: 8 programs, h 191 → top 22.
      expect(_at(190, 24 + 5, skills: _all, all: true), const StartPick(StartPickKind.program, program: 'Claude'));
      // The sub-menu covers x 144..151 of the left column too.
      expect(_at(146, 30, skills: _all, all: true), const StartPick(StartPickKind.program, program: 'Claude'));
    });

    test('small enough → top y 62, as before', () {
      expect(_at(190, 70, skills: const ['weather', 'clock'], all: true),
          const StartPick(StartPickKind.program, program: 'Weather'));
      // Closed: the same point is the right column (Số liệu).
      expect(_at(190, 70), const StartPick(StartPickKind.appScreen, screen: AppScreen.details));
    });
  });

  group('R-DK-22 right column, bottom band, outside', () {
    test('Desktop; Số liệu, Cài đặt, Thêm / gỡ, Thiết bị open the phone screen', () {
      expect(_at(190, 45), const StartPick(StartPickKind.desktop));
      expect(_at(190, 98), const StartPick(StartPickKind.appScreen, screen: AppScreen.settings));
      expect(_at(190, 118), const StartPick(StartPickKind.appScreen, screen: AppScreen.skills));
      expect(_at(190, 140), const StartPick(StartPickKind.appScreen, screen: AppScreen.device));
      expect(_at(190, 84), StartPick.none); // the divider
    });

    test('Khởi động lại, Tắt máy; the taskbar closes Start', () {
      expect(_at(40, 200), const StartPick(StartPickKind.restart));
      expect(_at(200, 200), const StartPick(StartPickKind.turnOff));
      expect(_at(140, 200), StartPick.none);
      expect(_at(30, 225), const StartPick(StartPickKind.close));
      expect(_at(150, 230), const StartPick(StartPickKind.close));
    });
  });
}
