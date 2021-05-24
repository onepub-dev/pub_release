import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';

import '../pub_release.dart';
import 'multi_settings.dart';

/// Implementation for the 'multi' command
/// which does multi-package releases

void multiRelease(String pathToProjectRoot, VersionMethod versionMethod,
    Version? passedVersion,
    {required bool dryrun,
    required bool runTests,
    required bool autoAnswer,
    int lineLength = 80,
    required String? tags,
    required String? excludeTags}) {
  MultiSettings.homeProjectPath = pathToProjectRoot;
  final toolDir = truepath(join(pathToProjectRoot, 'tool'));

  if (!MultiSettings.exists()) {
    printerr(red(
        "You must provide a ${MultiSettings.filename} file in the $toolDir directory."));
    exit(1);
  }
  final settings = MultiSettings.load();

  // For a multi-release we must have at least on dependency
  if (!settings.hasDependencies()) {
    printerr(red(
        'The ${MultiSettings.filename} file in the $toolDir directory must include at least one dependency.'));
    exit(1);
  }

  print(
      'Preparing a release for package ${orange(settings.packages.last.name)} and its related dependencies.');

  _printDependencies(settings);

  // ignore: parameter_assignments
  final determinedVersion =
      _determineVersion(settings, versionMethod, passedVersion);

  try {
    var firstPackage = true;
    for (final package in settings.packages) {
      print('');
      print(blue(centre('Releasing ${package.name}')));

      /// removeOverrides(package.path);
      final release = ReleaseRunner(package.path);
      final pubspecDetails = release.checkPackage(autoAnswer: true);

      if (firstPackage) {
        // ignore: parameter_assignments
        _setVersion(package, pubspecDetails, determinedVersion, release,
            dryrun: dryrun);

        /// We have asked the user for the version on the first package
        /// all subsequent packages get the same version no.
        // ignore: parameter_assignments
        versionMethod = VersionMethod.set;
        firstPackage = false;
      }

      if (!releaseDependency(
          release, pubspecDetails, versionMethod, determinedVersion,
          dryrun: dryrun,
          lineLength: lineLength,
          runTests: runTests,
          autoAnswer: autoAnswer,
          tags: tags,
          excludeTags: excludeTags)) {
        /// a dependency release failed so stop the release process.
        break;
      }

      // addOverrides(package.path);
    }
  } on PubReleaseException catch (e) {
    printerr(red(e.message));
  }
}

void _printDependencies(MultiSettings settings) {
  /// Print the list of dependencies.
  for (final package in settings.packages.reversed) {
    if (package.name == settings.packages.last.name) continue;
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
    required String? excludeTags}) {
  return release.pubRelease(
      pubSpecDetails: pubSpecDetails,
      versionMethod: versionMethod,
      setVersion: setVersion,
      lineLength: lineLength,
      dryrun: dryrun,
      runTests: runTests,
      autoAnswer: autoAnswer,
      tags: tags,
      excludeTags: excludeTags);
}

/// Determines the version we are to use.
/// If [versionMethod] is [VersionMethod.ask] then we ask the user
/// for the version after getting the highest version from the set of pubspec.yaml.
///
/// If [versionMethod] == [VersionMethod.set] then we take the version in
/// [setVersion] and return it.
Version _determineVersion(
    MultiSettings settings, VersionMethod versionMethod, Version? setVersion) {
  if (versionMethod == VersionMethod.ask) {
    final highestVersion = getHighestVersion(settings);
    // ignore: parameter_assignments
    setVersion = askForVersion(highestVersion);
  }

  // ignore: parameter_assignments
  return setVersion!;
}

/// When releasing we need to ensure that the version no. of any package
/// is higher than the previously released package no.
/// So we need to find the highest version no. from all of the packages.
@visibleForTesting
Version getHighestVersion(MultiSettings settings) {
  final lowest = Version.parse('0.0.1-dev.0');
  var highestVersion = lowest;

  for (final package in settings.packages) {
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

/// Sets the version on the [package] to [version].
void _setVersion(Package package, PubSpecDetails pubspecDetails,
    Version version, ReleaseRunner release,
    {required bool dryrun}) {
  release.determineAndUpdateVersion(VersionMethod.set, version, pubspecDetails,
      dryrun: dryrun);
}
