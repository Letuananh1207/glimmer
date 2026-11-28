import '../../../domain/models/library_photo.dart';

/// R-AK-4: the photo library served on the home network (plain HTTP) so the device can point at it.
abstract class PhotoServerRepository {
  bool get running;

  /// The port served on (0 = not running).
  int get port;

  /// Serve on [port] (another free one when it is taken); [next] answers "the photo after id". Returns the port.
  Future<int> start({required int port, required String key, required Future<ServedPhoto?> Function(int after) next});

  Future<void> stop();
}
