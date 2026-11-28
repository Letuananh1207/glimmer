import 'package:geolocator/geolocator.dart';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/weather_location.dart';
import '../../../utils/result.dart';
import '../../services/geo_search_service.dart';
import '../../services/position_service.dart';
import 'location_repository.dart';

/// [LocationRepository] over the phone's location services and Open-Meteo geocoding.
class LocationRepositoryRemote implements LocationRepository {
  LocationRepositoryRemote({required PositionService position, required GeoSearchService search})
    : _position = position,
      _search = search;

  final PositionService _position;
  final GeoSearchService _search;

  @override
  Future<GpsOutcome> currentPlace() async {
    try {
      if (!await _position.serviceEnabled()) return const GpsOutcome.failed(GpsFailure.off);
      final p = await _position.askPermission();
      if (p == LocationPermission.deniedForever) return const GpsOutcome.failed(GpsFailure.deniedForever);
      if (p == LocationPermission.denied || p == LocationPermission.unableToDetermine) {
        return const GpsOutcome.failed(GpsFailure.denied);
      }
      final (lat, lon) = await _position.current();
      ({String name, String region, String country})? place;
      try {
        place = await _position.placeOf(lat, lon);
      } on Exception {
        place = null; // no name: the user types one (design: the name field stays empty)
      }
      return GpsOutcome.fix(
        PlaceResult(
          name: place?.name ?? '',
          region: place?.region ?? '',
          country: place?.country ?? '',
          lat: lat,
          lon: lon,
        ),
      );
    } on LocationServiceDisabledException {
      return const GpsOutcome.failed(GpsFailure.off);
    } on PermissionDeniedException {
      return const GpsOutcome.failed(GpsFailure.denied);
    } on Exception {
      return const GpsOutcome.failed(GpsFailure.failed);
    }
  }

  @override
  Future<Result<List<PlaceResult>>> search(String query) async {
    try {
      final rows = await _search.search(query);
      return Result.ok([
        for (final r in rows)
          if (r['latitude'] is num && r['longitude'] is num && r['name'] is String)
            PlaceResult(
              name: r['name'] as String,
              region: r['admin1'] is String ? r['admin1'] as String : '',
              country: r['country'] is String ? r['country'] as String : '',
              lat: (r['latitude'] as num).toDouble(),
              lon: (r['longitude'] as num).toDouble(),
            ),
      ]);
    } on GeoSearchException catch (e) {
      return Result.error(AppError(AppErrorKind.unreachable, status: e.status, detail: 'open-meteo'));
    } on Exception catch (e) {
      return Result.error(AppError(AppErrorKind.unreachable, detail: '$e'));
    }
  }

  @override
  Future<void> openAppSettings() => _position.openAppSettings();

  @override
  Future<void> openLocationSettings() => _position.openLocationSettings();
}
