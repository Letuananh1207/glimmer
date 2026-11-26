import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/use_cases/control_device_use_case.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/ui/control/view_models/control_view_model.dart';
import 'package:glimmer_app/domain/rules/mirror_rules.dart';
import 'package:glimmer_app/ui/control/widgets/control_screen.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/touch_mirror.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/mirror_channel.dart';
import 'package:glimmer_app/ui/control/widgets/hold_card_panel.dart';
import 'package:glimmer_app/ui/control/widgets/start_menu_sheet.dart';
import 'package:glimmer_app/ui/core/themes/app_theme.dart';

import '../../../../testing/fakes/fake_repositories.dart';

const _url = 'http://192.168.1.50';
final _vi = lookupAppLocalizations(const Locale('vi'));

Map<String, dynamic> _state({
  String channel = 'Home',
  bool current = true,
  bool screenOn = true,
  String wifi = 'connected',
  bool night = false,
}) => {
  'fw': current ? '0.25.0' : '0.24.0',
  'wifi': wifi,
  'ip': wifi == 'ap' ? '192.168.4.1' : '192.168.1.50',
  'ssid': 'Nha-2G',
  'time': 1795500000,
  'active_channel': channel,
  'night_face': night,
  'skills_on': ['agent', 'photo', 'weather', 'clock'],
  'claude_usage': {'weekly_used': 38, 'session_used': 12},
  if (current) ...{'paused': false, 'screen_on': screenOn, 'slide_ms': 8000, 'slide_left_ms': 6000},
};

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.dark(),
  locale: const Locale('vi'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: home),
);

