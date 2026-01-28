/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart' as sm;
import 'package:pubspec_manager/pubspec_manager.dart';

import '../pub_release.dart';
import 'overrides.dart';

/// Implementation for the 'multi' command
/// which does multi-package releases
/// @Throwing(ArgumentError)
/// @Throwing(DuplicateKeyException)
/// @Throwing(FormatException)
/// @Throwing(NotFoundException)
/// @Throwing(PubSpecException)
/// @Throwing(UnsupportedError)
/// @Throwing(VersionException)

Future<void> multiRelease(
  String pathToProjectRoot,
  VersionMethod versionMethod,
  sm.Version? passedVersion, {
  required bool dryrun,
  required bool ignoreWarnings,
  required bool runTests,
  required bool autoAnswer,
  required String? tags,
  required String? excludeTags,
  required bool useGit,
  required bool format,
  required List<String> skipPackages,
  int lineLength = 80,
}) async {
  MultiSettings.homeProjectPath = pathToProjectRoot;
  final toolDir = truepath(join(pathToProjectRoot, 'tool'));

  try {
    final settings =
        checkPreConditions(toolDir, useGit: useGit, skipPackages: skipPackages);

    // For a multi-release we must have at least one dependency
    if (!settings.hasDependencies()) {
      printerr(red(
          'The ${MultiSettings.filename} file in the $toolDir directory must'
          ' include at least one dependency.'));
      exit(1);
    }

    print(
        'Preparing a release for package ${orange(settings.packages.last.name)}'
        ' and its related dependencies.');

    final skipSet = skipPackages.toSet();
    final selectedPackages = settings.packages
        .where((package) => !skipSet.contains(package.name))
        .toList();
    if (selectedPackages.isEmpty) {
      throw PubReleaseException('''
All packages were skipped. Remove items from --skip-packages to continue.''');
    }

    for (final name in skipSet) {
      if (!settings.containsPackage(name)) {
        print(orange('Skipping unknown package "$name".'));
      }
    }

    _printDependencies(selectedPackages);

    final determinedVersion = _determineVersionForPackages(
        selectedPackages, versionMethod, passedVersion, autoAnswer);
    updateAllVersions(selectedPackages, determinedVersion);

    /// Ensure that we only ask the user for a version once.
    /// all subsequent packages get the same version no.
    versionMethod = VersionMethod.set;

    final taggedGitRoots = <String>{};
    String? sharedReleaseNotes;
    for (final package in selectedPackages) {
      print('');
      print(blue(centre('Releasing ${package.name}')));

      /// removeOverrides(package.path);
      final release = ReleaseRunner(package.path);
      final pubspecDetails = release.checkPackage(autoAnswer: true);

      if (sharedReleaseNotes != null) {
        release.applyReleaseNotesIfMissing(
            determinedVersion, sharedReleaseNotes);
      }

      var allowTagging = true;
      if (useGit) {
        final git = Git(package.path);
        final gitRoot = git.pathToGitRoot;
        if (gitRoot != null && taggedGitRoots.contains(gitRoot)) {
          allowTagging = false;
        } else if (gitRoot != null) {
          taggedGitRoots.add(gitRoot);
        }
      }

      final success = await withOverridesFile<bool>(
          packageRoot: package.path,
          multiSettings: settings,
          action: () => releaseDependency(
              release, pubspecDetails, versionMethod, determinedVersion,
              dryrun: dryrun,
              ignoreWarnings: ignoreWarnings,
              lineLength: lineLength,
              format: format,
              runTests: runTests,
              autoAnswer: autoAnswer,
              allowTagging: allowTagging,
              tags: tags,
              excludeTags: excludeTags,
              useGit: useGit));
      if (!success) {
        /// a dependency release failed so stop the release process.
        break;
      }

      sharedReleaseNotes ??= release.readReleaseNotes(determinedVersion);

      // addOverrides(package.path);
    }
  } on PubReleaseException catch (e) {
    printerr(red(e.message));
    exit(1);
  }
}

/// Before we start lets check that everything looks to be in working order.
/// @Throwing(ArgumentError)
/// @Throwing(UnsupportedError)
MultiSettings checkPreConditions(String toolDir,
    {required bool useGit, required List<String> skipPackages}) {
  if (!exists('pubspec.yaml')) {
    printerr(red(
        'You must run pub_release from the root of the main Dart project.'));
    exit(1);
  }
  if (!MultiSettings.yamlExists()) {
    printerr(
        red("You must provide a ${MultiSettings.filename} file in the 'tool' "
            'directory of the main dart package.'));
    exit(1);
  }
  final settings = MultiSettings.load();

  final gitRoots = <String>{};

  var success = true;
  final skipSet = skipPackages.toSet();
  if (useGit) {
    for (final package in settings.packages) {
      if (skipSet.contains(package.name)) {
        continue;
      }
      final git = Git(package.path);

      if (git.isCommitRequired) {
        final gitRoot = git.pathToGitRoot!;
        if (!gitRoots.contains(gitRoot)) {
          printerr(red('You MUST commit all files in $gitRoot first.'));
          gitRoots.add(gitRoot);
          success = false;
        }
      }
    }
  }
  if (!success) {
    exit(1);
  }

  return settings;
}

void _printDependencies(List<Package> packages) {
  /// Print the list of dependencies.
  for (final package in packages.reversed) {
    if (package.name == packages.last.name) {
      continue;
    }
    print('  ${package.name}');
  }
}

