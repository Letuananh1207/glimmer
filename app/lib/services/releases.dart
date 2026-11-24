import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// The rolling `latest` release CI publishes on every push to main.
class Release {
  final DateTime published;
  final String commit; // first 7 of the target commit, if known
  final Map<String, String> assets; // name → download URL
  const Release(this.published, this.commit, this.assets);
}

class Releases {
  static Future<Release> latest(String repo) async {
    final c = HttpClient()..userAgent = 'glimmer-app';
    try {
      final req = await c.getUrl(Uri.parse('https://api.github.com/repos/$repo/releases/tags/latest'));
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final res = await req.close().timeout(const Duration(seconds: 15));
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) {
        throw HttpException(res.statusCode == 403
            ? 'GitHub đang giới hạn lượt gọi, thử lại sau ít phút.'
            : 'Không đọc được bản phát hành (HTTP ${res.statusCode}).');
      }
      final j = jsonDecode(text) as Map<String, dynamic>;
      final assets = <String, String>{
        for (final a in (j['assets'] as List? ?? const []).whereType<Map<String, dynamic>>())
          a['name'] as String: a['browser_download_url'] as String,
      };
      final when = DateTime.tryParse((j['published_at'] ?? j['created_at'] ?? '') as String) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final target = (j['target_commitish'] ?? '') as String;
      // target_commitish is a SHA only when CI tagged a commit; skip branch names.
      final sha = RegExp(r'^[0-9a-f]{7,40}$').hasMatch(target) ? target.substring(0, 7) : '';
      return Release(when.toLocal(), sha, assets);
    } finally {
      c.close(force: true);
    }
  }

  /// Download a release asset (follows GitHub's redirect to its CDN).
  static Future<Uint8List> download(String url, {void Function(double)? onProgress}) async {
    final c = HttpClient()..userAgent = 'glimmer-app';
    try {
      final res = await (await c.getUrl(Uri.parse(url))).close().timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw HttpException('Tải thất bại (HTTP ${res.statusCode}).');
      final total = res.contentLength;
      final b = BytesBuilder(copy: false);
      await for (final chunk in res) {
        b.add(chunk);
        if (total > 0) onProgress?.call(b.length / total);
      }
      return b.takeBytes();
    } finally {
      c.close(force: true);
    }
  }
}
