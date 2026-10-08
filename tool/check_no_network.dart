// Fails if the app could send data over the network (FR-023, Principle VII).
//
// Spec 001 is fully offline. Two checks:
// 1. The main Android manifest must not request the INTERNET permission.
//    `flutter create` puts it only in the debug and profile manifests, where
//    development tooling needs it; release builds use the main manifest.
// 2. No Dart code in the app or the core may use an HTTP client.
// Run from the repository root: dart tool/check_no_network.dart
import 'dart:io';

const mainManifest = 'app/android/app/src/main/AndroidManifest.xml';
const sourceRoots = ['app/lib', 'packages/trn_core/lib'];

void main() {
  final problems = <String>[];

  final manifest = File(mainManifest);
  if (!manifest.existsSync()) {
    stderr.writeln('$mainManifest not found; run from the repository root.');
    exit(2);
  }
  final manifestLines = manifest.readAsLinesSync();
  for (var i = 0; i < manifestLines.length; i++) {
    if (manifestLines[i].contains('android.permission.INTERNET')) {
      problems.add('$mainManifest:${i + 1}: requests the INTERNET permission');
    }
  }

  final networkUse = RegExp(
    r'''(import\s+['"]package:(http|dio)/)|\bHttpClient\b|\bWebSocket\b|\bSocket\.connect\b''',
  );
  for (final root in sourceRoots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final file in dir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (networkUse.hasMatch(lines[i])) {
          problems.add('${file.path}:${i + 1}: network use: ${lines[i].trim()}');
        }
      }
    }
  }

  if (problems.isEmpty) {
    stdout.writeln('No-network check passed.');
    return;
  }
  stderr.writeln('No-network check FAILED:');
  problems.forEach(stderr.writeln);
  exit(1);
}
