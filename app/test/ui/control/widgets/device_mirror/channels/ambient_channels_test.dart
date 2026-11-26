import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/models/mirror_frame.dart';
import 'package:glimmer_app/domain/rules/mirror_rules.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/clock_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/forecast_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/info_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/system_channels.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/channels/weather_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/device_mirror.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/mirror_channel.dart';
import 'package:glimmer_app/ui/control/widgets/device_mirror/xp_canvas.dart';

final _vi = lookupAppLocalizations(const Locale('vi'));
const _now = 1795676157;
const _settings = {
  'tzMinutes': 420,
  'weatherLat': 20.4737,
  'weatherLon': 106.0229,
  'userName': 'Một cái tên người dùng rất là dài',
  'showInfo': true,
};

Map<String, dynamic> _weather({bool valid = true, String err = '', bool stale = false}) => {
  'valid': valid,
  'temp_c': 21.6,
  'feels_c': 21.6,
  'humidity': 60,
  'wind_kmh': 7.2,
  'desc': 'Nhiều mây',
  'last_ok': _now - 7200,
  'stale': stale,
  'err': err,
  'days': [
    {'tmin': 15.3, 'tmax': 22, 'desc': 'Nhiều mây'},
    {'tmin': 17.2, 'tmax': 25, 'desc': 'Mưa'},
    {'tmax': 26.7, 'desc': 'Mưa rào'},
  ],
};

DeviceState _state(String channel, {Map<String, dynamic>? weather, String wifi = 'connected', int time = _now}) =>
    DeviceState.fromJson({
      'fw': '0.23.0-glimmer',
      'wifi': wifi,
      'ip': wifi == 'ap' ? '192.168.4.1' : '192.168.10.51',
      'ssid': 'Một mạng Wi-Fi có tên rất dài ơi là dài',
      'rssi': -60,
      'uptime_s': 1655,
      'heap': 22464,
      'maxblk': 21088,
      'next_fetch_s': 154,
      'time': time,
      'active_channel': channel,
      'skills_on': ['agent', 'weather', 'clock'],
      'weather': ?weather,
    });

/// Paints [name]'s painter for [s] at device pixels; any throw fails the test.
void _paint(String name, DeviceState s, {Map<String, dynamic> settings = _settings}) {
  final frame = mirrorFrameOf(s, channel: name, settings: settings, now: DateTime(2026));
  final rec = ui.PictureRecorder();
  final c = XpCanvas(Canvas(rec));
  (mirrorChannels[name] ?? fallbackChannel(name)).paint(c, frame, _vi);
  rec.endRecording().dispose();
}

void main() {
  test('sổ kênh: Weather / Forecast / Clock / Info / màn hệ thống là painter thật', () {
    expect(mirrorChannels['Weather'], isA<WeatherChannel>());
    expect(mirrorChannels['Forecast'], isA<ForecastChannel>());
    expect(mirrorChannels['Clock'], isA<ClockChannel>());
    expect(mirrorChannels['Info'], isA<InfoChannel>());
    expect(mirrorChannels[MirrorFrame.setupScreen], isA<SetupModeScreen>());
    expect(mirrorChannels[MirrorFrame.connectingScreen], isA<ConnectingScreen>());
    expect(mirrorChannels[MirrorFrame.otaScreen], isA<OtaScreen>());
    expect(mirrorChannels[MirrorFrame.noChannels], isA<NoChannelsChannel>());
    for (final n in [MirrorFrame.setupScreen, MirrorFrame.connectingScreen, MirrorFrame.otaScreen]) {
      expect(mirrorChannels[n]!.hasTaskbar, isFalse, reason: n);
    }
  });

  testWidgets('Weather vẽ đủ trạng thái: thường, đang tải, lỗi, cũ, độ F', (t) async {
    _paint('Weather', _state('Weather', weather: _weather()));
    _paint('Weather', _state('Weather'));
    _paint('Weather', _state('Weather', weather: _weather(valid: false)));
    _paint('Weather', _state('Weather', weather: _weather(valid: false, err: 'HTTP 500')));
    _paint('Weather', _state('Weather', weather: _weather(stale: true)));
    _paint('Weather', _state('Weather', weather: _weather()), settings: {..._settings, 'useFahrenheit': true});
    _paint('Weather', _state('Weather', weather: _weather(), time: 0), settings: const {});
  });

  testWidgets('Forecast vẽ 3 ngày và trạng thái trống', (t) async {
    _paint('Forecast', _state('Forecast', weather: _weather()));
    _paint('Forecast', _state('Forecast'));
  });

  testWidgets('Clock vẽ 24 giờ, 12 giờ (SA / CH), tên dài, đồng hồ chưa đặt', (t) async {
    _paint('Clock', _state('Clock'));
    _paint('Clock', _state('Clock'), settings: {..._settings, 'clock24h': false});
    _paint('Clock', _state('Clock', time: _now - 8 * 3600), settings: {..._settings, 'clock24h': false});
    _paint('Clock', _state('Clock', time: 0), settings: const {});
  });

  testWidgets('Info, Night 12 giờ, màn hệ thống và chưa có kênh vẽ được', (t) async {
    _paint('Info', _state('Info'));
    _paint('Info', _state('Info', time: 0), settings: const {});
    _paint('Night', _state('Night'), settings: {..._settings, 'clock24h': false});
    _paint(MirrorFrame.setupScreen, _state('Claude', wifi: 'ap'));
    _paint(MirrorFrame.connectingScreen, _state('Claude'));
    _paint(MirrorFrame.otaScreen, _state('Claude'));
    _paint(MirrorFrame.noChannels, _state('none'));
  });

  testWidgets('DeviceMirror hiện màn đăng nhập khi thiết bị ở chế độ cài đặt', (t) async {
    final frame = mirrorFrameOf(_state('Claude', wifi: 'ap'), now: DateTime(2026));
    expect(frame.channel, MirrorFrame.setupScreen);
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Center(
          child: DeviceMirror(frame: frame, semanticLabel: 'mirror'),
        ),
      ),
    );
    await t.pump();
    expect(t.takeException(), isNull);
  });
}
