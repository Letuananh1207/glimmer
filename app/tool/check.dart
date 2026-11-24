// Kiểm quy tắc bộ chuẩn flutter-dev (.claude/skills/flutter-dev) — chỉ in chỗ vi phạm.
//
// Chạy từ gốc dự án:
//   dart tool/check.dart              toàn bộ lib/
//   dart tool/check.dart --changed    chỉ file đổi so với HEAD (kể cả file mới) — dùng sau mỗi lần sửa
//   dart tool/check.dart --summary    chỉ in số đếm theo quy tắc
//   dart tool/check.dart --report     chỉ báo cáo, không thoát mã 1 khi có lỗi (mặc định: có lỗi E… → mã 1)
//   --max=N                               số chỗ in tối đa mỗi quy tắc (mặc định 20)
//
// Lỗi (E):
//   E-lop     import sai lớp (bảng "Ai được import ai" ở flutter-dev/references/architecture.md)
//   E-goi     lớp không phải UI/data import gói không thuộc lớp đó (material, provider, drift…)
//   E-context widget trong lib/ui/ tự lấy phụ thuộc bằng context.read/watch/select, Provider.of
//   E-ngoai   file nằm ngoài cấu trúc lớp (lib/screens, lib/widgets, lib/state, lib/data/<file>.dart…)
// Cảnh báo (W):
//   W-mau     màu viết cứng Color(0x…) ngoài app_colors.dart
//   W-co-chu  fontSize viết số
//   W-chuoi   chuỗi tiếng Việt viết thẳng (phải qua AppLocalizations)
//   W-dai     file quá 400 dòng
//   W-backend đổi repository/model dữ liệu mà docs/backend/ không đổi

import 'dart:io';

const _maxLines = 400;

final _root = Directory.current.path.replaceAll('\\', '/');
final _found = <String, List<String>>{};

/// Tên gói trong pubspec.yaml — để nhận `package:<tên>/…` là import nội bộ.
late final String _pkg;

void main(List<String> args) {
  final pubspec = File('$_root/pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('Hãy chạy lệnh ở thư mục gốc dự án.');
    exit(2);
  }
  _pkg = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(pubspec.readAsStringSync())?.group(1) ?? '';
  if (!Directory('$_root/lib').existsSync()) {
    stdout.writeln('check: chưa có lib/');
    return;
  }
  final changedOnly = args.contains('--changed');
  final summary = args.contains('--summary');
  final reportOnly = args.contains('--report');
  final max = int.tryParse(
        args
            .firstWhere((a) => a.startsWith('--max='), orElse: () => '--max=20')
            .substring(6),
      ) ??
      20;

  final all = Directory('$_root/lib')
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => _rel(f.path))
      .where((p) => p.endsWith('.dart') && !_skip(p))
      .toList()
    ..sort();
  final changed = changedOnly ? _gitChanged() : null;
  final files = changed == null ? all : all.where(changed.contains).toList();

  for (final path in files) {
    _checkFile(path);
  }
  if (changed != null) _checkBackendDocs(changed);

  final errors = _report(summary: summary, max: max);
  stdout.writeln(
    'check: ${files.length} file · $errors lỗi · '
    '${_count('W')} cảnh báo',
  );
  if (!reportOnly && errors > 0) exit(1);
}

// ---------- Lớp ----------

class _Layer {
  const _Layer(this.kind, [this.feature]);

  /// view, vm, ui_core, routes, routing, config, main, models, rules, use_case, repo, service, migration,
  /// api_model, utils, l10n, legacy.
  final String kind;

  /// Tính năng (`ui/<f>`) hoặc nhóm repository (`data/repositories/<f>`).
  final String? feature;
}

_Layer _layerOf(String p) {
  final s = p.split('/');
  if (p == 'lib/main.dart') return const _Layer('main');
  if (s.length < 3) return const _Layer('legacy');
  switch (s[1]) {
    case 'ui':
      if (s[2] == 'core') return const _Layer('ui_core');
      if (s.length > 4 && s[3] == 'view_models') return _Layer('vm', s[2]);
      return _Layer('view', s[2]);
    case 'domain':
      return switch (s[2]) {
        'models' => const _Layer('models'),
        'rules' => const _Layer('rules'),
        'use_cases' => const _Layer('use_case'),
        _ => const _Layer('legacy'),
      };
    case 'data':
      return switch (s[2]) {
        'repositories' => _Layer('repo', s.length > 4 ? s[3] : null),
        'services' => const _Layer('service'),
        'migrations' => const _Layer('migration'),
        'models' => const _Layer('api_model'),
        _ => const _Layer('legacy'),
      };
    case 'routing':
      return _Layer(p.endsWith('/routes.dart') ? 'routes' : 'routing');
    case 'config':
      return const _Layer('config');
    case 'utils':
      return const _Layer('utils');
    case 'l10n':
      return const _Layer('l10n');
  }
  return const _Layer('legacy');
}

