import '../../../domain/models/weather_location.dart';
import '../../../utils/result.dart';

/// Finding a place for the device's weather (design 2026-11-26.9): the phone's position (only when asked, R-VT-1) and
/// the Open-Meteo city search (R-VT-2). Nothing is stored on the phone.
abstract class LocationRepository {
  /// The phone's position and, when its geocoder knows one, the place name.
  Future<GpsOutcome> currentPlace();

  /// Cities matching [query] (≤ 10). Failures are [AppError]s.
  Future<Result<List<PlaceResult>>> search(String query);

  /// The phone's settings for this app (permission denied for good).
  Future<void> openAppSettings();

  /// The phone's location settings (location services off).
  Future<void> openLocationSettings();
}
