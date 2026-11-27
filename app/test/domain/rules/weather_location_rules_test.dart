import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/weather_location.dart';
import 'package:glimmer_app/domain/rules/weather_location_rules.dart';

const _dn = PlaceResult(name: 'Đà Nẵng', lat: 16.0678, lon: 108.2208, country: 'Việt Nam');

void main() {
  test('R-VT-2 search from 2 characters, 400 ms after the last key', () {
    expect(shouldSearch(''), isFalse);
    expect(shouldSearch(' Đ '), isFalse);
    expect(shouldSearch('Đà'), isTrue, reason: 'characters, not bytes');
    expect(searchDelay, const Duration(milliseconds: 400));
  });

  test('R-VT-3 the device name: trimmed, at most 16 characters (letters, not bytes)', () {
    expect(deviceName('  Đà Nẵng  '), 'Đà Nẵng');
    expect(deviceName('Thành phố Hồ Chí Minh'), 'Thành phố Hồ Chí');
    expect(deviceName('Thành phố Hồ Chí Minh').runes.length, locationNameMax);
    expect(nameLength(' Huế '), 3);
  });

  test('R-VT-3 apply sends lat, lon and the name; rename only the name', () {
    expect(applyBody(_dn, 'Đà Nẵng', place: true), {
      'weatherLat': 16.0678,
      'weatherLon': 108.2208,
      'weatherPlace': 'Đà Nẵng',
    });
    expect(renameBody(' Nhà '), {'weatherPlace': 'Nhà'});
  });

  test('R-VT-4 firmware without weatherPlace → coordinates only', () {
    expect(placeSupported({'weatherLat': 21.0}), isFalse);
    expect(placeSupported(null), isFalse);
    expect(placeSupported({'weatherPlace': ''}), isTrue);
    expect(applyBody(_dn, 'Đà Nẵng', place: false), {'weatherLat': 16.0678, 'weatherLon': 108.2208});
  });

  test('R-VT-5 clear = 0, 0, "" (old firmware: no name); 0, 0 reads as not set', () {
    expect(clearBody(place: true), {'weatherLat': 0, 'weatherLon': 0, 'weatherPlace': ''});
    expect(clearBody(place: false), {'weatherLat': 0, 'weatherLon': 0});
    expect(locationOf(clearBody(place: true)).isSet, isFalse);
    final l = locationOf({'weatherLat': 21.03, 'weatherLon': 105.85, 'weatherPlace': 'Hà Nội'});
    expect((l.isSet, l.place, coord(l.lat)), (true, 'Hà Nội', '21.03'));
  });

  test('gmtOffset of the preview clock line', () {
    expect(gmtOffset(420), '+7');
    expect(gmtOffset(-180), '-3');
    expect(gmtOffset(330), '+5:30');
  });
}
