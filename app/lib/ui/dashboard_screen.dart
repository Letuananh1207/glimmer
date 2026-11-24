import 'package:flutter/material.dart';

import '../api/device_api.dart';
import '../api/models.dart' as m;
import '../app_controller.dart';
import 'clawd.dart';
import 'theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen(this.c, {super.key});
  final AppController c;

  Future<void> _act(BuildContext context, Future<void> Function(DeviceApi) f, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await f(c.api!);
      messenger.showSnackBar(SnackBar(content: Text(done)));
      await c.refresh();
    } on DeviceException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = c.state;
    if (s == null) return const Center(child: CircularProgressIndicator());
    final shown = s.projects.where((p) => p.shown).toList()
      ..sort((a, b) => _rank(a.state).compareTo(_rank(b.state)));
    final mood = moodFor([for (final p in shown) p.state]);
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        _Header(s, mood, walking: shown.any((p) => p.state == 'working')),
        if (c.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(c.error!, style: const TextStyle(color: G.amber, fontSize: 12)),
          ),
        if (s.inSetupMode)
          const _Note('Thiết bị đang ở chế độ cài đặt Wi-Fi (glimmer-setup). Vào tab Thiết bị → Wi-Fi.'),
        _UsageCard(s),
        _ProjectsCard(shown, onClear: () => _act(context, (a) => a.clearProjects(), 'Đã xóa bảng project')),
        _CardsCard(c.cards,
            onClear: (id) => _act(context, (a) => a.clearCard(id), 'Đã xóa thẻ'),
            onClearAll: () => _act(context, (a) => a.clearAllCards(), 'Đã xóa mọi thẻ')),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            FilledButton.tonalIcon(
              onPressed: () => _act(context, (a) => a.refreshNow(), 'Thiết bị đang tải số liệu mới'),
              icon: const Icon(Icons.refresh),
              label: const Text('Tải số liệu ngay'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _act(context, (a) => a.showChannel('Claude'), 'Đã chuyển sang màn Claude'),
              icon: const Icon(Icons.tv),
              label: const Text('Hiện màn Claude'),
            ),
          ]),
        ),
      ]),
    );
  }

  static int _rank(String s) => const ['approval', 'input', 'error', 'working', 'done'].indexOf(s);
}

class _Header extends StatelessWidget {
  const _Header(this.s, this.mood, {required this.walking});
  final m.DeviceState s;
  final ClawdMood mood;
  final bool walking;

  @override
  Widget build(BuildContext context) {
    final online = !s.inSetupMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        Clawd(mood: mood, walking: walking, size: 72),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('glimmer', style: T.h(G.ink).copyWith(fontSize: 20)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.circle, size: 9, color: online ? G.mint : G.amber),
              const SizedBox(width: 6),
              Flexible(
                child: Text(online ? '${s.ssid} · ${s.ip}' : 'chế độ cài đặt · ${s.ip}',
                    style: T.label, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Card(
        color: G.panel2,
        child: Padding(padding: const EdgeInsets.all(14), child: Text(text, style: const TextStyle(color: G.amber))),
      );
}

class _UsageCard extends StatelessWidget {
  const _UsageCard(this.s);
  final m.DeviceState s;

  @override
  Widget build(BuildContext context) {
    final u = s.usage;
    String meta;
    Color metaColor = G.muted;
    if (!s.claudeConfigured) {
      meta = 'chưa có khóa Claude — thêm trong Cài đặt';
      metaColor = G.amber;
    } else if (u.cred == 'expired' || u.cred == 'rejected') {
      meta = 'khóa Claude lỗi — cập nhật trong Cài đặt';
      metaColor = G.coral;
    } else if (u.cred == 'blocked') {
      meta = 'claude.ai đang chặn thiết bị — tự thử lại';
      metaColor = G.amber;
    } else if (u.stale) {
      meta = 'số liệu cũ (${ago(s.time - u.lastOk)} trước)';
      metaColor = G.amber;
    } else {
      meta = u.lastOk > 0 && s.clockSynced ? '${ago(s.time - u.lastOk)} trước' : '';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('MỨC DÙNG CLAUDE', style: T.label),
            const Spacer(),
            Flexible(child: Text(meta, style: T.label.copyWith(color: metaColor), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 14),
          _UsageRow('Tuần', u.weeklyUsed, countdown(u.weeklyReset, s.time), big: true, dim: u.stale),
          const SizedBox(height: 14),
          _UsageRow('Phiên 5 giờ', u.sessionUsed, countdown(u.sessionReset, s.time), dim: u.stale),
        ]),
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow(this.label, this.used, this.left, {this.big = false, this.dim = false});
  final String label, left;
  final int used;
  final bool big, dim;

  @override
  Widget build(BuildContext context) {
    final color = dim ? G.muted : G.usage(used);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(used < 0 ? '--' : '$used', style: TextStyle(fontSize: big ? 40 : 24, fontWeight: FontWeight.w700, color: color)),
        Text('%', style: TextStyle(fontSize: big ? 20 : 14, color: color)),
        const SizedBox(width: 10),
        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(label, style: T.body)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(left == '--' ? '' : 'đặt lại sau $left', style: T.label.copyWith(color: G.inkDim)),
        ),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: used < 0 ? 0 : used / 100,
          minHeight: big ? 8 : 5,
          backgroundColor: G.panel2,
          color: color,
        ),
      ),
    ]);
  }
}

