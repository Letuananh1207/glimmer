import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/weather_location.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/ui/core/themes/app_theme.dart';
import 'package:glimmer_app/ui/weather_location/view_models/weather_location_view_model.dart';
import 'package:glimmer_app/ui/weather_location/widgets/weather_location_screen.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../../testing/fakes/fake_repositories.dart';

const _url = 'http://192.168.1.50';
const _dn = PlaceResult(name: 'Đà Nẵng', lat: 16.07, lon: 108.22, country: 'Việt Nam');
final _vi = lookupAppLocalizations(const Locale('vi'));

void main() {
  late DeviceRig rig;
  late FakeLocationRepository loc;

  setUp(() async {
    rig = await DeviceRig.create();
    loc = FakeLocationRepository();
    await rig.connect(_url);
    rig.api.on(_url, 'GET', '/api/settings', const {
      'weatherLat': 21.03,
      'weatherLon': 105.85,
      'weatherPlace': 'Hà Nội',
    });
  });
  tearDown(() => rig.repo.dispose());

  Future<WeatherLocationViewModel> open(WidgetTester t) async {
    final vm = WeatherLocationViewModel(device: rig.repo, location: loc, doneFor: const Duration(seconds: 1));
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: WeatherLocationScreen(viewModel: vm, onBack: () {}),
        ),
      ),
    );
    await t.pumpAndSettle();
    return vm;
  }

  testWidgets('R-VT-1 shows the device place; GPS off → the banner with "bật định vị"', (t) async {
    await open(t);
    expect(find.text('Hà Nội'), findsOneWidget);
    expect(loc.gpsCalls, 0);
    loc.gpsAnswer = const GpsOutcome.failed(GpsFailure.off);
    await t.tap(find.text(_vi.weatherLocationUseGps));
    await t.pumpAndSettle();
    expect(find.text(_vi.weatherLocationGpsOffTitle), findsOneWidget);
    await t.tap(find.text(_vi.weatherLocationTurnOnGps));
    expect(loc.locationSettings, 1);
  });

  testWidgets('R-VT-2 / R-VT-3 a search result opens the sheet; Apply sends and the note shows', (t) async {
    await open(t);
    loc.searchAnswer = const Result.ok([_dn]);
    await t.enterText(find.byType(TextField), 'Đà');
    await t.pump(const Duration(milliseconds: 450));
    await t.pumpAndSettle();
    expect(loc.searches, ['Đà']);
    await t.tap(find.text('Đà Nẵng'));
    await t.pumpAndSettle();
    expect(find.text(_vi.weatherLocationConfirmTitle), findsOneWidget);

    rig.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
    await t.tap(find.text(_vi.weatherLocationApply));
    await t.pumpAndSettle();
    expect(rig.posts('/api/settings').single.body, {
      'weatherLat': 16.07,
      'weatherLon': 108.22,
      'weatherPlace': 'Đà Nẵng',
    });
    expect(find.text(_vi.weatherLocationDone('Đà Nẵng')), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
  });
}
