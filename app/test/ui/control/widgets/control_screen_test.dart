import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/use_cases/control_device_use_case.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/ui/control/view_models/control_view_model.dart';
import 'package:glimmer_app/ui/control/widgets/control_screen.dart';
import 'package:glimmer_app/ui/control/widgets/hold_card_panel.dart';
import 'package:glimmer_app/ui/control/widgets/key_pad.dart';
import 'package:glimmer_app/ui/control/widgets/power_button.dart';
import 'package:glimmer_app/ui/control/widgets/trackpad.dart';
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
  bool mouse = true,
  String power = 'on',
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
  if (current) 'windows': <String, Object?>{},
  if (current && mouse) ...{
    'cursor': {'port': 4210, 'x': 120, 'y': 120, 'shape': 1, 'shown': true},
    'power': power,
  },
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

  testWidgets('normal: power button, trackpad, mouse buttons, keys, bottom row; no picture of the screen', (t) async {
    await pump(t, _state());
    expect(find.byType(PowerButton), findsOneWidget);
    expect(find.byType(Trackpad), findsOneWidget);
    expect(find.byType(MouseButtons), findsOneWidget);
    expect(find.byType(KeyPad), findsOneWidget);
    expect(find.text(_vi.controlMouseLeft), findsOneWidget);
    expect(find.text(_vi.keyAltTab), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text(_vi.powerOn), findsNothing, reason: 'on: no big Bật máy');
    await t.tap(find.bySemanticsLabel(_vi.controlDetailsA11y));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    expect(opened, [null]);
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('R-DK-19 R-DK-15 the Windows key opens Start on the device', (t) async {
    await pump(t, _state());
    rig.api.on(_url, 'POST', '/api/menu', {'ok': true});
    await t.tap(find.text(_vi.keyWindows));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    expect(rig.posts('/api/menu').single.body, {'kind': 'start', 'all': false});
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('R-DK-21 firmware without the mouse: banner, keys send nothing', (t) async {
    await pump(t, _state(mouse: false));
    expect(find.text(_vi.controlOldFwTitle), findsOneWidget);
    expect(find.text(_vi.controlOldFwBody('0.25.0')), findsOneWidget);
    await t.tap(find.text(_vi.keyWindows), warnIfMissed: false);
    await t.tap(find.byType(PowerButton), warnIfMissed: false);
    await _frames(t);
    expect(rig.posts('/api/menu'), isEmpty);
    expect(rig.posts('/api/power'), isEmpty);
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('R-DK-20 off: Bật máy in the trackpad, a tap boots the device', (t) async {
    await pump(t, _state(power: 'off'));
    expect(find.text(_vi.powerOn), findsOneWidget);
    rig.api.on(_url, 'POST', '/api/power', {'ok': true, 'power': 'booting'});
    await t.tap(find.text(_vi.powerOn));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 50));
    expect(rig.posts('/api/power').single.body, {'on': true});
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
    expect(t.getSize(find.byType(Trackpad)).height, 190 + 6, reason: 'shorter under the card (+ top margin)');
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('glimmer-setup: amber banner with Cài Wi-Fi', (t) async {
    await pump(t, _state(wifi: 'ap'));
    expect(find.text(_vi.controlSetupTitle), findsOneWidget);
    expect(find.text(_vi.controlSetupAction), findsOneWidget);
    await t.binding.setSurfaceSize(null);
  });

  testWidgets('offline: coral banner', (t) async {
    await pump(t, _state());
    await t.runAsync(() async {
      rig.api.gone(_url);
      await rig.repo.refresh();
    });
    await _frames(t);
    expect(find.text(_vi.controlOfflineTitle), findsOneWidget);
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
}
