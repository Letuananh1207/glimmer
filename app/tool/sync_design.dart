// Đồng bộ thiết kế (thư mục design/ ở gốc repo glimmer) → code Flutter trong app/.
//
// Chạy trong app/:   dart run tool/sync_design.dart
//
// Tự động:
//   ../design/tokens/design_tokens.json → lib/ui/core/themes/app_colors.dart  (sinh lại toàn bộ từ "color")
//   ../design/l10n/app_vi.arb           → lib/l10n/app_vi.arb  (gộp: chuỗi thiết kế thắng, giữ chuỗi riêng của code,
//                                                               báo chuỗi thiết kế đã xoá)
//   ../design/icons/*.svg               → assets/icons/
//   ../design/data/*.json               → assets/data/
//   ../design/images/*.png              → assets/images/  (ảnh dùng trong app, vd. màn thiết bị thật)
// Chỉ báo (sửa tay theo CHANGELOG):
//   "font" / "type" / "space" / "size" / "radius" / "border" trong design_tokens.json đổi
//   → lib/ui/core/themes/app_text.dart (viết tay)
//   chuỗi dev… chép từ HTML thiết kế (metadata "x-thiet-ke") mà câu trong HTML đã đổi / thiết kế đã có khoá
//   thư mục assets mới chưa khai báo trong pubspec.yaml
//
// Trạng thái lần đồng bộ trước: .design_sync.json (commit file này). `appliedVersion` do /ui-apply ghi.

import 'dart:convert';
import 'dart:io';

final _root = Directory.current.path.replaceAll('\\', '/');
final _design = '$_root/../design';
final _changed = <String>[];
final _notes = <String>[];
const _handTokens = ['font', 'type', 'space', 'size', 'radius', 'border'];

void main(List<String> args) {
  if (!File('$_root/pubspec.yaml').existsSync()) {
    stderr.writeln('Hãy chạy trong thư mục app/ (nơi có pubspec.yaml).');
    exit(2);
  }
  final tokensFile = File('$_design/tokens/design_tokens.json');
  if (!tokensFile.existsSync()) {
    stderr.writeln('Chưa có design/tokens/design_tokens.json — thiết kế chưa chốt lần nào (/ui-design chot).');
    exit(1);
  }
  final tokens = jsonDecode(tokensFile.readAsStringSync()) as Map<String, dynamic>;
  final state = _readState();

  _writeText('$_root/lib/ui/core/themes/app_colors.dart', _colorsDart(tokens));
  _mergeArb('$_design/l10n/app_vi.arb', '$_root/lib/l10n/app_vi.arb', state);
  _copyDir('icons', 'assets/icons', '.svg');
  _copyDir('data', 'assets/data', '.json');
  _copyDir('images', 'assets/images', '.png');

  for (final key in _handTokens) {
    final before = (state['tokens'] as Map<String, dynamic>?)?[key];
    if (before != null && before != jsonEncode(tokens[key])) {
      _notes.add('design_tokens.json → "$key" đã đổi: sửa tay lib/ui/core/themes/app_text.dart '
          '(AppFonts / AppSpace / AppSize, xem design/CHANGELOG.md).');
    }
  }
  if (!File('$_root/lib/ui/core/themes/app_text.dart').existsSync()) {
    _notes.add('Chưa có lib/ui/core/themes/app_text.dart: viết tay AppFonts / AppSpace / AppSize theo '
        '"font", "type", "space", "size" của design_tokens.json.');
  }

  _writeState(tokens);
  _report();
}

// ---------- màu ----------

String _colorsDart(Map<String, dynamic> t) {
  final b = StringBuffer()
    ..writeln('// SINH TỰ ĐỘNG bởi tool/sync_design.dart từ design/tokens/design_tokens.json.')
    ..writeln('// Không sửa tay — sửa thiết kế rồi chạy: dart run tool/sync_design.dart')
    ..writeln("import 'package:flutter/painting.dart';")
    ..writeln()
    ..writeln('abstract final class AppColors {');
  final colors = (t['color'] as Map<String, dynamic>?) ?? const {};
  colors.forEach((name, spec) {
    final m = spec is Map<String, dynamic> ? spec : {'value': spec};
    final argb = _argb(m['value']);
    if (argb == null) {
      _notes.add('Màu "$name" không đọc được (${m['value']}) — cần #RRGGBB, #AARRGGBB hoặc rgba(r, g, b, a).');
      return;
    }
    if (m['use'] != null) b.writeln('  /// ${m['use']}');
    b.writeln('  static const Color $name = Color(0x$argb);');
  });
  b.writeln('}');
  return b.toString();
}