String centre(String message, {String fill = '*'}) {
  final columns = Terminal().columns;

  final messageWidth = message.length + 2;

  final fillLeft = (columns - messageWidth) ~/ 2;
  final fillRight = ((columns - messageWidth) / 2).round();
  return '${'*' * fillLeft} $message ${'*' * fillRight}';
}

Future<bool> releaseDependency(
        ReleaseRunner release,
        PubSpecDetails pubSpecDetails,
        VersionMethod versionMethod,
        sm.Version? setVersion,
        {required int lineLength,
        required bool format,
        required bool runTests,
        required bool autoAnswer,
        required bool dryrun,
        required bool ignoreWarnings,
        required bool allowTagging,
        required String? tags,
        required String? excludeTags,
        required bool useGit}) =>
    release.pubRelease(
        pubSpecDetails: pubSpecDetails,
        versionMethod: versionMethod,
        setVersion: setVersion,
        lineLength: lineLength,
        format: format,
        dryrun: dryrun,
        ignoreWarnings: ignoreWarnings,
        runTests: runTests,
        autoAnswer: autoAnswer,
        allowTagging: allowTagging,
        tags: tags,
        excludeTags: excludeTags,
        useGit: useGit);

/// Determines the version we are to use.
/// If [versionMethod] is [VersionMethod.ask] then we ask the user
/// for the version after getting the highest version from
/// the set of pubspec.yaml.
///
/// If [versionMethod] == [VersionMethod.set] then we take the version in
/// [setVersion] and return it.
/// @Throwing(ArgumentError)
/// @Throwing(DuplicateKeyException)
/// @Throwing(FormatException)
/// @Throwing(NotFoundException)
/// @Throwing(PubSpecException)
/// @Throwing(UnsupportedError)
/// @Throwing(VersionException)
sm.Version _determineVersionForPackages(List<Package> packages,
    VersionMethod versionMethod, sm.Version? setVersion, bool autoAnswer) {
  assert(
      (versionMethod == VersionMethod.set && setVersion != null) ||
          versionMethod == VersionMethod.ask,
      'must use set or ask');

  late final sm.Version setVersion0;

  final highestVersion = _getHighestVersion(packages);
  if (versionMethod == VersionMethod.ask) {
    setVersion0 = askForVersion(highestVersion);
  } else {
    setVersion0 = setVersion!;
  }

  /// Check that the selected version is higher then the current highest
  /// version.
  if (!autoAnswer && setVersion0.compareTo(highestVersion) < 0) {
    print(orange(
        'The selected version $setVersion0 should be higher than any current '
        'version ($highestVersion) '));
    print('If you try to publish a version that is already published then the '
        'publish action will fail.');
    if (!confirm('Do you want to continue?')) {
      exit(1);
    }
  }
  return setVersion0;
}

/// @Throwing(ArgumentError)
/// @Throwing(DuplicateKeyException)
/// @Throwing(FormatException)
/// @Throwing(NotFoundException)
/// @Throwing(PubSpecException)
/// @Throwing(VersionException)
sm.Version _getHighestVersion(List<Package> packages) {
  final lowest = sm.Version.parse('0.0.1-dev.0');
  var highestVersion = lowest;

  for (final package in packages) {
    final pubspec = PubSpec.loadFromPath(join(package.path, 'pubspec.yaml'));
    if (pubspec.version.semVersion.compareTo(highestVersion) > 0) {
      highestVersion = pubspec.version.semVersion;
    }
  }

  if (highestVersion == lowest) {
    highestVersion = sm.Version.parse('0.0.1');
  }
  return highestVersion;
}

// /// Sets the version on the [package] to [version].
// void _setVersion(Package package, PubSpecDetails pubspecDetails,
//     Version version, ReleaseRunner release,
//     {required bool dryrun}) {
//   release.determineAndUpdateVersion(VersionMethod.set, version,
// pubspecDetails,
//       dryrun: dryrun);
// }

/// Updates the version of all of the packges
/// and then updates any inter-package dependencies so they
/// required the new version as a minimum.
/// @Throwing(ArgumentError)
/// @Throwing(DuplicateKeyException)
/// @Throwing(NotFoundException)
/// @Throwing(PubSpecException)
/// @Throwing(VersionException)
void updateAllVersions(List<Package> packages, sm.Version version) {
  final knownProjects = <PubSpec>[];
  for (final project in packages) {
    final pubspecPath = join(project.path, 'pubspec.yaml');
    if (exists(pubspecPath)) {
      final pubspec = PubSpec.loadFromPath(pubspecPath)
        ..version.setSemVersion(version)
        ..saveTo(pubspecPath);
      knownProjects.add(pubspec);
    }
  }

  final hatVersion = '^$version';

  // now update dependencies for the 'known' project
  // which we have changed.
  // We add a hat ^ to the start of the version no.
  // to make pub publish happy (it doesn't like overly
  //constrained version numbers)
  for (final project in packages) {
    final pubspecPath = join(project.path, 'pubspec.yaml');
    if (exists(pubspecPath)) {
      final pubspec = PubSpec.loadFromPath(pubspecPath);

      /// Update the version no. for any known dependency whos version
      /// we have just changed.
      for (final dependency in pubspec.dependencies.list) {
        final known = findKnown(knownProjects, dependency);
        if (known != null) {
          if (dependency is DependencyPubHosted) {
            dependency.versionConstraint = hatVersion;
          }
        }
      }

      pubspec.saveTo(pubspecPath);
      knownProjects.add(pubspec);
    }
  }
}

PubSpec? findKnown(List<PubSpec> knownProjects, Dependency dependency) {
  for (final known in knownProjects) {
    if (known.name.value == dependency.name) {
      return known;
    }
  }
  return null;
}
