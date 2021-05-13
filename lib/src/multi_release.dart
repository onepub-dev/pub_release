import 'dart:io';

import 'package:dcli/dcli.dart';

import '../pub_release.dart';
import 'multi_settings.dart';

/// Implementation for the 'sem' command
/// which does simultaneous releases

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

  if (!MultiSettings().exists()) {
    printerr(red(
        "You must provide a ${MultiSettings.filename} file in the $toolDir directory."));
    exit(-1);
  }
  final settings = MultiSettings()..load();

  // For a multi-release we must have at least on dependency
  if (!settings.hasDependencies()) {
    printerr(red(
        'The ${MultiSettings.filename} file in the $toolDir directory must include at least one dependency.'));
    exit(-1);
  }

  print(
      'Preparing a release for package ${orange(settings.packages.last.name)} and its related dependencies.');

  _printDependencies(settings);

  // ignore: parameter_assignments
  final determinedVersion =
      _determineVersion(settings.packages.first, versionMethod, passedVersion);

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

      releaseDependency(
          release, pubspecDetails, versionMethod, determinedVersion,
          dryrun: dryrun,
          lineLength: lineLength,
          runTests: runTests,
          autoAnswer: autoAnswer,
          tags: tags,
          excludeTags: excludeTags);

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

void releaseDependency(ReleaseRunner release, PubSpecDetails pubSpecDetails,
    VersionMethod versionMethod, Version? setVersion,
    {required int lineLength,
    required bool runTests,
    required bool autoAnswer,
    required bool dryrun,
    required String? tags,
    required String? excludeTags}) {
  release.pubRelease(
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
/// for the version after getting the current version from the pubspec.yaml.
///
/// If [versionMethod] == [VersionMethod.set] then we take the version in
/// [setVersion] and return it.
Version _determineVersion(
    Package leafPackage, VersionMethod versionMethod, Version? setVersion) {
  if (versionMethod == VersionMethod.ask) {
    final pubspec = PubSpec.fromFile(join(leafPackage.path, 'pubspec.yaml'));
    // ignore: parameter_assignments
    setVersion = askForVersion(pubspec.version ?? Version.parse('0.0.1'));
  }

  // ignore: parameter_assignments
  return setVersion!;
}

/// Sets the version on the [package] to [version].
void _setVersion(Package package, PubSpecDetails pubspecDetails,
    Version version, ReleaseRunner release,
    {required bool dryrun}) {
  release.determineAndUpdateVersion(VersionMethod.set, version, pubspecDetails,
      dryrun: dryrun);
}
