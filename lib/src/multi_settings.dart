import 'package:dcli/dcli.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:settings_yaml/settings_yaml.dart';

///
/// reads/writes to the pubrelease_multi.yaml file.
///

/// Holds settings information for a project
/// including any package dependencies use by the 'multi' command.
///
class MultiSettings {
  /// Load the pubrelease_multi.yaml into memory.
  /// [pathTo] is intended for aiding with unit testing by allowing
  /// the test to pass an alternate path. Normally [pathTo] should not
  /// be passed as the file will be loaded from its default location.
  /// If you pass [pathTo] it must include the filename.
  MultiSettings.load({String? pathTo}) {
    pathTo ??= pathToYaml;
    final settings = SettingsYaml.load(pathToSettings: pathTo);

    for (final entry in settings.valueMap.entries) {
      final package =
          Package(entry.key, truepath(homeProjectPath, entry.value as String));
      if (!exists(package.path)) {
        throw PubReleaseException(
            'The path ${package.path} for ${package.name} does not exist.');
      }

      if (!exists(join(package.path, 'pubspec.yaml'))) {
        throw PubReleaseException(
            'The pubspec.yaml for ${package.name} does not exist.');
      }

      packages.add(package);
    }
  }

  static const filename = 'pubrelease_multi.yaml';

  static late final pathToYaml = join(homeProjectPath, 'tool', filename);
  final packages = <Package>[];

  static String? _pathToHomeProject;

  static set homeProjectPath(String pathToHomeProject) =>
      _pathToHomeProject = pathToHomeProject;

  static String get homeProjectPath =>
      _pathToHomeProject ?? DartProject.fromPath('.').pathToProjectRoot;

  bool hasDependencies() => packages.isNotEmpty;

  bool containsPackage(String packageName) {
    var found = false;

    for (final package in packages) {
      if (package.name == packageName) {
        found = true;
        break;
      }
    }
    return found;
  }

  bool validate() {
    var valid = true;
    try {
      for (final package in packages) {
        if (!exists(package.path)) {
          throw PubReleaseException(
              'The path ${package.path} for ${package.name} does not exist.');
        }

        if (!exists(join(package.path, 'pubspec.yaml'))) {
          throw PubReleaseException(
              'The pubspec.yaml for ${package.name} does not exist.');
        }
      }
    } on PubReleaseException catch (e) {
      valid = false;
      print(e);
    }
    return valid;
  }

  static bool yamlExists() => exists(pathToYaml);

  /// When releasing we need to ensure that the version no. of any package
  /// is higher than the previously released package no.
  /// So we need to find the highest version no. from all of the packages.
  Version getHighestVersion() {
    final lowest = Version.parse('0.0.1-dev.0');
    var highestVersion = lowest;

    for (final package in packages) {
      final pubspec = PubSpec.fromFile(join(package.path, 'pubspec.yaml'));
      if (pubspec.version != null &&
          pubspec.version!.compareTo(highestVersion) > 0) {
        highestVersion = pubspec.version!;
      }
    }

    /// If no package had a version no.
    if (highestVersion == lowest) {
      highestVersion = Version.parse('0.0.1');
    }

    return highestVersion;
  }

  /// Updates the version of all of the conduit packges
  /// and then updates any inter-package dependencies so they
  /// required the new version as a minimum.
  void updateAllVersions(String version) {
    final rootOfMonoRepo =
        truepath(DartProject.fromPath('.').pathToProjectRoot, '..');
    final projects = find('*',
            types: [Find.directory],
            recursive: false,
            workingDirectory: rootOfMonoRepo)
        .toList();

    final knownProjects = <PubSpec>[];
    for (final project in projects) {
      final pubspecPath = join(project, 'pubspec.yaml');
      if (exists(pubspecPath)) {
        final pubspec = PubSpec.fromFile(pubspecPath)
          ..version = Version.parse(version)
          ..saveToFile(pubspecPath);
        knownProjects.add(pubspec);
      }
    }

    final hatVersion = '^$version';

    // now update dependencies for the 'known' project
    // which we have changed.
    // We add a hat ^ to the start of the version no
    // to make pub publish happy (it doesn't like overly
    //constrained version numbers)
    for (final project in projects) {
      final pubspecPath = join(project, 'pubspec.yaml');
      if (exists(pubspecPath)) {
        final pubspec = PubSpec.fromFile(pubspecPath);

        final replacementDependencies = <String, Dependency>{};

        /// Update the version no. for any known dependency whos version
        /// we have just changed.
        for (final dependency in pubspec.dependencies.values) {
          final known = findKnown(knownProjects, dependency);
          if (known != null) {
            replacementDependencies[dependency.name] =
                Dependency.fromHosted(dependency.name, hatVersion);
          } else {
            replacementDependencies[dependency.name] = dependency;
          }
        }
        pubspec
          ..dependencies = replacementDependencies
          ..saveToFile(pubspecPath);
        knownProjects.add(pubspec);
      }
    }
  }

  PubSpec? findKnown(List<PubSpec> knownProjects, Dependency dependency) {
    for (final known in knownProjects) {
      if (known.name == dependency.name) {
        return known;
      }
    }
    return null;
  }
}

class Package {
  Package(this.name, this.path);
  String name;

  /// The truepath to the packages location on the file system.
  String path;
}

class PubReleaseException implements Exception {
  PubReleaseException(this.message);
  String message;
}
