import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/domain/models/weather_location.dart';
import 'package:glimmer_app/ui/weather_location/view_models/weather_location_view_model.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../../testing/fakes/fake_repositories.dart';

const _url = 'http://192.168.1.50';
const _hn = <String, Object>{'weatherLat': 21.03, 'weatherLon': 105.85, 'weatherPlace': 'Hà Nội', 'tzMinutes': 420};
const _dn = PlaceResult(name: 'Đà Nẵng', lat: 16.07, lon: 108.22, country: 'Việt Nam');

void main() {
  late DeviceRig rig;
  late FakeLocationRepository loc;

  Future<WeatherLocationViewModel> open(Map<String, Object> settings) async {
    await rig.connect(_url);
    rig.api.on(_url, 'GET', '/api/settings', settings);
    final vm = WeatherLocationViewModel(device: rig.repo, location: loc, doneFor: const Duration(milliseconds: 50));
    await vm.load();
    return vm;
  }

  setUp(() async {
    rig = await DeviceRig.create();
    loc = FakeLocationRepository();
  });
  tearDown(() => rig.repo.dispose());

  test('reads the device location', () async {
    final vm = await open(_hn);
    expect((vm.current.place, vm.current.isSet, vm.placeSupported, vm.tzMinutes), ('Hà Nội', true, true, 420));
  });

  test('R-VT-1 GPS only when pressed; each failure has its state', () async {
    final vm = await open(_hn);
    expect(loc.gpsCalls, 0, reason: 'opening the screen never asks');
    for (final (f, s) in [
      (GpsFailure.denied, GpsState.denied),
      (GpsFailure.deniedForever, GpsState.deniedForever),
      (GpsFailure.off, GpsState.off),
      (GpsFailure.failed, GpsState.failed),
    ]) {
      loc.gpsAnswer = GpsOutcome.failed(f);
      expect(await vm.useGps(), isNull);
      expect(vm.gps, s);
    }
    loc.gpsAnswer = const GpsOutcome.fix(_dn);
    expect(await vm.useGps(), _dn);
    expect(vm.gps, GpsState.idle);
    expect(loc.gpsCalls, 5);
  });

  test('R-VT-2 search waits 400 ms after the last key, from 2 characters; one search per pause', () async {
    final vm = await open(_hn);
    loc.searchAnswer = const Result.ok([_dn]);
    vm.setQuery('Đ');
    expect(vm.search, SearchState.idle);
    vm.setQuery('Đà');
    vm.setQuery('Đà N');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(loc.searches, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(loc.searches, ['Đà N']);
    expect(vm.search, SearchState.results);
    expect(vm.results, [_dn]);

    loc.searchAnswer = const Result.ok([]);
    vm.setQuery('zzz');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(vm.search, SearchState.none);

    loc.searchAnswer = const Result.error(AppError(AppErrorKind.unreachable));
    await vm.retrySearch();
    expect(vm.search, SearchState.error);

    vm.setQuery('');
    expect(vm.search, SearchState.idle);
    expect(vm.results, isEmpty);
  });

  test('R-VT-3 apply sends lat, lon and the name cut to 16; the card updates and a note shows', () async {
    final vm = await open(_hn);
    rig.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
    expect(await vm.apply(_dn, 'Thành phố Đà Nẵng xinh đẹp'), isTrue);
    expect(rig.posts('/api/settings').single.body, {
      'weatherLat': 16.07,
      'weatherLon': 108.22,
      'weatherPlace': 'Thành phố Đà Nẵn',
    });
    expect(vm.current.place, 'Thành phố Đà Nẵn');
    expect(vm.done, 'Thành phố Đà Nẵn');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(vm.done, isNull);
  });

  test('R-VT-3 rename sends only the name', () async {
    final vm = await open(_hn);
    rig.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
    expect(await vm.rename(' Nhà '), isTrue);
    expect(rig.posts('/api/settings').single.body, {'weatherPlace': 'Nhà'});
    expect((vm.current.place, vm.current.lat), ('Nhà', 21.03));
  });

  test('R-VT-3 a refused send keeps the device location and shows the failure; not retried', () async {
    final vm = await open(_hn);
    expect(await vm.apply(_dn, 'Đà Nẵng'), isFalse, reason: 'no answer to the POST');
    expect((vm.sendFailed, vm.sending, vm.current.place, vm.done), (true, false, 'Hà Nội', null));
    expect(rig.posts('/api/settings'), hasLength(1));
    vm.sheetClosed();
    expect(vm.sendFailed, isFalse);
  });

  test('R-VT-4 firmware without weatherPlace: coordinates only', () async {
    final vm = await open(const {'weatherLat': 21.03, 'weatherLon': 105.85});
    expect(vm.placeSupported, isFalse);
    rig.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
    await vm.apply(_dn, 'Đà Nẵng');
    expect(rig.posts('/api/settings').single.body, {'weatherLat': 16.07, 'weatherLon': 108.22});
  });

  test('R-VT-5 clear sends 0, 0, "" and the card reads not set', () async {
    final vm = await open(_hn);
    rig.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
    expect(await vm.clear(), isTrue);
    expect(rig.posts('/api/settings').single.body, {'weatherLat': 0, 'weatherLon': 0, 'weatherPlace': ''});
    expect(vm.current.isSet, isFalse);
  });
}
