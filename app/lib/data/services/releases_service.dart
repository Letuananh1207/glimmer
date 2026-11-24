import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// GitHub answered [status] (0 = network error).
class ReleaseHttpException implements Exception {
  const ReleaseHttpException(this.status);
  final int status;

  @override
  String toString() => 'ReleaseHttpException($status)';
}

/// GitHub releases API + asset downloads.
class ReleasesService {
  /// `GET /repos/{repo}/releases/tags/latest` → raw JSON.
  Future<Map<String, dynamic>> latestJson(String repo) async {
    final c = HttpClient()..userAgent = 'glimmer-app';
    try {
      final req = await c.getUrl(Uri.parse('https://api.github.com/repos/$repo/releases/tags/latest'));
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final res = await req.close().timeout(const Duration(seconds: 15));
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) throw ReleaseHttpException(res.statusCode);
      return jsonDecode(text) as Map<String, dynamic>;
    } finally {
      c.close(force: true);
    }
  }

  /// Download a release asset (follows GitHub's redirect to its CDN).
  Future<Uint8List> download(String url, {void Function(double)? onProgress}) async {
    final c = HttpClient()..userAgent = 'glimmer-app';
    try {
      final res = await (await c.getUrl(Uri.parse(url))).close().timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw ReleaseHttpException(res.statusCode);
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
