/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:pubspec_manager/pubspec_manager.dart';

import 'multi_settings.dart';

///
/// Manages updating the pubspec.yaml dependency overrides.
///

/// Removes all of the dependency_overrides for each of the packages
/// listed in the pubrelease_multi.yaml file.
void removeOverrides(String pathToProjectRoot) {
  final multiSettings = MultiSettings.load();

  for (final package in multiSettings.packages) {
    final pubspecPath = join(pathToProjectRoot, package.path, 'pubspec.yaml');
    final pubspec = PubSpec.loadFromPath(pubspecPath);
    _removeOverrides(pubspec, multiSettings);
    pubspec.saveTo(pubspecPath);

    /// pause for a moment incase an IDE is monitoring the pubspec.yaml
    /// changes. If we move too soon the .dart_tools directory may not exist.
    sleep(2);
  }
}

/// Adds all of the overrides required by the [MultiSettings] config
/// file.
void addOverrides(String pathToProjectRoot) {
  final multiSettings = MultiSettings.load();

  for (final package in multiSettings.packages) {
    final pubspecPath = join(pathToProjectRoot, package.path, 'pubspec.yaml');
    final pubspec = PubSpec.loadFromPath(pubspecPath);

    /// remove and re-add overrides in case they have changed.
    _removeOverrides(pubspec, multiSettings);
    _addOverrides(pathToProjectRoot, pubspec, multiSettings);

    pubspec.saveTo(pubspecPath);
  }
}

/// Adds the set of packages in [MultiSettings] into [pubspec]
/// as an override.
/// Assumes that the packages don't already exists in [multiSettings]
///
void _addOverrides(
    String pathToProjectRoot, PubSpec pubspec, MultiSettings multiSettings) {
  for (final package in multiSettings.packages) {
    // we don't add an override to ourselves
    if (package.name == pubspec.name.value) {
      continue;
    }

    /// we only add an override if the pubspec has an existing dependency
    /// on [package.name]
    if (!pubspec.dependencies.exists(package.name)) {
      continue;
    }

    final path = relative(package.path, from: pathToProjectRoot);
    pubspec.dependencyOverrides
        .append(PathDependencyBuilder(name: package.name, path: path));
  }
}

/// Removes any overrides that related to packages found in
/// [multiSettings].
void _removeOverrides(PubSpec pubspec, MultiSettings multiSettings) {
  final dependencies = pubspec.dependencyOverrides.list;
  for (final dependency in dependencies) {
    if (multiSettings.containsPackage(dependency.name)) {
      pubspec.dependencyOverrides.remove(dependency.name);
    }
  }
}
