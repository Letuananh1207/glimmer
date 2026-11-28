import '../../../domain/models/library_photo.dart';
import '../../services/photo_server_service.dart';
import 'photo_server_repository.dart';

class PhotoServerRepositoryLocal implements PhotoServerRepository {
  PhotoServerRepositoryLocal({required PhotoServerService server}) : _server = server;

  final PhotoServerService _server;

  @override
  bool get running => _server.running;

  @override
  int get port => _server.port;

  @override
  Future<int> start({required int port, required String key, required Future<ServedPhoto?> Function(int after) next}) =>
      _server.start(
        port: port,
        key: key,
        next: (after) async {
          final p = await next(after);
          return p == null ? null : (id: p.id, index: p.index, count: p.count, jpeg: p.jpeg);
        },
      );

  @override
  Future<void> stop() => _server.stop();
}
