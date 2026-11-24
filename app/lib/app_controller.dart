import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api/device_api.dart';
import 'api/models.dart';
import 'services/discovery.dart';
import 'services/store.dart';

/// App-wide state: which display, its latest state and cards, polling.
class AppController extends ChangeNotifier {
  AppController(this.store);

  final Store store;
  DeviceApi? api;
  DeviceState? state;
  List<Card> cards = const [];
  String? error;
  bool searching = false;
  Timer? _poll;

  bool get connected => api != null;

  /// Find the display (saved address, NSD, glimmer.local, setup AP).
  Future<bool> discover() async {
    searching = true;
    error = null;
    notifyListeners();
    final found = await Discovery.find(saved: store.deviceUrl, token: store.token);
    searching = false;
    if (found == null) {
      error = 'Không tìm thấy thiết bị trên mạng này.';
      notifyListeners();
      return false;
    }
    _use(found.url, found.state);
    return true;
  }

  /// Connect to an address the user typed ("192.168.1.50" or a URL).
  Future<bool> connectTo(String address, {String? token}) async {
    var url = address.trim();
    if (url.isEmpty) return false;
    if (!url.startsWith('http')) url = 'http://$url';
    if (token != null) store.token = token.trim();
    searching = true;
    error = null;
    notifyListeners();
    final probe = DeviceApi(url, token: store.token);
    final s = await probe.probe(timeout: const Duration(seconds: 6));
    probe.close();
    searching = false;
    if (s == null) {
      error = 'Không có thiết bị glimmer ở $url.';
      notifyListeners();
      return false;
    }
    _use(url, s);
    return true;
  }

  void _use(String url, DeviceState s) {
    api?.close();
    api = DeviceApi(url, token: store.token);
    state = s;
    if (url != DeviceApi.setupApUrl) store.deviceUrl = url;
    notifyListeners();
    startPolling();
    refresh();
  }

  void forget() {
    stopPolling();
    api?.close();
    api = null;
    state = null;
    cards = const [];
    notifyListeners();
  }

  void setToken(String t) {
    store.token = t.trim();
    if (api != null) _use(api!.baseUrl, state!);
  }

  Future<void> refresh() async {
    final a = api;
    if (a == null) return;
    try {
      state = await a.state();
      error = null;
      try {
        cards = await a.cards();
      } on DeviceException catch (e) {
        if (!e.unauthorized) rethrow;
        cards = const [];
        error = 'Thiết bị có API token — nhập token trong Cài đặt để xem thẻ.';
      }
    } on DeviceException catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  void dispose() {
    stopPolling();
    api?.close();
    super.dispose();
  }
}
