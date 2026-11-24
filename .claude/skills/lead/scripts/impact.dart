// Dò phạm vi ảnh hưởng cho /lead — in gọn, ít token.
//
//   dart .claude/skills/lead/scripts/impact.dart <từ khoá|đường dẫn>... [--depth N]
//
// 1. Điểm khởi đầu: file có đường dẫn chứa từ khoá + node của đồ thị
//    understand-anything (.ua/ hoặc .understand-anything/) có tên/tóm tắt/tag khớp.
// 2. Ảnh hưởng ngược: tính trực tiếp từ import/export/part trong lib/ và test/
//    (luôn mới, không phụ thuộc đồ thị cũ).
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  var depth = 2;
  final terms = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--depth' && i + 1 < args.length) {
      depth = int.parse(args[++i]);
    } else {
      terms.add(args[i].replaceAll('\\', '/').toLowerCase());
    }
  }
  if (terms.isEmpty) {
    stderr.writeln('Cần ít nhất một từ khoá hoặc đường dẫn.');
    exit(64);
  }

  final pkg = RegExp(r'^name:\s*(\S+)', multiLine: true)
      .firstMatch(File('pubspec.yaml').readAsStringSync())!
      .group(1)!;
  final files = [
    for (final dir in ['lib', 'test', 'testing'])
      if (Directory(dir).existsSync())
        ...Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .map((f) => f.path.replaceAll('\\', '/'))
            .where((p) => p.endsWith('.dart') && !_generated(p)),
  ]..sort();
  final known = files.toSet();

  // Đồ thị import: file → các file nó dùng; và chiều ngược.
  final directive =
      RegExp(r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''', multiLine: true);
  final usedBy = <String, Set<String>>{};
  for (final f in files) {
    for (final m in directive.allMatches(File(f).readAsStringSync())) {
      final target = _resolve(m.group(1)!, f, pkg);
      if (target != null && known.contains(target)) {
        usedBy.putIfAbsent(target, () => {}).add(f);
      }
    }
  }

  // Điểm khởi đầu.
  final seeds = <String, String>{}; // file → lý do
  for (final f in files) {
    final hit = terms.where((t) => f.toLowerCase().contains(t));
    if (hit.isNotEmpty) seeds[f] = 'đường dẫn ~ ${hit.join(', ')}';
  }
  final graphNotes = _fromGraph(terms, known, seeds);

  if (seeds.isEmpty) {
    print('Không tìm thấy file khớp: ${terms.join(', ')}');
    print('→ thử từ khoá khác (tên tiếng Anh trong code) hoặc grep.');
    graphNotes.forEach(print);
    return;
  }

  final libSeeds = seeds.keys.where((f) => !f.startsWith('test/')).toList();
  final testSeeds = seeds.keys.where((f) => f.startsWith('test/')).toList();

  print('## Điểm khởi đầu (${seeds.length})');
  for (final f in [...libSeeds, ...testSeeds].take(30)) {
    print('- $f  [${seeds[f]}]');
  }
  if (seeds.length > 30) print('- … và ${seeds.length - 30} file nữa — thu hẹp từ khoá');

  // Lan ngược theo tầng.
  final seen = {...seeds.keys};
  var frontier = libSeeds.toSet();
  final tests = <String>{...testSeeds};
  for (var level = 1; level <= depth && frontier.isNotEmpty; level++) {
    final next = <String>{};
    for (final f in frontier) {
      for (final user in usedBy[f] ?? const <String>{}) {
        if (user.startsWith('test/') || user.startsWith('testing/')) {
          tests.add(user);
        } else if (seen.add(user)) {
          next.add(user);
        }
      }
    }
    if (next.isNotEmpty) {
      print('\n## Dùng các file trên — tầng $level (${next.length})');
      final list = next.toList()..sort();
      for (final f in list.take(40)) {
        print('- $f');
      }
      if (list.length > 40) {
        print('- … và ${list.length - 40} file nữa (file dùng chung — kiểm tra theo mẫu, không đọc hết)');
      }
    }
    frontier = next;
  }

  if (tests.isNotEmpty) {
    final list = tests.toList()..sort();
    print('\n## Test liên quan (${list.length})');
    for (final f in list.take(30)) {
      print('- $f');
    }
    if (list.length > 30) print('- … và ${list.length - 30} file nữa');
  }
  if (graphNotes.isNotEmpty) {
    print('');
    graphNotes.forEach(print);
  }
}

bool _generated(String p) =>
    p.endsWith('.g.dart') ||
    p.endsWith('.freezed.dart') ||
    p.startsWith('lib/l10n/app_localizations') ||
    p.endsWith('app_colors.dart');

String? _resolve(String uri, String from, String pkg) {
  if (uri.startsWith('package:$pkg/')) {
    return 'lib/${uri.substring('package:$pkg/'.length)}';
  }
  if (uri.contains(':')) return null;
  final parts = from.split('/')..removeLast();
  for (final seg in uri.split('/')) {
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (seg != '.') {
      parts.add(seg);
    }
  }
  return parts.join('/');
}

/// Thêm điểm khởi đầu từ đồ thị; trả về các dòng ghi chú (độ mới, node khái niệm).
List<String> _fromGraph(
    List<String> terms, Set<String> known, Map<String, String> seeds) {
  final dir = Directory('.understand-anything').existsSync()
      ? '.understand-anything'
      : '.ua';
  final file = File('$dir/knowledge-graph.json');
  if (!file.existsSync()) {
    return ['_Chưa có đồ thị understand-anything — chỉ dò theo đường dẫn. Chạy /understand để tìm theo nghĩa._'];
  }
  final notes = <String>[];
  final graph = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  final commit = (graph['project'] as Map?)?['gitCommitHash'] as String?;
  if (commit != null) {
    final r = Process.runSync(
        'git', ['diff', '--name-only', commit, 'HEAD', '--', 'lib', 'test']);
    if (r.exitCode == 0) {
      final changed =
          (r.stdout as String).split('\n').where((l) => l.trim().isNotEmpty).length;
      if (changed > 0) {
        notes.add('_Đồ thị cũ: $changed file trong lib/test đã đổi từ ${commit.substring(0, 7)} — tóm tắt có thể lệch; quan hệ import ở trên vẫn mới. Nên chạy /understand khi tiện._');
      }
    }
  }

  // Khớp ở tên/tag → điểm khởi đầu (được lan ngược). Chỉ khớp trong tóm tắt
  // → "có nhắc tới", liệt kê riêng, không lan, để danh sách không phình.
  final concepts = <String>[];
  final mentions = <String>{};
  for (final n in (graph['nodes'] as List).cast<Map<String, dynamic>>()) {
    final strong = [n['name'], ...?(n['tags'] as List?)]
        .whereType<String>()
        .join(' ')
        .toLowerCase();
    final summary = ((n['summary'] as String?) ?? '').toLowerCase();
    final hit = terms.where(strong.contains).toList();
    final weak = hit.isEmpty && terms.any(summary.contains);
    if (hit.isEmpty && !weak) continue;
    final path = (n['filePath'] as String?)?.replaceAll('\\', '/');
    if (path != null && known.contains(path)) {
      if (hit.isNotEmpty) {
        seeds.putIfAbsent(path, () => 'đồ thị: ${n['type']} "${n['name']}"');
      } else {
        mentions.add(path);
      }
    } else if (path == null && concepts.length < 8) {
      concepts.add('- ${n['type']} "${n['name']}": ${n['summary'] ?? ''}');
    }
  }
  mentions.removeAll(seeds.keys);
  if (mentions.isNotEmpty) {
    final list = mentions.toList()..sort();
    notes.add('## Có nhắc tới trong tóm tắt (không lan — mở khi cần) (${list.length})');
    notes.addAll(list.take(20).map((p) => '- $p'));
    if (list.length > 20) notes.add('- … và ${list.length - 20} file nữa');
  }
  if (concepts.isNotEmpty) {
    notes.add('## Khái niệm/luồng trong đồ thị');
    notes.addAll(concepts);
  }
  return notes;
}
