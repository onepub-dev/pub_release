/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:path/path.dart';
import 'package:pubspec_manager/pubspec_manager.dart';

import 'multi_settings.dart';
import 'release_file_guard.dart';

/// Manages temporary pubspec_overrides.yaml files for multi releases.

/// Temporarily writes pubspec_overrides.yaml with path overrides for
/// packages in [multiSettings], then restores any original file.
/// @Throwing(ArgumentError)
/// @Throwing(DuplicateKeyException)
/// @Throwing(NotFoundException)
/// @Throwing(PubSpecException)
/// @Throwing(VersionException)
Future<T> withOverridesFile<T>({
  required String packageRoot,
  required MultiSettings multiSettings,
  required Future<T> Function() action,
}) async {
  final overridesPath = join(packageRoot, 'pubspec_overrides.yaml');
  final overridesFile = File(overridesPath);

  final pubspecPath = join(packageRoot, 'pubspec.yaml');
  final pubspec = PubSpec.loadFromPath(pubspecPath);

  final overrides = _buildOverrides(pubspec, multiSettings);
  if (overrides.isEmpty) {
    return await action();
  }

  guardReleaseFile(packageRoot, overridesPath);
  final backupDirectory = Directory.systemTemp.createTempSync('pub_release_');
  final backupFile = File(join(backupDirectory.path, 'pubspec_overrides.yaml'));
  var backedUp = false;
  var writeStarted = false;
  try {
    if (overridesFile.existsSync()) {
      overridesFile.copySync(backupFile.path);
      backedUp = true;
    }
    writeStarted = true;
    overridesFile.writeAsStringSync(_renderOverridesYaml(overrides));
    return await action();
  } finally {
    try {
      if (writeStarted) {
        guardReleaseFile(packageRoot, overridesPath);
        if (backedUp) {
          backupFile.copySync(overridesPath);
        } else if (overridesFile.existsSync()) {
          overridesFile.deleteSync();
        }
      }
    } finally {
      backupDirectory.deleteSync(recursive: true);
    }
  }
}

Map<String, String> _buildOverrides(
    PubSpec pubspec, MultiSettings multiSettings) {
  final overrides = <String, String>{};
  for (final package in multiSettings.packages) {
    if (package.name == pubspec.name.value) {
      continue;
    }
    overrides[package.name] = package.path;
  }
  return overrides;
}

String _renderOverridesYaml(Map<String, String> overrides) {
  final buffer = StringBuffer('dependency_overrides:\n');
  for (final entry in overrides.entries) {
    buffer
      ..write('  ${entry.key}:\n')
      ..write('    path: ${entry.value}\n');
  }
  return buffer.toString();
}
