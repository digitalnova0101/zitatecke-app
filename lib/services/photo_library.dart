import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import '../theme/card_styles.dart';
import 'http_util.dart';

class RemotePhoto {
  const RemotePhoto({required this.id, required this.file, required this.tags, required this.dim});

  final String id;
  final String file; // "photos/ph_x.jpg"
  final List<String> tags;
  final double dim;

  factory RemotePhoto.fromJson(Map<String, dynamic> j) => RemotePhoto(
        id: j['id'] as String,
        file: j['file'] as String,
        tags: ((j['tags'] as List?) ?? const []).cast<String>(),
        dim: ((j['dim'] as num?) ?? 0.1).toDouble(),
      );
}

/// Online photos: download, phone mein cache, aur quote ke mood se match.
class PhotoLibrary {
  PhotoLibrary._();
  static final PhotoLibrary instance = PhotoLibrary._();

  Directory? _dir;
  List<RemotePhoto> _catalog = const [];

  /// Agar kisi mood ki photo na ho to ye milte-julte moods.
  static const Map<String, List<String>> _fallback = {
    'kaffee': ['sonnenaufgang'],
    'regen': ['himmel'],
    'nebel': ['himmel', 'natur'],
    'wald': ['natur'],
    'herbst': ['natur'],
    'kerzen': ['feier', 'winter'],
    'mond': ['nacht'],
    'sterne': ['nacht'],
    'herz': ['rosen', 'blumen'],
    'rosen': ['blumen'],
    'feier': ['blumen'],
    'winter': ['schnee'],
    'schnee': ['winter'],
    'sommer': ['meer', 'blumen'],
    'fruehling': ['blumen'],
    'himmel': ['meer'],
  };

  Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    _dir = Directory('${docs.path}/content/photos');
    await _dir!.create(recursive: true);
  }

  String _localPath(RemotePhoto p) => '${_dir!.path}/${p.id}.jpg';

  /// Feed ki photo list (naye pehle).
  void setCatalog(List<RemotePhoto> photos) {
    _catalog = photos;
    _register();
  }

  void _register() {
    dynamicStyles.clear();
    if (_dir == null) return;
    for (final p in _catalog) {
      final path = _localPath(p);
      if (!File(path).existsSync()) continue;
      dynamicStyles['r_${p.id}'] = CardStyle(
        id: 'r_${p.id}',
        file: path,
        dim: p.dim,
        tags: p.tags,
        colors: const [Color(0xFF3B2A35), Color(0xFF6B4A5A)],
        textColor: Colors.white,
        emoji: '🖼️',
      );
    }
  }

  /// Zaroori photos download karo. [neededMoods] wali pehle.
  Future<int> sync({Set<String> neededMoods = const {}, int maxNew = 25}) async {
    if (_dir == null) return 0;
    final keep = _catalog.take(kMaxCachedPhotos).toList();
    final missing = keep.where((p) => !File(_localPath(p)).existsSync()).toList()
      ..sort((a, b) {
        final an = a.tags.any(neededMoods.contains) ? 0 : 1;
        final bn = b.tags.any(neededMoods.contains) ? 0 : 1;
        return an - bn;
      });
    var count = 0;
    for (final p in missing.take(maxNew)) {
      try {
        await Http.download(Uri.parse('$kContentBase${p.file}'), File(_localPath(p)));
        count++;
      } catch (e) {
        debugPrint('photo ${p.id} failed: $e');
      }
    }
    // Purani photos hatao jo ab feed mein nahi (ya limit se bahar).
    final keepIds = keep.map((p) => '${p.id}.jpg').toSet();
    try {
      for (final f in _dir!.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (!keepIds.contains(name)) f.deleteSync();
      }
    } catch (_) {}
    _register();
    return count;
  }

  /// Mood ke hisaab se photo style (online photos + app ki photos).
  String? styleIdForMood(String mood, {required String seed}) {
    final all = [...dynamicStyles.values, ...kCardStyles.where((s) => s.hasPhoto)];
    var cands = all.where((s) => s.tags.contains(mood)).toList();
    if (cands.isEmpty) {
      for (final alt in _fallback[mood] ?? const <String>[]) {
        cands = all.where((s) => s.tags.contains(alt)).toList();
        if (cands.isNotEmpty) break;
      }
    }
    if (cands.isEmpty) return null;
    return cands[seed.hashCode.abs() % cands.length].id;
  }

  int get cachedCount => dynamicStyles.length;
}
