import 'dart:io' as io;

import 'package:path/path.dart';

/// Runs [action] inside a temporary copy of [projectRoot].
///
/// We need this for `dart pub publish --dry-run` because pub warns when the
/// working tree has modified files. During a dry run we intentionally update
/// pubspec.yaml, lib/src/version.g.dart and CHANGELOG.md files, so publishing
/// from a temp copy keeps the real
/// workspace clean while still validating the package contents.
T withDryRunDirectory<T>(
  String projectRoot,
  T Function(String workingDirectory) action,
) {
  final tempDir = io.Directory.systemTemp.createTempSync('pub_release_dryrun_');
  _copyDirectory(
    io.Directory(projectRoot),
    tempDir,
    excludeNames: {'.git', '.dart_tool'},
  );
  _rewritePubspecOverridesPaths(
      originalProjectRoot: projectRoot, tempProjectRoot: tempDir.path);
  try {
    return action(tempDir.path);
  } finally {
    _cleanupDryRunDirectory(tempDir.path);
  }
}

void _cleanupDryRunDirectory(String tempPath) {
  try {
    io.Directory(tempPath).deleteSync(recursive: true);
  } catch (_) {
    // Best effort cleanup; keep dry-run resilient.
  }
}

void _copyDirectory(io.Directory source, io.Directory target,
    {required Set<String> excludeNames}) {
  if (!target.existsSync()) {
    target.createSync(recursive: true);
  }

  for (final entity in source.listSync(followLinks: false)) {
    final name = basename(entity.path);
    if (excludeNames.contains(name)) {
      continue;
    }

    final destPath = join(target.path, name);
    if (entity is io.Directory) {
      _copyDirectory(entity, io.Directory(destPath),
          excludeNames: excludeNames);
    } else if (entity is io.File) {
      io.File(destPath).createSync(recursive: true);
      entity.copySync(destPath);
    }
  }
}

void _rewritePubspecOverridesPaths(
    {required String originalProjectRoot, required String tempProjectRoot}) {
  final overridesPath = join(tempProjectRoot, 'pubspec_overrides.yaml');
  final overridesFile = io.File(overridesPath);
  if (!overridesFile.existsSync()) {
    return;
  }

  final lines = overridesFile.readAsLinesSync();
  var changed = false;
  final updated = <String>[];

  for (final line in lines) {
    final match = RegExp(r'^(\s*path:\s*)(.+)\s*$').firstMatch(line);
    if (match == null) {
      updated.add(line);
      continue;
    }

    final prefix = match.group(1)!;
    var value = match.group(2)!.trim();
    final quote = (value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))
        ? value.substring(0, 1)
        : '';
    if (quote.isNotEmpty && value.length >= 2) {
      value = value.substring(1, value.length - 1);
    }

    if (!isAbsolute(value)) {
      final absolute = normalize(join(originalProjectRoot, value));
      updated.add('$prefix$quote$absolute$quote');
      changed = true;
    } else {
      updated.add(line);
    }
  }

  if (changed) {
    overridesFile.writeAsStringSync(updated.join('\n'));
  }
}