String? _argb(dynamic v) {
  if (v is! String) return null;
  final hex = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').firstMatch(v.trim());
  if (hex != null) {
    final h = hex.group(1)!.toUpperCase();
    return h.length == 6 ? 'FF$h' : h;
  }
  final rgba = RegExp(r'^rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)$').firstMatch(v.trim());
  if (rgba == null) return null;
  String h(int n) => n.toRadixString(16).padLeft(2, '0').toUpperCase();
  final a = (double.parse(rgba.group(4)!) * 255).round();
  return h(a) + h(int.parse(rgba.group(1)!)) + h(int.parse(rgba.group(2)!)) + h(int.parse(rgba.group(3)!));
}

// ---------- chuỗi ----------

void _mergeArb(String designPath, String libPath, Map<String, dynamic> state) {
  final dFile = File(designPath);
  if (!dFile.existsSync()) return;
  final design = jsonDecode(dFile.readAsStringSync()) as Map<String, dynamic>;
  final libFile = File(libPath);
  final lib = libFile.existsSync()
      ? jsonDecode(libFile.readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{'@@locale': 'vi'};

  final prevKeys = ((state['arbKeys'] as List?) ?? const []).cast<String>().toSet();
  final designKeys = design.keys.where((k) => !k.startsWith('@')).toSet();
  final out = <String, dynamic>{};
  final added = <String>[], updated = <String>[];

  for (final k in lib.keys) {
    // Metadata "@khoá" mà thiết kế đã bỏ (vd. bỏ tham số) → bỏ theo.
    if (k.startsWith('@') && designKeys.contains(k.substring(1)) && !design.containsKey(k)) continue;
    if (design.containsKey(k)) {
      if (!k.startsWith('@') && jsonEncode(lib[k]) != jsonEncode(design[k])) updated.add(k);
      out[k] = design[k];
    } else {
      out[k] = lib[k];
    }
  }
  for (final k in design.keys) {
    if (out.containsKey(k)) continue;
    out[k] = design[k];
    if (!k.startsWith('@')) added.add(k);
  }
  // Chuỗi thiết kế từng có nay đã xoá: không tự xoá (code có thể đang dùng), chỉ báo.
  final removed = prevKeys.difference(designKeys).where(lib.containsKey).toList();

  _writeText(libPath, '${const JsonEncoder.withIndent('  ').convert(out)}\n');
  if (added.isNotEmpty) _notes.add('Chuỗi mới: ${added.join(', ')}');
  if (updated.isNotEmpty) _notes.add('Chuỗi đổi nội dung: ${updated.join(', ')}');
  if (removed.isNotEmpty) {
    _notes.add('Thiết kế đã bỏ các chuỗi: ${removed.join(', ')} — gỡ chỗ dùng trong lib/ rồi xoá khỏi '
        'lib/l10n/app_vi.arb.');
  }
  if (added.isNotEmpty || updated.isNotEmpty) _notes.add('Chạy tiếp: flutter gen-l10n');
  _checkDevFromDesign(out, design);
}

/// Chuỗi `dev…` chép từ câu chữ viết thẳng trong HTML thiết kế: metadata `"x-thiet-ke": "source/<Màn>.dc.html"`
/// (tuỳ chọn `"x-khoa-thiet-ke": "<khoá đang chờ>"`). Báo khi câu trong HTML đã đổi, hoặc thiết kế đã có khoá
/// cùng nội dung (nên đổi code sang khoá đó rồi xoá chuỗi dev).
void _checkDevFromDesign(Map<String, dynamic> lib, Map<String, dynamic> design) {
  String norm(String v) => v.replaceAll(RegExp(r'\{[^}]*\}'), '{}').replaceAll(RegExp(r'\s+'), ' ').trim();
  String plainHtml(String html) => [
        html.replaceAll(RegExp(r'<[^>]+>'), ''),
        for (final m in RegExp(r'<script[^>]*>([\s\S]*?)</script>').allMatches(html)) m[1]!,
        for (final m in RegExp(r'\b(?:aria-label|alt|title|placeholder)="([^"]*)"').allMatches(html)) m[1]!,
      ]
          .join(' ')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll(RegExp(r'\s+'), ' ');
  final designText = <String, String>{
    for (final e in design.entries)
      if (!e.key.startsWith('@') && e.value is String) norm(e.value as String): e.key,
  };
  final htmlCache = <String, String?>{};
  final changed = <String>[], promoted = <String>[];
  for (final e in lib.entries) {
    final k = e.key;
    if (!k.startsWith('dev') || e.value is! String) continue;
    final meta = lib['@$k'];
    final src = meta is Map ? meta['x-thiet-ke'] as String? : null;
    final want = meta is Map ? meta['x-khoa-thiet-ke'] as String? : null;
    if (src == null && want == null) continue;
    final value = e.value as String;
    if (want != null) {
      if (design[want] is String && norm(design[want] as String) == norm(value)) promoted.add('$k → $want');
    } else if (designText[norm(value)] case final dk?) {
      promoted.add('$k → $dk');
    }
    if (src == null) continue;
    final html = htmlCache.putIfAbsent(src, () {
      final f = File('$_design/$src');
      return f.existsSync() ? plainHtml(f.readAsStringSync()) : null;
    });
    if (html == null) {
      changed.add('$k (không thấy design/$src)');
      continue;
    }
    for (final part in value.split(RegExp(r'\{[^}]*\}'))) {
      final frag = part.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (frag.length < 4 || html.contains(frag)) continue;
      changed.add('$k ("$frag" không còn trong design/$src)');
      break;
    }
  }
  if (changed.isNotEmpty) _notes.add('Chuỗi dev chép từ thiết kế có thể đã đổi: ${changed.join('; ')}');
  if (promoted.isNotEmpty) _notes.add('Thiết kế đã có khoá cho chuỗi dev — đổi code sang khoá rồi xoá dev: ${promoted.join(', ')}');
}

// ---------- tài nguyên ----------

/// Chép `design/<from>/*<ext>` → `<to>/`; báo khi `<to>/` chưa khai báo trong pubspec.yaml.
void _copyDir(String from, String to, String ext) {
  final dir = Directory('$_design/$from');
  if (!dir.existsSync()) return;
  var any = false;
  for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith(ext))) {
    any = true;
    _copy(f.path, '$_root/$to/${f.uri.pathSegments.last}');
  }
  if (any && !File('$_root/pubspec.yaml').readAsStringSync().contains('$to/')) {
    _notes.add('Thêm "- $to/" vào mục flutter: assets: của pubspec.yaml.');
  }
}

