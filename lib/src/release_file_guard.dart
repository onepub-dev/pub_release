import 'dart:io';

import 'package:path/path.dart' as p;

/// Rejects symbolic links in a release artifact and its package-local parents.
///
/// The package root is the boundary, so sibling packages in a multi release
/// remain supported. Checks include dangling links and run before file access.
/// This preflight check does not protect against concurrent same-user races.
void guardReleaseFile(String packageRoot, String filePath) {
  final root = p.normalize(p.absolute(packageRoot));
  final target = p.normalize(p.absolute(filePath));
  if (!p.isWithin(root, target)) {
    throw FileSystemException(
        'Release artifact is outside package root', target);
  }

  var component = root;
  final components = <String>[root];
  for (final part in p.split(p.relative(target, from: root))) {
    component = p.join(component, part);
    components.add(component);
  }
  for (final path in components) {
    if (FileSystemEntity.typeSync(path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw FileSystemException(
          'Refusing symbolic link in release artifact path', path);
    }
  }
}

/// Checks every package artifact before a release starts changing files.
void guardReleaseArtifacts(String packageRoot) {
  for (final artifact in [
    'pubspec.yaml',
    'pubspec.lock',
    'pubspec_overrides.yaml',
    '.gitignore',
    'CHANGELOG.md',
    'changelog.md',
    'CHANGELOG.md.bak',
    'changelog.md.bak',
    'release.notes.tmp.md',
    p.join('lib', 'src', 'version', 'version.g.dart'),
  ]) {
    guardReleaseFile(packageRoot, p.join(packageRoot, artifact));
  }
}
