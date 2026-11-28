import 'dart:io';
import 'dart:typed_data';

/// The mouse pointer to the device over UDP (R-DK-17). Fire and forget: a lost datagram is fixed by the next one, so
/// nothing is awaited or retried. The datagram itself comes from domain/rules/cursor_rules.dart.
class CursorService {
  RawDatagramSocket? _socket;
  Future<RawDatagramSocket>? _opening;
  String? _host;
  InternetAddress? _address;

  /// Send [datagram] to [host] (an IP or a name such as glimmer.local) at [port]. False = not sent (no network,
  /// unknown host); the caller just keeps going.
  Future<bool> send(String host, int port, Uint8List datagram) async {
    try {
      final socket = _socket ??= await (_opening ??= RawDatagramSocket.bind(InternetAddress.anyIPv4, 0));
      if (host != _host || _address == null) {
        _address = InternetAddress.tryParse(host) ?? (await InternetAddress.lookup(host)).first;
        _host = host;
      }
      return socket.send(datagram, _address!, port) > 0;
    } catch (_) {
      _address = null;
      return false;
    }
  }

  void close() {
    _socket?.close();
    _socket = null;
    _opening = null;
  }
}