/// Lớp được import (bảng mục 5). `*` = mọi lớp mới.
const _allowed = <String, Set<String>>{
  'view': {'ui_core', 'view', 'vm', 'models', 'utils', 'l10n', 'routes'},
  'ui_core': {'ui_core', 'models', 'utils', 'l10n', 'routes'},
  'vm': {'models', 'rules', 'use_case', 'repo', 'utils'},
  'use_case': {'models', 'rules', 'use_case', 'repo', 'utils'},
  'repo': {'models', 'rules', 'service', 'api_model', 'migration', 'repo', 'utils'},
  'migration': {'models', 'rules', 'service', 'migration', 'utils'},
  'service': {'api_model', 'utils'},
  'api_model': {'models', 'utils'},
  'rules': {'models', 'rules', 'utils'},
  'models': {'models', 'utils'},
  'utils': {'utils'},
  'routes': {'models', 'utils'},
  'l10n': {'l10n'},
  'routing': {'*'},
  'config': {'*'},
  'main': {'*'},
};

/// Gói ngoài chỉ được dùng ở các lớp này. Thêm gói mới của dự án vào đây
/// (gói nói chuyện với thế giới bên ngoài → chỉ `service`, cộng `config`/`main` nếu cần khởi tạo).
const _packageOwners = <String, Set<String>>{
  'package:flutter/material.dart': {'view', 'ui_core', 'routing', 'config', 'main'},
  'package:flutter/widgets.dart': {'view', 'ui_core', 'routing', 'routes', 'config', 'main'},
  'package:flutter/cupertino.dart': {'view', 'ui_core'},
  'package:provider/': {'view', 'ui_core', 'routing', 'config', 'main'},
  'package:go_router/': {'view', 'ui_core', 'routing', 'routes', 'config', 'main'},
  'package:shared_preferences/': {'service'},
  'package:sqflite': {'service'},
  'package:drift/': {'service'},
  'package:drift_flutter/': {'service'},
  'package:hive': {'service'},
  'package:isar': {'service'},
  'package:path_provider/': {'service'},
  'package:flutter_secure_storage/': {'service'},
  'package:flutter_local_notifications/': {'service'},
  'package:http/': {'service'},
  'package:nsd/': {'service'},
  'package:wifi_iot/': {'service'},
  'package:permission_handler/': {'service'},
  'package:file_picker/': {'service'},
  'package:share_plus/': {'service'},
  'package:dio/': {'service'},
  'package:supabase_flutter/': {'service', 'config', 'main'},
  'package:supabase/': {'service'},
  'package:firebase_core/': {'service', 'config', 'main'},
  'package:cloud_firestore/': {'service'},
  'package:firebase_auth/': {'service'},
  'package:firebase_analytics/': {'service'},
  'package:posthog_flutter/': {'service', 'config', 'main'},
  'package:in_app_purchase': {'service', 'config', 'main'},
};

final _importRe = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');
final _contextRe = RegExp(r'context\.(read|watch|select)\s*<|Provider\.of\s*<|Consumer\d?\s*<');
final _colorRe = RegExp(r'Color\(\s*0x');
final _fontSizeRe = RegExp(r'fontSize:\s*\d');
final _stringRe = RegExp(r'''r?'(?:[^'\\]|\\.)*'|r?"(?:[^"\\]|\\.)*"''');
final _vnRe = RegExp(
  '[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]',
  caseSensitive: false,
);

void _checkFile(String path) {
  final lines = File('$_root/$path').readAsLinesSync();
  final layer = _layerOf(path);
  if (layer.kind == 'legacy') _add('E-ngoai', path);
  if (lines.length > _maxLines) _add('W-dai', '$path (${lines.length} dòng)');

  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final at = '$path:${i + 1}';
    final m = _importRe.firstMatch(raw);
    if (m != null) {
      _checkImport(path, layer, m.group(1)!, at);
      continue;
    }
    final code = _stripComment(raw);
    if (code.trim().isEmpty) continue;
    if ({'view', 'ui_core'}.contains(layer.kind) &&
        !path.endsWith('/view_model_host.dart') &&
        _contextRe.hasMatch(code)) {
      _add('E-context', at);
    }
    if (_colorRe.hasMatch(code) && !path.endsWith('/app_colors.dart')) {
      _add('W-mau', at);
    }
    if (_fontSizeRe.hasMatch(code)) _add('W-co-chu', at);
    if (!code.contains('debugPrint(') &&
        _stringRe.allMatches(code).any((s) => _vnRe.hasMatch(s.group(0)!))) {
      _add('W-chuoi', '$at  ${code.trim().length > 90 ? '${code.trim().substring(0, 90)}…' : code.trim()}');
    }
  }
}