class _ProjectsCard extends StatelessWidget {
  const _ProjectsCard(this.projects, {required this.onClear});
  final List<m.Project> projects;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('PROJECT', style: T.label),
            const Spacer(),
            if (projects.isNotEmpty)
              TextButton(onPressed: onClear, child: const Text('Xóa bảng', style: TextStyle(fontSize: 12))),
          ]),
          if (projects.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('Chưa có hoạt động. Hook của Claude Code sẽ gửi trạng thái lên đây.', style: T.body),
            ),
          for (final p in projects)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.square, size: 12, color: G.state(p.state)),
              minLeadingWidth: 12,
              title: Text(p.project, style: const TextStyle(color: G.ink)),
              subtitle: Text(
                [G.stateLabel(p.state), if (p.detail.isNotEmpty) p.detail, if (p.agent != 'claude') p.agent].join(' · '),
                style: TextStyle(color: G.state(p.state), fontSize: 12),
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(ago(p.ageS), style: T.label),
              ),
            ),
        ]),
      ),
    );
  }
}

class _CardsCard extends StatelessWidget {
  const _CardsCard(this.cards, {required this.onClear, required this.onClearAll});
  final List<m.Card> cards;
  final void Function(String id) onClear;
  final VoidCallback onClearAll;

  static String _kind(String k) => switch (k) {
        'approval' => 'Cần duyệt',
        'input' => 'Chờ bạn',
        'success' => 'Xong',
        'error' => 'Lỗi',
        'progress' => 'Tiến độ',
        'warning' => 'Cảnh báo',
        _ => 'Thông tin',
      };

  static Color _color(String k) => switch (k) {
        'approval' || 'warning' => G.amber,
        'input' => G.sky,
        'success' => G.mint,
        'error' => G.coral,
        'progress' => G.lilac,
        _ => G.ink,
      };

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('THẺ TRÊN MÀN HÌNH', style: T.label),
            const Spacer(),
            TextButton(onPressed: onClearAll, child: const Text('Xóa hết', style: TextStyle(fontSize: 12))),
          ]),
          for (final k in cards)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(k.title.isEmpty ? _kind(k.kind) : k.title, style: TextStyle(color: _color(k.kind))),
              subtitle: Text(
                [_kind(k.kind), if (k.project.isNotEmpty) k.project, if (k.body.isNotEmpty) k.body, '${ago(k.ageS)} trước']
                    .join(' · '),
                style: T.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => onClear(k.id)),
            ),
        ]),
      ),
    );
  }
}