void _copy(String from, String to) {
  final bytes = File(from).readAsBytesSync();
  final dst = File(to);
  if (dst.existsSync()) {
    final old = dst.readAsBytesSync();
    var same = old.length == bytes.length;
    for (var i = 0; same && i < old.length; i++) {
      if (old[i] != bytes[i]) same = false;
    }
    if (same) return;
  }
  dst.parent.createSync(recursive: true);
  dst.writeAsBytesSync(bytes);
  _changed.add(to);
}

void _writeText(String path, String content) {
  final f = File(path);
  if (f.existsSync() && f.readAsStringSync() == content) return;
  f.parent.createSync(recursive: true);
  f.writeAsStringSync(content);
  _changed.add(path);
}

// ---------- trạng thái ----------

Map<String, dynamic> _readState() {
  final f = File('$_root/.design_sync.json');
  return f.existsSync() ? jsonDecode(f.readAsStringSync()) as Map<String, dynamic> : <String, dynamic>{};
}

void _writeState(Map<String, dynamic> tokens) {
  final arb = File('$_design/l10n/app_vi.arb');
  final design = arb.existsSync() ? jsonDecode(arb.readAsStringSync()) as Map<String, dynamic> : const {};
  final next = <String, dynamic>{
    'appliedVersion': _readState()['appliedVersion'],
    'syncedVersion': _latestVersion(),
    'tokens': {for (final k in _handTokens) k: jsonEncode(tokens[k])},
    'arbKeys': design.keys.where((k) => !k.startsWith('@')).toList()..sort(),
  };
  final text = '${const JsonEncoder.withIndent('  ').convert(next)}\n';
  final f = File('$_root/.design_sync.json');
  if (!f.existsSync() || f.readAsStringSync() != text) f.writeAsStringSync(text);
}

String? _latestVersion() {
  final f = File('$_design/CHANGELOG.md');
  if (!f.existsSync()) return null;
  return RegExp(r'^## (\d{4}-\d{2}-\d{2}\.\d+)', multiLine: true).firstMatch(f.readAsStringSync())?.group(1);
}

void _report() {
  stdout.writeln('Thiết kế phiên bản: ${_latestVersion() ?? '(chưa có mục CHANGELOG)'}');
  if (_changed.isEmpty) {
    stdout.writeln('Không có file nào cần cập nhật.');
  } else {
    stdout.writeln('Đã cập nhật ${_changed.length} file:');
    for (final c in _changed) {
      stdout.writeln('  • ${c.replaceFirst('$_root/', '')}');
    }
  }
  if (_notes.isNotEmpty) {
    stdout.writeln('\nCần chú ý:');
    for (final n in _notes) {
      stdout.writeln('  - $n');
    }
  }
}
