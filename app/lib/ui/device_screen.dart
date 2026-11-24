import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../api/device_api.dart';
import '../app_controller.dart';
import '../services/releases.dart';
import '../services/wifi.dart';
import 'theme.dart';
import 'wifi_setup_screen.dart';

/// Device info, Wi-Fi, firmware updates, config backup/restore, reboot.
class DeviceScreen extends StatefulWidget {
  const DeviceScreen(this.c, {super.key});
  final AppController c;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  Release? _release;
  String? _releaseError;
  String? _busy; // what a long operation is doing, null when idle
  double? _progress;

  AppController get c => widget.c;

  @override
  void initState() {
    super.initState();
    _checkRelease();
  }

  Future<void> _checkRelease() async {
    try {
      final r = await Releases.latest(c.store.repo);
      if (mounted) setState(() => _release = r);
    } catch (e) {
      if (mounted) setState(() => _releaseError = e.toString().replaceFirst(RegExp(r'^\w+Exception: '), ''));
    }
  }

  void _step(String? what, [double? p]) {
    if (mounted) {
      setState(() {
        _busy = what;
        _progress = p;
      });
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<bool> _confirm(String title, String body, String ok) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok)),
          ],
        ),
      ) ==
      true;

  bool get _updateAvailable {
    final b = c.state?.buildTime, r = _release;
    // CI stamps its build a few minutes before publishing; allow 30 min of slack.
    return b != null && r != null && r.published.isAfter(b.add(const Duration(minutes: 30)));
  }

  // ── backup ──
  Future<File> _saveBackup(Map<String, dynamic> cfg) async {
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 16).replaceAll(':', '');
    final f = File('${dir.path}/glimmer-config-$stamp.json');
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(cfg));
    return f;
  }

  Future<void> _backup() async {
    if (!await _confirm('Sao lưu cấu hình',
        'Tệp chứa mật khẩu Wi-Fi và khóa Claude ở dạng chữ thường. Chỉ lưu ở nơi an toàn.', 'Sao lưu')) {
      return;
    }
    try {
      final f = await _saveBackup(await c.api!.exportConfig());
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], text: 'Cấu hình glimmer'));
    } catch (e) {
      _toast('Sao lưu lỗi: $e');
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (picked.isEmpty) return;
    final file = picked.first;
    Map<String, dynamic> cfg;
    try {
      final bytes = await file.xFile.readAsBytes();
      cfg = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (cfg['wifi_ssid'] == null) throw const FormatException('không phải tệp cấu hình glimmer');
    } catch (e) {
      _toast('Tệp không hợp lệ: $e');
      return;
    }
    if (!await _confirm('Khôi phục cấu hình', 'Thay toàn bộ cấu hình thiết bị bằng tệp "${file.name}"? '
        'Thiết bị sẽ khởi động lại.', 'Khôi phục')) {
      return;
    }
    await _importConfig(cfg);
  }

  /// Import a config: directly when reachable, else through glimmer-setup.
  Future<bool> _importConfig(Map<String, dynamic> cfg) async {
    var viaAp = false;
    try {
      var api = c.api;
      if (api == null || await api.probe() == null) {
        _step('Vào Wi-Fi glimmer-setup để khôi phục…');
        if (!await PhoneWifi.ensurePermissions() || await PhoneWifi.joinSetupAp() == null) {
          throw Exception('không vào được glimmer-setup');
        }
        viaAp = true;
        api = DeviceApi(DeviceApi.setupApUrl, token: c.store.token);
      }
      _step('Gửi cấu hình…');
      try {
        await api.importConfig(cfg);
      } on DeviceException catch (e) {
        if (e.status != 0) rethrow;
      }
      if (viaAp) {
        api.close();
        await PhoneWifi.leaveSetupAp();
      }
      _step('Chờ thiết bị khởi động lại…');
      c.forget();
      await Future<void>.delayed(const Duration(seconds: 15));
      for (var i = 0; i < 20 && !await c.discover(); i++) {
        await Future<void>.delayed(const Duration(seconds: 6));
      }
      _toast(c.connected ? 'Đã khôi phục cấu hình' : 'Đã gửi cấu hình; chưa thấy thiết bị trên mạng');
      return true;
    } catch (e) {
      if (viaAp) await PhoneWifi.leaveSetupAp();
      _toast('Khôi phục lỗi: $e');
      return false;
    } finally {
      _step(null);
    }
  }

  // ── updates ──
  Future<Uint8List> _download(String name) async {
    final url = _release?.assets[name];
    if (url == null) throw Exception('bản phát hành không có $name');
    return Releases.download(url, onProgress: (p) => _step('Tải $name…', p));
  }

  /// Firmware only: keeps the filesystem (config, fonts, history).
  Future<void> _updateFirmware() async {
    if (!await _confirm('Cập nhật firmware',
        'Tải firmware mới nhất từ ${c.store.repo} và nạp qua Wi-Fi. Cấu hình được giữ nguyên.', 'Cập nhật')) {
      return;
    }
    try {
      final fw = await _download('firmware.bin');
      await c.api!.upload('firmware', fw, onProgress: (p) => _step('Nạp firmware…', p));
      _step('Thiết bị đang khởi động lại…');
      final s = await c.api!.waitOnline();
      _toast(s == null ? 'Đã nạp; chưa thấy thiết bị trả lời' : 'Xong — firmware ${s.fw}');
      await c.refresh();
    } catch (e) {
      _toast('Cập nhật lỗi: $e');
    } finally {
      _step(null);
    }
  }

  /// Firmware + filesystem (fonts, web UI). The filesystem image carries no
  /// config, so: back it up, flash both, then restore it through the setup
  /// AP the device opens when it finds no config.
  Future<void> _updateFull() async {
    if (!await _confirm(
        'Cập nhật đầy đủ',
        'Nạp firmware và hệ thống tệp (font, giao diện web). Ứng dụng sẽ sao lưu cấu hình, nạp, rồi tự '
            'khôi phục qua Wi-Fi glimmer-setup (Android sẽ hỏi xác nhận). Lịch sử mức dùng 7 ngày bị xóa.',
        'Bắt đầu')) {
      return;
    }
    try {
      _step('Sao lưu cấu hình…');
      final cfg = await c.api!.exportConfig();
      if (cfg['wifi_ssid'] == null) throw Exception('không đọc được cấu hình để sao lưu');
      final backup = await _saveBackup(cfg);
      final fw = await _download('firmware.bin');
      final fs = await _download('littlefs.bin');
      await c.api!.upload('firmware', fw, onProgress: (p) => _step('Nạp firmware…', p));
      _step('Chờ thiết bị khởi động lại…');
      if (await c.api!.waitOnline() == null) throw Exception('thiết bị không trả lời sau khi nạp firmware');
      await c.api!.upload('filesystem', fs, onProgress: (p) => _step('Nạp hệ thống tệp…', p));
      _step('Thiết bị chuyển sang glimmer-setup…');
      await Future<void>.delayed(const Duration(seconds: 20));
      if (!await _importConfig(cfg)) {
        _toast('Chưa khôi phục được. Bản sao lưu: ${backup.path}');
      }
    } catch (e) {
      _toast('Cập nhật lỗi: $e');
    } finally {
      _step(null);
    }
  }

  Future<void> _reboot() async {
    if (!await _confirm('Khởi động lại', 'Thiết bị sẽ tắt màn hình vài giây rồi bật lại.', 'Khởi động lại')) {
      return;
    }
    await c.api!.reboot();
    _step('Đang khởi động lại…');
    await c.api!.waitOnline();
    _step(null);
    await c.refresh();
  }

  String _fmt(DateTime? d) => d == null
      ? '?'
      : '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = c.state;
    if (s == null) return const Center(child: CircularProgressIndicator());
    final busy = _busy != null;
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      if (busy)
        Card(
          color: G.panel2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_busy!, style: T.h(G.ink)),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 6),
              const Text('Đừng tắt ứng dụng hay rút điện thiết bị.', style: T.label),
            ]),
          ),
        ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('THIẾT BỊ', style: T.label),
            const SizedBox(height: 8),
            _kv('Firmware', s.fw),
            _kv('Bản build', _fmt(s.buildTime)),
            _kv('Wi-Fi', s.inSetupMode ? 'chế độ cài đặt' : '${s.ssid} (${s.rssi} dBm)'),
            _kv('IP', s.ip),
            _kv('Đã chạy', ago(s.uptimeS)),
            _kv('Bộ nhớ trống', '${s.heap ~/ 1024} KB (khối lớn nhất ${s.maxBlock ~/ 1024} KB)'),
          ]),
        ),
      ),
      Card(
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.wifi),
            title: const Text('Đổi Wi-Fi cho thiết bị'),
            subtitle: const Text('Khi chuyển nhà / nơi làm', style: T.label),
            enabled: !busy,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WifiSetupScreen(c))),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Khởi động lại'),
            enabled: !busy,
            onTap: _reboot,
          ),
          ListTile(
            leading: const Icon(Icons.link_off),
            title: const Text('Kết nối thiết bị khác'),
            enabled: !busy,
            onTap: c.forget,
          ),
        ]),
      ),
      Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('CẬP NHẬT', style: T.label),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _release == null
                  ? (_releaseError ?? 'Đang kiểm tra bản mới…')
                  : 'Bản mới nhất: ${_fmt(_release!.published)}${_release!.commit.isEmpty ? '' : ' · ${_release!.commit}'}\n'
                      '${_updateAvailable ? 'Có bản mới hơn thiết bị.' : 'Thiết bị có vẻ đã cập nhật.'}',
              style: TextStyle(color: _updateAvailable ? G.mint : G.inkDim, fontSize: 13),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('Cập nhật firmware'),
            subtitle: const Text('Giữ nguyên cấu hình và lịch sử', style: T.label),
            enabled: !busy && _release != null,
            onTap: _updateFirmware,
          ),
          ListTile(
            leading: const Icon(Icons.layers),
            title: const Text('Cập nhật đầy đủ'),
            subtitle: const Text('Kèm font + giao diện web; tự sao lưu và khôi phục cấu hình', style: T.label),
            enabled: !busy && _release != null,
            onTap: _updateFull,
          ),
        ]),
      ),
      Card(
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('Sao lưu cấu hình'),
            subtitle: const Text('Có mật khẩu Wi-Fi và khóa — giữ kín', style: T.label),
            enabled: !busy,
            onTap: _backup,
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore),
            title: const Text('Khôi phục cấu hình'),
            enabled: !busy,
            onTap: _restore,
          ),
        ]),
      ),
    ]);
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 120, child: Text(k, style: T.label)),
          Expanded(child: Text(v, style: const TextStyle(color: G.ink, fontSize: 13))),
        ]),
      );
}
