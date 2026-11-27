import 'dart:io';

/// The phone's own network addresses (R-AK-4: the device must reach the photo library on the home network).
class NetworkService {
  /// IPv4 addresses of the phone's interfaces, loopback left out.
  Future<List<String>> ipv4() async => [
    for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4))
      for (final a in i.addresses)
        if (!a.isLoopback) a.address,
  ];
}
