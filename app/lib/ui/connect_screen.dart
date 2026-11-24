import 'package:flutter/material.dart';

import '../app_controller.dart';
import 'clawd.dart';
import 'theme.dart';
import 'wifi_setup_screen.dart';

/// Shown until a display answers.
class ConnectScreen extends StatelessWidget {
  const ConnectScreen(this.c, {super.key});
  final AppController c;

  Future<void> _manual(BuildContext context) async {
    final ip = TextEditingController(text: c.store.deviceUrl.replaceFirst('http://', ''));
    final token = TextEditingController(text: c.store.token);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập địa chỉ thiết bị'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('IP hiện trên kênh Thông tin của thiết bị, ví dụ 192.168.1.50.', style: T.label),
          const SizedBox(height: 12),
          TextField(controller: ip, decoration: const InputDecoration(labelText: 'Địa chỉ IP')),
          const SizedBox(height: 12),
          TextField(
              controller: token,
              decoration: const InputDecoration(labelText: 'API token (nếu có)'),
              obscureText: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kết nối')),
        ],
      ),
    );
    if (ok == true) await c.connectTo(ip.text, token: token.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Spacer(),
            Center(child: Clawd(mood: c.searching ? ClawdMood.open : ClawdMood.sleep, walking: c.searching, size: 144)),
            const SizedBox(height: 28),
            Text(c.searching ? 'Đang tìm thiết bị…' : 'Chưa kết nối',
                textAlign: TextAlign.center, style: T.h(G.ink).copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              c.searching
                  ? 'Tìm glimmer trên mạng Wi-Fi của điện thoại.'
                  : (c.error ?? 'Điện thoại cần ở cùng mạng Wi-Fi với thiết bị.'),
              textAlign: TextAlign.center,
              style: T.body,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: c.searching ? null : c.discover,
              icon: const Icon(Icons.search),
              label: const Text('Tìm lại'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: c.searching ? null : () => _manual(context),
              icon: const Icon(Icons.edit),
              label: const Text('Nhập địa chỉ IP'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: c.searching
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WifiSetupScreen(c))),
              icon: const Icon(Icons.wifi),
              label: const Text('Thiết bị mới / đang hiện glimmer-setup'),
            ),
          ]),
        ),
      ),
    );
  }
}
