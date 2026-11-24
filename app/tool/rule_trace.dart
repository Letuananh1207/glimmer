// Truy vết quy tắc nghiệp vụ ↔ test: đọc bảng mã `R-…` ở docs/testing/quy_tac.md, dò mã trong test/, integration_test/,
// supabase/tests/. Quy tắc app đã đúng (`ok`, `tk`) mà chưa có test nào → báo và thoát mã 1.
// Quy tắc `sửa` chỉ liệt kê (test viết trước khi sửa app — đỏ tới khi sửa xong). Ô App ghi "miễn test" → bỏ qua.
//
//   dart tool/rule_trace.dart        tóm tắt + quy tắc ok thiếu test
//   dart tool/rule_trace.dart -v     kèm số test của từng mã

import 'dart:io';

final _code = RegExp(r'R-[A-Z]+-\d+');

void main(List<String> args) {
  final verbose = args.contains('-v');
  final book = File('docs/testing/quy_tac.md');
  if (!book.existsSync()) {
    stdout.writeln('rule_trace: chưa có docs/testing/quy_tac.md');
    return;
  }
  final rules = _readRules(book);
  final hits = <String, int>{};
  for (final dir in ['test', 'integration_test', 'supabase/tests']) {
    final d = Directory(dir);
    if (!d.existsSync()) continue;
    for (final f in d.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('_test.dart') && !f.path.endsWith('.sql')) continue;
      for (final m in _code.allMatches(f.readAsStringSync())) {
        hits[m[0]!] = (hits[m[0]!] ?? 0) + 1;
      }
    }
  }

  // `tk` cũng là app đã đúng (chỉ thiết kế ghi sai) → cũng phải có test.
  final missing = [
    for (final r in rules)
      if ((r.status == 'ok' || r.status == 'tk') && (hits[r.code] ?? 0) == 0) r.code,
  ];
  final toFix = [for (final r in rules) if (r.status == 'sửa') r.code];
  final unknown = hits.keys.where((c) => !rules.any((r) => r.code == c)).toList()..sort();
  final counts = {for (final s in ['ok', 'sửa', 'tk', 'miễn']) s: rules.where((r) => r.status == s).length};

  stdout.writeln('quy tắc: ${rules.length} (ok ${counts['ok']} · sửa ${counts['sửa']} · tk ${counts['tk']} · '
      'miễn test ${counts['miễn']}) · ok + tk có test: '
      '${counts['ok']! + counts['tk']! - missing.length}/${counts['ok']! + counts['tk']!}');
  if (verbose) {
    for (final r in rules) {
      stdout.writeln('  ${r.code.padRight(9)} ${r.status.padRight(4)} ${hits[r.code] ?? 0}');
    }
  }
  if (toFix.isNotEmpty) stdout.writeln('chờ sửa app: ${toFix.join(' ')}');
  if (unknown.isNotEmpty) stdout.writeln('mã trong test không có ở quy_tac.md: ${unknown.join(' ')}');
  if (missing.isNotEmpty) {
    stdout.writeln('THIẾU TEST (quy tắc app đã đúng): ${missing.join(' ')}');
    exit(1);
  }
}

/// Dòng bảng `| R-… | quy tắc | ví dụ | App |`; trạng thái lấy từ chữ đầu ô App (`ok`, `sửa`, `tk`), "miễn test" → `miễn`.
List<({String code, String status})> _readRules(File f) => [
  for (final line in f.readAsLinesSync())
    if (RegExp(r'^\|\s*(R-[A-Z]+-\d+)\s*\|').firstMatch(line) case final m?)
      (code: m[1]!, status: _status(line.split('|').reversed.elementAt(1).trim())),
];

String _status(String app) {
  if (app.contains('miễn test')) return 'miễn';
  for (final s in ['sửa', 'tk', 'ok']) {
    if (app.startsWith(s)) return s;
  }
  return '?';
}