void _checkImport(String path, _Layer from, String uri, String at) {
  final String target;
  if (_pkg.isNotEmpty && uri.startsWith('package:$_pkg/')) {
    target = 'lib/${uri.substring('package:$_pkg/'.length)}';
  } else if (uri.startsWith('package:') || uri.startsWith('dart:')) {
    for (final e in _packageOwners.entries) {
      if (uri.startsWith(e.key) && !e.value.contains(from.kind)) {
        _add('E-goi', '$at  ${from.kind} không dùng $uri');
      }
    }
    return;
  } else {
    target = _normalize('${path.substring(0, path.lastIndexOf('/'))}/$uri');
  }
  final to = _layerOf(target);
  if (to.kind == 'legacy') return; // đã báo E-ngoai ở chính file đó
  final ok = _allowed[from.kind] ?? const {};
  var allowed = ok.contains('*') || ok.contains(to.kind);
  // View chỉ dùng ViewModel/màn của chính tính năng mình.
  if ((to.kind == 'vm' || to.kind == 'view') && from.kind == 'view' && to.feature != from.feature) {
    allowed = false;
  }
  // Repository không biết nhau (chỉ import trong nhóm của mình).
  if (from.kind == 'repo' && to.kind == 'repo' && to.feature != from.feature) {
    allowed = false;
  }
  // Service không gọi nhau; một service nhiều file (thư mục riêng `services/<tên>/`) import lẫn nhau được.
  if (from.kind == 'service' && to.kind == 'service') {
    final dir = path.substring(0, path.lastIndexOf('/'));
    allowed = dir != 'lib/data/services' && target.startsWith('$dir/');
  }
  if (!allowed) _add('E-lop', '$at  ${from.kind} → ${to.kind}: $target');
}

/// Đổi lib/data/repositories hoặc lib/domain/models mà docs/backend không đổi → nhắc cập nhật hợp đồng dữ liệu.
void _checkBackendDocs(Set<String> changed) {
  if (!Directory('$_root/docs/backend').existsSync()) return;
  final data = changed.where(
    (p) => p.startsWith('lib/data/repositories/') || p.startsWith('lib/domain/models/'),
  );
  if (data.isNotEmpty && !changed.any((p) => p.startsWith('docs/backend/'))) {
    _add('W-backend', '${data.join(', ')} — cập nhật docs/backend/ nếu đổi trường dữ liệu');
  }
}

// ---------- Tiện ích ----------

bool _skip(String p) =>
    p.startsWith('lib/l10n/app_localizations') || p.endsWith('.g.dart');

String _rel(String abs) {
  final p = abs.replaceAll('\\', '/');
  return p.startsWith('$_root/') ? p.substring(_root.length + 1) : p;
}

String _normalize(String p) {
  final out = <String>[];
  for (final s in p.split('/')) {
    if (s == '..') {
      if (out.isNotEmpty) out.removeLast();
    } else if (s != '.' && s.isNotEmpty) {
      out.add(s);
    }
  }
  return out.join('/');
}

/// Bỏ phần chú thích `//` (không cắt `//` nằm trong chuỗi, ví dụ URL).
String _stripComment(String line) {
  String? quote;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (quote != null) {
      if (c == '\\') {
        i++;
      } else if (c == quote) {
        quote = null;
      }
    } else if (c == "'" || c == '"') {
      quote = c;
    } else if (c == '/' && i + 1 < line.length && line[i + 1] == '/') {
      return line.substring(0, i);
    }
  }
  return line;
}

Set<String>? _gitChanged() {
  final diff = Process.runSync('git', ['diff', '--name-only', '--relative', 'HEAD']);
  final untracked = Process.runSync('git', ['ls-files', '--others', '--exclude-standard']);
  if (diff.exitCode != 0) {
    stderr.writeln('Không đọc được git diff — kiểm toàn bộ.');
    return null;
  }
  return {
    for (final out in [diff.stdout, untracked.stdout])
      for (final l in (out as String).split('\n'))
        if (l.trim().isNotEmpty) l.trim(),
  };
}

void _add(String rule, String where) => (_found[rule] ??= []).add(where);

int _count(String prefix) => _found.entries
    .where((e) => e.key.startsWith(prefix))
    .fold(0, (n, e) => n + e.value.length);

int _report({required bool summary, required int max}) {
  final rules = _found.keys.toList()..sort();
  for (final rule in rules) {
    final items = _found[rule]!;
    stdout.writeln('$rule: ${items.length}');
    if (summary) continue;
    for (final w in items.take(max)) {
      stdout.writeln('  $w');
    }
    if (items.length > max) stdout.writeln('  … và ${items.length - max} chỗ khác (--max=N để xem thêm)');
  }
  return _count('E');
}
