import 'package:flutter/material.dart';

import '../api/device_api.dart';
import '../app_controller.dart';
import '../services/wifi.dart';
import 'clawd.dart';
import 'theme.dart';

/// Put the display on a Wi-Fi network.
///
/// If the display is reachable (it's online here, or the phone is on its
/// setup AP) the new network is sent directly. Otherwise the phone joins
/// "glimmer-setup" just for this app (Android asks to confirm once), sends
/// the network, lets go, and looks for the display on the normal Wi-Fi.
class WifiSetupScreen extends StatefulWidget {
  const WifiSetupScreen(this.c, {super.key});
  final AppController c;

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

enum _Step { form, working, done, failed }

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final _ssid = TextEditingController();
  final _pass = TextEditingController();
  bool _show = false;
  _Step _step = _Step.form;
  String _status = '';
  String _detail = '';

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    await PhoneWifi.ensurePermissions();
    final s = await PhoneWifi.currentSsid();
    if (s != null && s != DeviceApi.setupApSsid && mounted && _ssid.text.isEmpty) {
      setState(() => _ssid.text = s);
    }
  }

  void _say(String status, [String detail = '']) {
    if (mounted) {
      setState(() {
        _status = status;
        _detail = detail;
      });
    }
  }

  Future<void> _run() async {
    final ssid = _ssid.text.trim();
    if (ssid.isEmpty) return;
    setState(() => _step = _Step.working);
    final c = widget.c;
    var viaAp = false;
    try {
      // 1. Already reachable on this network? Send it straight away.
      // Only when it actually answers here — a display that already left
      // this network would swallow the request, and its silence would look
      // like the reboot that follows a successful save.
      DeviceApi? api;
      final reachable = c.connected && !(c.state?.inSetupMode ?? false) && await c.api!.probe() != null;
      if (reachable) {
        _say('Gửi Wi-Fi mới cho thiết bị…');
        api = DeviceApi(c.api!.baseUrl, token: c.store.token);
      } else {
        // 2. Through the display's setup AP.
        _say('Đang vào Wi-Fi glimmer-setup…',
            'Thiết bị phải đang hiện KẾT NỐI WI-FI · glimmer-setup (khoảng 1 phút sau khi cắm điện). '
                'Android sẽ hỏi bạn xác nhận kết nối.');
        if (!await PhoneWifi.ensurePermissions()) {
          throw Exception('Cần quyền vị trí / thiết bị Wi-Fi lân cận để vào glimmer-setup.');
        }
        final s = await PhoneWifi.joinSetupAp();
        if (s == null) throw Exception('Không vào được glimmer-setup. Thiết bị có đang hiện màn cài đặt Wi-Fi không?');
        viaAp = true;
        api = DeviceApi(DeviceApi.setupApUrl, token: c.store.token);
      }
      _say('Gửi "$ssid" cho thiết bị…');
      try {
        await api.saveSettings({'wifiSSID': ssid, 'wifiPass': _pass.text}, restart: true);
      } on DeviceException catch (e) {
        if (e.status != 0) rethrow; // 0: it rebooted before answering — fine
      } finally {
        api.close();
      }
      if (viaAp) await PhoneWifi.leaveSetupAp();

      // 3. Find it on the new network.
      _say('Chờ thiết bị vào "$ssid"…', 'Có thể mất tới 4 phút. Điện thoại cần ở cùng mạng này.');
      c.forget();
      await Future<void>.delayed(const Duration(seconds: 15));
      final end = DateTime.now().add(const Duration(minutes: 4));
      var ok = false;
      while (!ok && DateTime.now().isBefore(end)) {
        ok = await c.discover();
        if (!ok) await Future<void>.delayed(const Duration(seconds: 8));
      }
      if (!ok) {
        throw Exception('Chưa thấy thiết bị trên "$ssid". Sai mật khẩu, mạng chỉ có 5 GHz, '
            'hoặc mạng phải đăng nhập web — khi đó thiết bị sẽ lại hiện glimmer-setup.');
      }
      setState(() => _step = _Step.done);
      _say('Xong! Thiết bị đã vào "$ssid".', 'IP ${c.state?.ip ?? ''}');
    } catch (e) {
      if (viaAp) await PhoneWifi.leaveSetupAp();
      setState(() => _step = _Step.failed);
      _say('Chưa xong', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _step == _Step.working;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Cài Wi-Fi cho thiết bị')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Center(
            child: Clawd(
              mood: switch (_step) {
                _Step.done => ClawdMood.happy,
                _Step.failed => ClawdMood.sad,
                _ => ClawdMood.open,
              },
              walking: busy,
              size: 120,
            ),
          ),
          const SizedBox(height: 20),
          if (_step == _Step.form) ...[
            const Text(
                'Thiết bị chỉ nhớ một mạng, chỉ dùng Wi-Fi 2,4 GHz và không vào được mạng phải đăng nhập '
                'qua trang web (khách sạn, sân bay). Khi đó hãy dùng hotspot điện thoại.',
                style: T.label),
            const SizedBox(height: 16),
            TextField(controller: _ssid, decoration: const InputDecoration(labelText: 'Tên Wi-Fi (SSID)')),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              obscureText: !_show,
              decoration: InputDecoration(
                labelText: 'Mật khẩu (để trống nếu mạng mở)',
                suffixIcon: IconButton(
                  icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _show = !_show),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: _run, icon: const Icon(Icons.send), label: const Text('Gửi cho thiết bị')),
          ] else ...[
            Text(_status, textAlign: TextAlign.center, style: T.h(switch (_step) {
              _Step.done => G.mint,
              _Step.failed => G.coral,
              _ => G.ink,
            })),
            const SizedBox(height: 10),
            Text(_detail, textAlign: TextAlign.center, style: T.body),
            const SizedBox(height: 24),
            if (busy) const Center(child: CircularProgressIndicator()),
            if (_step == _Step.failed)
              FilledButton(onPressed: () => setState(() => _step = _Step.form), child: const Text('Thử lại')),
            if (_step == _Step.done)
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Xong')),
          ],
        ]),
      ),
    );
  }
}
