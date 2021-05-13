import 'package:dcli/dcli.dart';

import 'multi_settings.dart';

///
/// Manages updating the pubspec.yaml dependency overrides.
///

/// Removes all of the dependency_overrides for each of the packages
/// listed in the pubsem.yaml file.
void removeOverrides(String pathToProjectRoot) {
  final pubsem = MultiSettings()..load();

  for (final package in pubsem.packages) {
    final pubspecPath = join(pathToProjectRoot, package.path, 'pubspec.yaml');
    final pubspec = PubSpec.fromFile(pubspecPath);
    _removeOverrides(pubspec, pubsem);
    pubspec.saveToFile(pubspecPath);
  }
}

void addOverrides(String pathToProjectRoot) {
  final pubsem = MultiSettings()..load();

  for (final package in pubsem.packages) {
    final pubspecPath = join(pathToProjectRoot, package.path, 'pubspec.yaml');
    final pubspec = PubSpec.fromFile(pubspecPath);

    /// remove and re-add overrides in case they have changed.
    _removeOverrides(pubspec, pubsem);
    _addOverrides(pathToProjectRoot, pubspec, pubsem);

    pubspec.saveToFile(pubspecPath);
  }
}

/// Adds the set of packages in [pubsem] into [pubspec].
/// Assumes that the packages don't already exists in [pubsem]
///
void _addOverrides(
    String pathToProjectRoot, PubSpec pubspec, MultiSettings pubsem) {
  final updated = Map<String, Dependency>.from(pubspec.dependencyOverrides);
  for (final package in pubsem.packages) {
    // we don't add an override to ourselves
    if (package.name == pubspec.name) continue;

    /// we only add an override if we are already depending.
    if (!pubspec.dependencies.containsKey(package.name)) continue;
    final dep = Dependency.fromPath(
        package.name, relative(package.path, from: pathToProjectRoot));
    updated[package.name] = dep;
  }

  pubspec.dependencyOverrides = updated;
}

/// Removes any overrides that related to packages found in
/// [pubsem].
void _removeOverrides(PubSpec pubspec, MultiSettings pubsem) {
  final keep = <String, Dependency>{};
  for (final entry in pubspec.dependencyOverrides.entries) {
    if (!pubsem.containsPackage(entry.key)) {
      keep[entry.key] = entry.value;
    }
  }

  pubspec.dependencyOverrides = keep;
}
