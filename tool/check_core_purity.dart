// Fails if packages/trn_core depends on or imports Flutter (research R8).
//
// The core holds the rules Principles I and IV care most about. Keeping it
// free of Flutter keeps those rules testable without a device and reusable by
// a later backend. Run from the repository root: dart tool/check_core_purity.dart
import 'dart:io';

void main() {
  final problems = <String>[];

  final pubspec = File('packages/trn_core/pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('packages/trn_core/pubspec.yaml not found; run from the repository root.');
    exit(2);
  }
  final pubspecLines = pubspec.readAsLinesSync();
  for (var i = 0; i < pubspecLines.length; i++) {
    final line = pubspecLines[i];
    if (RegExp(r'^\s*(flutter|flutter_test)\s*:').hasMatch(line)) {
      problems.add('packages/trn_core/pubspec.yaml:${i + 1}: depends on Flutter: ${line.trim()}');
    }
  }

  final dartFiles = Directory('packages/trn_core')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('.dart_tool'));
  final flutterImport = RegExp(r'''^\s*(import|export)\s+['"]package:flutter''');
  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      if (flutterImport.hasMatch(lines[i])) {
        problems.add('${file.path}:${i + 1}: imports Flutter: ${lines[i].trim()}');
      }
    }
  }

  if (problems.isEmpty) {
    stdout.writeln('Core purity check passed: packages/trn_core has no Flutter dependency.');
    return;
  }
  stderr.writeln('Core purity check FAILED:');
  problems.forEach(stderr.writeln);
  exit(1);
}
