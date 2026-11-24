import 'package:flutter/material.dart';

import '../api/device_api.dart';
import '../app_controller.dart';
import 'theme.dart';

/// Device settings (GET/POST /api/settings, camelCase keys). Only changed
/// keys are sent; secrets come back masked as "***" and are sent only when
/// the user types a new value.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen(this.c, {super.key});
  final AppController c;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _orig;
  final Map<String, dynamic> _edit = {};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await widget.c.api!.settings();
      setState(() {
        _orig = s;
        _edit.clear();
        _error = null;
      });
    } on DeviceException catch (e) {
      setState(() => _error = e.message);
    }
  }

  V _v<V>(String k, V d) {
    final v = _edit.containsKey(k) ? _edit[k] : _orig?[k];
    if (v is V) return v;
    if (d is int && v is num) return v.toInt() as V;
    if (d is double && v is num) return v.toDouble() as V;
    return d;
  }

  void _set(String k, Object v) => setState(() {
        if (_orig?[k] == v) {
          _edit.remove(k);
        } else {
          _edit[k] = v;
        }
      });

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.c.api!.saveSettings(Map.of(_edit));
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu')));
      await _load();
    } on DeviceException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _secret(String key, String title, String hint) async {
    final t = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(hint, style: T.label),
          const SizedBox(height: 12),
          TextField(controller: t, obscureText: true, autofocus: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, t.text.trim()), child: const Text('Đặt')),
        ],
      ),
    );
    if (v != null) _set(key, v);
  }

  String _hhmm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  Future<void> _pickTime(String key) async {
    final m = _v<int>(key, 0);
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
    if (t != null) _set(key, t.hour * 60 + t.minute);
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
        child: Text(title, style: T.label.copyWith(color: G.clawd)),
      );

  Widget _switch(String key, String title, [String? sub]) => SwitchListTile(
        title: Text(title),
        subtitle: sub == null ? null : Text(sub, style: T.label),
        value: _v<bool>(key, false),
        onChanged: (v) => _set(key, v),
      );

  Widget _choice(String key, String title, Map<int, String> options) => ListTile(
        title: Text(title),
        trailing: DropdownButton<int>(
          value: options.containsKey(_v<int>(key, options.keys.first)) ? _v<int>(key, options.keys.first) : null,
          items: [for (final e in options.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: (v) => v == null ? null : _set(key, v),
        ),
      );

  Widget _slider(String key, String title, int min, int max) {
    final v = _v<int>(key, min).clamp(min, max);
    return ListTile(
      title: Text('$title: $v%'),
      subtitle: Slider(
        value: v.toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: (max - min) ~/ 5,
        onChanged: (x) => _set(key, x.round()),
      ),
    );
  }

  Widget _secretTile(String key, String title, String hint) {
    final set = _edit.containsKey(key) || (_orig?[key] is String && (_orig![key] as String).isNotEmpty);
    return ListTile(
      title: Text(title),
      subtitle: Text(_edit.containsKey(key) ? 'sẽ đổi khi lưu' : (set ? 'đã đặt' : 'chưa đặt'), style: T.label),
      trailing: const Icon(Icons.edit, size: 18),
      onTap: () => _secret(key, title, hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_orig == null) {
      return Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!, style: T.body),
                TextButton(onPressed: _load, child: const Text('Thử lại')),
              ]),
      );
    }
    final night = _v<int>('nightMode', 0);
    return Stack(children: [
      ListView(padding: const EdgeInsets.only(bottom: 96), children: [
        _section('MÀN HÌNH'),
        _slider('brightness', 'Độ sáng', 5, 100),
        _switch('idleDim', 'Tự giảm sáng khi rảnh', '15 phút không có hoạt động agent → 15%'),
        _switch('claudeWeeklyHero', 'Số lớn là mức dùng tuần', 'tắt: số lớn là phiên 5 giờ'),
        _switch('clock24h', 'Đồng hồ 24 giờ'),
        _section('BAN ĐÊM'),
        _choice('nightMode', 'Chế độ', {0: 'Không', 1: 'Giảm sáng', 2: 'Đồng hồ', 3: 'Tắt màn'}),
        if (night != 0) ...[
          ListTile(
            title: const Text('Từ'),
            trailing: Text(_hhmm(_v<int>('nightStartMin', 1380))),
            onTap: () => _pickTime('nightStartMin'),
          ),
          ListTile(
            title: const Text('Đến'),
            trailing: Text(_hhmm(_v<int>('nightEndMin', 420))),
            onTap: () => _pickTime('nightEndMin'),
          ),
          if (night == 1) _slider('nightBright', 'Độ sáng ban đêm', 5, 100),
        ],
        _section('SỐ LIỆU CLAUDE'),
        _secretTile('claudeKey', 'Khóa Claude (sessionKey)', 'Dán sessionKey của claude.ai (bắt đầu bằng sk-ant-…).'),
        _choice('refreshMin', 'Tải số liệu mỗi', {1: '1 phút', 2: '2 phút', 3: '3 phút', 5: '5 phút', 10: '10 phút', 15: '15 phút'}),
        ListTile(
          title: const Text('Tên của bạn'),
          subtitle: Text(_v<String>('userName', '').isEmpty ? 'chưa đặt' : _v<String>('userName', ''), style: T.label),
          trailing: const Icon(Icons.edit, size: 18),
          onTap: () async {
            final t = TextEditingController(text: _v<String>('userName', ''));
            final v = await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Tên của bạn'),
                content: TextField(controller: t, maxLength: 16, autofocus: true),
                actions: [FilledButton(onPressed: () => Navigator.pop(ctx, t.text.trim()), child: const Text('Đặt'))],
              ),
            );
            if (v != null) _set('userName', v);
          },
        ),
        _section('AGENT'),
        _switch('showAgents', 'Màn danh sách tác tử', 'thẻ duyệt vẫn hiện khi tắt'),
        _switch('pinApprovals', 'Giữ thẻ duyệt tới khi trả lời'),
        _switch('agentDoneCards', 'Thẻ "xong" khi agent dừng'),
        _choice('approvalTtlMin', 'Bỏ thẻ chờ sau', {5: '5 phút', 15: '15 phút', 30: '30 phút', 60: '1 giờ', 0: 'Không bao giờ'}),
        _secretTile('apiToken', 'API token của thiết bị', 'Nếu đặt, hook / app phải gửi kèm token này. Để trống để bỏ.'),
        ListTile(
          title: const Text('Token app đang dùng'),
          subtitle: Text(widget.c.store.token.isEmpty ? 'không có' : 'đã lưu', style: T.label),
          trailing: const Icon(Icons.key, size: 18),
          onTap: () async {
            final t = TextEditingController(text: widget.c.store.token);
            final v = await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Token cho app'),
                content: TextField(controller: t, obscureText: true),
                actions: [FilledButton(onPressed: () => Navigator.pop(ctx, t.text), child: const Text('Lưu'))],
              ),
            );
            if (v != null) {
              widget.c.setToken(v);
              setState(() {});
            }
          },
        ),
      ]),
      if (_edit.isNotEmpty)
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => setState(_edit.clear),
                child: const Text('Bỏ thay đổi'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Đang lưu…' : 'Lưu (${_edit.length})'),
              ),
            ),
          ]),
        ),
    ]);
  }
}
