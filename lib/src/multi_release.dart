/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart' as sm;
import 'package:pubspec_manager/pubspec_manager.dart' hide Version;

import '../pub_release.dart';

/// Implementation for the 'multi' command
/// which does multi-package releases

void multiRelease(
  String pathToProjectRoot,
  VersionMethod versionMethod,
  Version? passedVersion, {
  required bool dryrun,
  required bool runTests,
  required bool autoAnswer,
  required String? tags,
  required String? excludeTags,
  required bool useGit,
  int lineLength = 80,
}) {
  MultiSettings.homeProjectPath = pathToProjectRoot;
  final toolDir = truepath(join(pathToProjectRoot, 'tool'));

  try {
    final settings = checkPreConditions(toolDir, useGit: useGit);

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

    _printDependencies(settings);

    // ignore: parameter_assignments
    final determinedVersion =
        _determineVersion(settings, versionMethod, passedVersion, autoAnswer);
    updateAllVersions(settings, determinedVersion);

    /// Ensure that we only ask the user for a version once.
    /// all subsequent packages get the same version no.
    // ignore: parameter_assignments
    versionMethod = VersionMethod.set;

    for (final package in settings.packages) {
      print('');
      print(blue(centre('Releasing ${package.name}')));

      /// removeOverrides(package.path);
      final release = ReleaseRunner(package.path);
      final pubspecDetails = release.checkPackage(autoAnswer: true);

      if (!releaseDependency(
          release, pubspecDetails, versionMethod, determinedVersion,
          dryrun: dryrun,
          lineLength: lineLength,
          runTests: runTests,
          autoAnswer: autoAnswer,
          tags: tags,
          excludeTags: excludeTags,
          useGit: useGit)) {
        /// a dependency release failed so stop the release process.
        break;
      }

      // addOverrides(package.path);
    }
  } on PubReleaseException catch (e) {
    printerr(red(e.message));
    exit(1);
  }
}

/// Before we start lets check that everything looks to be in working order.
MultiSettings checkPreConditions(String toolDir, {required bool useGit}) {
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
  if (useGit) {
    for (final package in settings.packages) {
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

void _printDependencies(MultiSettings settings) {
  /// Print the list of dependencies.
  for (final package in settings.packages.reversed) {
    if (package.name == settings.packages.last.name) {
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

bool releaseDependency(ReleaseRunner release, PubSpecDetails pubSpecDetails,
        VersionMethod versionMethod, Version? setVersion,
        {required int lineLength,
        required bool runTests,
        required bool autoAnswer,
        required bool dryrun,
        required String? tags,
        required String? excludeTags,
        required bool useGit}) =>
    release.pubRelease(
        pubSpecDetails: pubSpecDetails,
        versionMethod: versionMethod,
        setVersion: setVersion,
        lineLength: lineLength,
        dryrun: dryrun,
        runTests: runTests,
        autoAnswer: autoAnswer,
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
Version _determineVersion(MultiSettings settings, VersionMethod versionMethod,
    Version? setVersion, bool autoAnswer) {
  assert(
      (versionMethod == VersionMethod.set && setVersion != null) ||
          versionMethod == VersionMethod.ask,
      'must use set or ask');

  late final Version _setVersion;

  final highestVersion = settings.getHighestVersion();
  if (versionMethod == VersionMethod.ask) {
    _setVersion = askForVersion(highestVersion);
  } else {
    _setVersion = setVersion!;
  }

  /// Check that the selected version is higher then the current highest
  /// version.
  if (!autoAnswer && _setVersion.compareTo(highestVersion) < 0) {
    print(orange(
        'The selected version $_setVersion should be higher than any current '
        'version ($highestVersion) '));
    print('If you try to publish a version that is already published then the '
        'publish action will fail.');
    if (!confirm('Do you want to continue?')) {
      exit(1);
    }
  }
  return _setVersion;
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
void updateAllVersions(MultiSettings settings, sm.Version version) {
  final knownProjects = <PubSpec>[];
  for (final project in settings.packages) {
    final pubspecPath = join(project.path, 'pubspec.yaml');
    if (exists(pubspecPath)) {
      final pubspec = PubSpec.loadFromPath(pubspecPath)
        ..version.value = version
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
  for (final project in settings.packages) {
    final pubspecPath = join(project.path, 'pubspec.yaml');
    if (exists(pubspecPath)) {
      final pubspec = PubSpec.loadFromPath(pubspecPath);

      /// Update the version no. for any known dependency whos version
      /// we have just changed.
      for (final dependency in pubspec.dependencies.list) {
        final known = findKnown(knownProjects, dependency);
        if (known != null) {
          if (dependency is PubHostedDependency) {
            dependency.version = hatVersion;
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
