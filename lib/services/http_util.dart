import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Chhota HTTP helper (koi extra package nahi).
class Http {
  Http._();

  static const _ua = 'Zitatecke-App/1.2 (+https://zitatecke.de)';

  static Future<String> getText(Uri uri, {Duration timeout = const Duration(seconds: 15)}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(uri).timeout(timeout);
      req.headers.set(HttpHeaders.userAgentHeader, _ua);
      final res = await req.close().timeout(timeout);
      if (res.statusCode != 200) {
        await res.drain<void>();
        throw HttpException('HTTP ${res.statusCode}', uri: uri);
      }
      return await res.transform(utf8.decoder).join().timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }

  static Future<dynamic> getJson(Uri uri, {Duration timeout = const Duration(seconds: 15)}) async =>
      jsonDecode(await getText(uri, timeout: timeout));

  /// File download (pehle .part, phir rename – aadhi file kabhi nahi bachegi).
  static Future<void> download(Uri uri, File target, {Duration timeout = const Duration(seconds: 30)}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    final part = File('${target.path}.part');
    try {
      final req = await client.getUrl(uri).timeout(timeout);
      req.headers.set(HttpHeaders.userAgentHeader, _ua);
      final res = await req.close().timeout(timeout);
      if (res.statusCode != 200) {
        await res.drain<void>();
        throw HttpException('HTTP ${res.statusCode}', uri: uri);
      }
      final sink = part.openWrite();
      await res.pipe(sink).timeout(timeout);
      await part.rename(target.path);
    } catch (e) {
      if (await part.exists()) await part.delete();
      rethrow;
    } finally {
      client.close(force: true);
    }
  }
}
