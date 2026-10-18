// Ek baar chalao (flutter create ke baad):
//   dart run tool/setup_android.dart
//
// 1. AndroidManifest.xml mein notification permissions daalta hai.
// 2. android/app/build.gradle(.kts) mein "core library desugaring" on karta hai
//    (flutter_local_notifications ke liye zaroori).
import 'dart:io';

void main() {
  final manifestSrc = File('android_files/AndroidManifest.xml');
  final manifestDst = File('android/app/src/main/AndroidManifest.xml');
  if (!manifestDst.parent.existsSync()) {
    stderr.writeln('android/ folder nahi mila. Pehle ye chalao:\n'
        '  flutter create --project-name guten_morgen_app --org de.zitatecke --platforms android .');
    exit(1);
  }
  manifestDst.writeAsStringSync(manifestSrc.readAsStringSync());
  stdout.writeln('✓ AndroidManifest.xml updated');

  // Flutter ka gradle plugin android/app/proguard-rules.pro apne aap use karta hai.
  File('android/app/proguard-rules.pro')
      .writeAsStringSync(File('android_files/proguard-rules.pro').readAsStringSync());
  stdout.writeln('✓ proguard-rules.pro added');

  // WhatsApp share: FileProvider paths + MainActivity (native code).
  final xmlDir = Directory('android/app/src/main/res/xml')..createSync(recursive: true);
  File('${xmlDir.path}/zitatecke_file_paths.xml')
      .writeAsStringSync(File('android_files/zitatecke_file_paths.xml').readAsStringSync());
  _writeMainActivity();

  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  if (kts.existsSync()) {
    _patch(
      kts,
      enableLine: 'isCoreLibraryDesugaringEnabled = true',
      depBlock: '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n    implementation("androidx.core:core:1.13.1")\n}\n',
    );
  } else if (groovy.existsSync()) {
    _patch(
      groovy,
      enableLine: 'coreLibraryDesugaringEnabled true',
      depBlock: "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n    implementation 'androidx.core:core:1.13.1'\n}\n",
    );
  } else {
    stderr.writeln('android/app/build.gradle(.kts) nahi mili.');
    exit(1);
  }
  _setApplicationId(kts.existsSync() ? kts : groovy);
  _disableShrinking(kts.existsSync() ? kts : groovy, isKts: kts.existsSync());
  stdout.writeln('\nSab ready! Ab chalao:  flutter run');
}

/// Play Store package ID. Publish ke baad ye KABHI mat badalna.
const String kApplicationId = 'de.zitatecke.app';

void _setApplicationId(File f) {
  final s = f.readAsStringSync();
  final re = RegExp(r'''applicationId(\s*=?\s*)["'][^"']*["']''');
  if (!re.hasMatch(s)) {
    stderr.writeln('applicationId nahi mila – ${f.path} mein khud "$kApplicationId" daalo.');
    return;
  }
  final updated = s.replaceFirstMapped(re, (m) => 'applicationId${m[1]}"$kApplicationId"');
  f.writeAsStringSync(updated);
  stdout.writeln('✓ applicationId = $kApplicationId');
}

void _patch(File f, {required String enableLine, required String depBlock}) {
  var s = f.readAsStringSync();
  if (s.contains('CoreLibraryDesugaring') || s.contains('coreLibraryDesugaring')) {
    stdout.writeln('✓ ${f.path} pehle se updated hai');
    return;
  }
  final idx = s.indexOf('compileOptions {');
  if (idx == -1) {
    stderr.writeln('${f.path} mein "compileOptions {" nahi mila – README ka manual step dekho.');
    exit(1);
  }
  final insertAt = idx + 'compileOptions {'.length;
  s = '${s.substring(0, insertAt)}\n        $enableLine${s.substring(insertAt)}';
  s = s + depBlock;
  f.writeAsStringSync(s);
  stdout.writeln('✓ ${f.path} updated (desugaring on)');
}

/// Release build mein R8 shrinking band – warna plugins ke methods hat jaate hain
/// aur app white screen pe atak jaati hai.
void _disableShrinking(File f, {required bool isKts}) {
  var s = f.readAsStringSync();
  if (s.contains('isMinifyEnabled') || s.contains('minifyEnabled')) {
    stdout.writeln('✓ shrinking setting pehle se hai');
    return;
  }
  final lines = isKts
      ? '\n            isMinifyEnabled = false\n            isShrinkResources = false'
      : '\n            minifyEnabled false\n            shrinkResources false';
  final bt = s.indexOf('buildTypes');
  final m = bt == -1 ? null : RegExp(r'release\s*\{').firstMatch(s.substring(bt));
  if (m == null) {
    stderr.writeln('buildTypes.release nahi mila – shrinking manually band karo.');
    return;
  }
  final at = bt + m.end;
  s = s.substring(0, at) + lines + s.substring(at);
  f.writeAsStringSync(s);
  stdout.writeln('✓ release shrinking off');
}

/// flutter create wali MainActivity.kt ko WhatsApp-share wali se badlo
/// (package line wahi rehti hai).
void _writeMainActivity() {
  final root = Directory('android/app/src/main/kotlin');
  if (!root.existsSync()) {
    stderr.writeln('kotlin folder nahi mila – MainActivity manually copy karo.');
    return;
  }
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('MainActivity.kt'))
      .toList();
  if (files.isEmpty) {
    stderr.writeln('MainActivity.kt nahi mili.');
    return;
  }
  final target = files.first;
  final pkg = RegExp(r'^package\s+([\w.]+)', multiLine: true)
      .firstMatch(target.readAsStringSync())
      ?.group(1);
  if (pkg == null) {
    stderr.writeln('MainActivity package nahi mila.');
    return;
  }
  final template = File('android_files/MainActivity.kt').readAsStringSync();
  target.writeAsStringSync(template.replaceAll('__PACKAGE__', pkg));
  stdout.writeln('✓ MainActivity.kt (WhatsApp share) – package $pkg');
}
