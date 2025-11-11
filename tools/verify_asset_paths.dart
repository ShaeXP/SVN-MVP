import 'dart:io';

void main() {
  final repo = Directory.current.path.replaceAll('\\', '/');
  final bad = <String>[];

  // 1) Fail if any nested SVN-MVP…assets/animations exists
  final nested = Directory(repo)
      .listSync(recursive: true)
      .whereType<Directory>()
      .where((d) {
        final p = d.path.replaceAll('\\', '/');
        return p.contains('SVN-MVP/SVN-MVP/assets/animations');
      }).map((d) => d.path.replaceAll('\\', '/'));
  bad.addAll(nested);

  // 2) Fail if pubspec or lib contains asset paths with SVN-MVP/ or leading /assets
  for (final file in Directory(repo)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) {
        final p = f.path.replaceAll('\\', '/');
        return p.endsWith('pubspec.yaml') || p.startsWith('$repo/lib/');
      })) {
    final txt = file.readAsStringSync();
    if (txt.contains('SVN-MVP/')) bad.add(file.path);
    if (txt.contains('/assets/animations/')) bad.add(file.path);
  }

  if (bad.isNotEmpty) {
    stderr.writeln('Invalid asset paths or nested folders detected:');
    for (final b in bad) { stderr.writeln(' - $b'); }
    exit(1);
  } else {
    print('Asset path verification passed.');
  }
}