Future<void> _frames(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late DeviceRig rig;
  ControlViewModel? vm;
  final opened = <String?>[];

  setUp(() async {
    rig = await DeviceRig.create();
    opened.clear();
  });
  tearDown(() {
    vm?.dispose();
    vm = null;
    rig.repo.dispose();
  });

  Future<void> pump(WidgetTester t, Map<String, dynamic> state, {List<Object> cards = const []}) async {
    await t.binding.setSurfaceSize(const Size(390, 1400));
    await t.runAsync(() async {
      await rig.connect(_url, state);
      rig.api.on(_url, 'GET', '/push', {'cards': cards});
      rig.api.on(_url, 'GET', '/api/settings', {'brightness': 80, 'nightMode': 0});
      vm = ControlViewModel(
        device: rig.repo,
        control: ControlDeviceUseCase(device: rig.repo),
      );
      await vm!.reload();
    });
    await t.pumpWidget(
      _app(
        ControlScreen(
          viewModel: vm!,
          onOpenDetails: (s) async => opened.add(s),
          onUpdateFirmware: () {},
          onSetupWifi: () {},
          onOpenSettings: () => opened.add('settings'),
          onOpenSkills: () => opened.add('skills'),
        ),
      ),
    );
    await _frames(t);
  }

  testWidgets('normal: touch mirror, brightness, toggles; no legend, no status line, no rotation buttons', (t) async {
    await pump(t, _state());
    expect(find.byType(TouchMirror), findsOneWidget);
    expect(find.textContaining(_vi.controlOpenOnDevice, findRichText: true), findsNothing);
    expect(find.text(_vi.controlLegendTitle), findsNothing);
    expect(find.text(_vi.controlPrev), findsNothing);
    expect(find.text(_vi.controlPause), findsNothing);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text(_vi.controlDetails), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    await t.tap(find.text(_vi.controlDetails));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    expect(opened, [null]);
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('R-DK-3 R-DK-10 old firmware: banner + lock, a touch on × sends nothing', (t) async {
    await pump(t, _state(current: false));
    expect(find.text(_vi.controlOldFwTitle), findsOneWidget);
    expect(find.text(_vi.controlOldFwBody('0.24.0')), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    final mirror = t.getTopLeft(find.byType(TouchMirror));
    // × at device (228, 11) → shell pad 6 + screen pad 2 + × 1.5.
    await t.tapAt(mirror + const Offset(8 + 228 * 1.5, 8 + 11 * 1.5));
    await _frames(t);
    expect(rig.posts(), isEmpty);
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('R-DK-8 start on the mirror opens Start; Bảng điều khiển → Cài đặt', (t) async {
    await pump(t, _state());
    final mirror = t.getTopLeft(find.byType(TouchMirror));
    await t.tapAt(mirror + const Offset(8 + 30 * 1.5, 8 + 227 * 1.5));
    await _frames(t);
    expect(find.byType(StartMenuSheet), findsOneWidget);
    expect(find.text(_vi.startAllPrograms), findsOneWidget);
    await t.tap(find.text(_vi.startAllPrograms));
    await _frames(t);
    expect(find.text(_vi.allProgramsTitle), findsOneWidget);
    expect(find.text(_vi.appForecast), findsOneWidget);
    await t.tap(find.byTooltip(_vi.allProgramsBackA11y));
    await _frames(t);
    await t.tap(find.text(_vi.startControlPanel));
    await _frames(t);
    expect(opened, ['settings']);
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('R-DK-2 card holds the screen: panel with Bỏ thẻ, no approve button', (t) async {
    await pump(
      t,
      _state(channel: 'Attention'),
      cards: [
        {'id': 'c1', 'kind': 'approval', 'agent': 'claude', 'value': 'Bash', 'project': 'glimmer'},
      ],
    );
    expect(find.byType(HoldCardPanel), findsOneWidget);
    expect(find.text(_vi.controlCardLabel), findsOneWidget);
    expect(find.text(_vi.controlDismissCard), findsOneWidget);
    expect(find.text(_vi.stateApproval), findsNothing, reason: 'the app never approves');
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('screen off: title + note, power lit as Bật màn', (t) async {
    await pump(t, _state(screenOn: false));
    expect(find.textContaining(_vi.controlScreenOffTitle, findRichText: true), findsOneWidget);
    expect(find.text(_vi.controlScreenOffOverlay), findsOneWidget);
    expect(find.text(_vi.controlScreenOn), findsOneWidget);
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('night face: night line', (t) async {
    await pump(t, _state(channel: 'Night', night: true));
    expect(find.textContaining(_vi.controlNightNote('00:00'), findRichText: true), findsOneWidget);
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('glimmer-setup: amber banner with Cài Wi-Fi', (t) async {
    await pump(t, _state(wifi: 'ap'));
    expect(find.text(_vi.controlSetupTitle), findsOneWidget);
    expect(find.text(_vi.controlSetupAction), findsOneWidget);
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('offline: coral banner, overlay on the last picture', (t) async {
    await pump(t, _state());
    await t.runAsync(() async {
      rig.api.gone(_url);
      await rig.repo.refresh();
    });
    await _frames(t);
    expect(find.text(_vi.controlOfflineTitle), findsOneWidget);
    expect(find.text(_vi.controlOfflineOverlayNote), findsOneWidget);
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('R-DK-1 failed command: snackbar with Thử lại', (t) async {
    await pump(t, _state());
    await t.runAsync(() => vm!.openProgram('Clock'));
    await _frames(t);
    expect(find.text(_vi.controlFailed(_vi.devControlCmdOpen(_vi.appClock))), findsOneWidget);
    expect(find.text(_vi.commonRetry), findsOneWidget);
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('DeviceMirror foundation: every registered channel and the night face paint', (t) async {
    final s = DeviceState.fromJson(_state());
    for (final name in mirrorChannels.keys) {
      final frame = mirrorFrameOf(s, channel: name, now: DateTime(2026), settings: const {'tzMinutes': 420});
      await t.pumpWidget(
        _app(
          Center(
            child: TouchMirror(frame: frame, semanticLabel: name),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull, reason: name);
    }
    final unknown = mirrorFrameOf(s, channel: 'Music', now: DateTime(2026));
    await t.pumpWidget(
      _app(
        Center(
          child: TouchMirror(frame: unknown, semanticLabel: 'x', dim: 0.4, offline: true),
        ),
      ),
    );
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text(_vi.controlOfflineOverlay), findsOneWidget);
  });
}
