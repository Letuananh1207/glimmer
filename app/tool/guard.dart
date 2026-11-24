// Chốt chặn tự động trên các file đổi so với HEAD (kể cả file mới):
//   1. dart tool/check.dart --changed  — quy tắc lớp của bộ chuẩn flutter-dev
//   2. dart analyze                    — lỗi biên dịch trong file Dart đã đổi
// Chỉ chặn khi có lỗi (E… của check.dart, `error` của analyzer); cảnh báo cho qua.
//
//   dart tool/guard.dart stop        hook Stop của Claude Code (.claude/settings.json)
//   dart tool/guard.dart pre-commit  git pre-commit (tool/git_hooks/pre-commit)

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'pre-commit' : args.first;
  // Hook Stop đã chặn một lần mà vẫn lỗi → cho dừng, chỉ báo, để không lặp vô hạn.
  var retried = false;
  if (mode == 'stop') {
    try {
      final input = jsonDecode(await stdin.transform(utf8.decoder).join());
      retried = input is Map && input['stop_hook_active'] == true;
    } catch (_) {}
  }

  // Chưa có git → không biết file nào đổi; không chặn (kiểm tay: dart tool/check.dart).
  if (Process.runSync('git', ['rev-parse', '--is-inside-work-tree'], runInShell: true).exitCode != 0) {
    if (mode == 'stop' && !retried) {
      stdout.writeln(jsonEncode({'systemMessage': 'guard.dart: chưa có git — bỏ qua chốt chặn.'}));
    }
    exit(0);
  }

  final problems = <String>[..._runCheck(), ..._runAnalyze()];
  if (problems.isEmpty) exit(0);

  final report = 'Chốt chặn kiến trúc (tool/guard.dart) phát hiện lỗi:\n'
      '${problems.join('\n')}';
  if (mode == 'stop') {
    if (retried) {
      stdout.writeln(jsonEncode({
        'systemMessage': 'Vẫn còn lỗi kiến trúc/biên dịch — chạy '
            '`dart tool/guard.dart` để xem.',
      }));
      exit(0);
    }
    stderr.writeln('$report\nSửa các lỗi trên theo bộ chuẩn flutter-dev rồi mới báo xong.');
    exit(2);
  }
  stderr.writeln('$report\nCommit bị chặn. Bỏ qua tạm thời: git commit --no-verify');
  exit(1);
}

List<String> _runCheck() {
  final r = Process.runSync('dart', ['tool/check.dart', '--changed'],
      runInShell: true, stdoutEncoding: utf8, stderrEncoding: utf8);
  if (r.exitCode == 0) return const [];
  final out = (r.stdout as String).split('\n');
  // Giữ khối lỗi E…, bỏ khối cảnh báo W….
  final lines = <String>[];
  var inError = false;
  for (final l in out) {
    if (RegExp(r'^[EW]-').hasMatch(l)) inError = l.startsWith('E-');
    if (inError && l.trim().isNotEmpty) lines.add(l);
  }
  return lines.isEmpty ? ['check.dart thoát mã ${r.exitCode}:\n${r.stdout}${r.stderr}'] : lines;
}

List<String> _runAnalyze() {
  final files = _changedDart();
  if (files.isEmpty) return const [];
  final r = Process.runSync(
    'dart',
    ['analyze', '--no-fatal-warnings', ...files],
    runInShell: true,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (r.exitCode == 0) return const [];
  final errors = (r.stdout as String)
      .split('\n')
      .where((l) => l.trimLeft().startsWith('error'))
      .map((l) => 'analyze: ${l.trim()}')
      .toList();
  return errors.isEmpty ? ['dart analyze thoát mã ${r.exitCode}:\n${r.stdout}${r.stderr}'] : errors;
}

List<String> _changedDart() {
  final out = [
    Process.runSync('git', ['diff', '--name-only', '--relative', 'HEAD']).stdout,
    Process.runSync('git', ['ls-files', '--others', '--exclude-standard']).stdout,
  ].join('\n');
  return {
    for (final l in out.split('\n'))
      if (l.trim().endsWith('.dart') && File(l.trim()).existsSync()) l.trim(),
  }.toList();
}
