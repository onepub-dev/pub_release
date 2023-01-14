import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';

import '../../pub_release.dart';

/// Returns the version no. for the pubspec.yaml located
/// at [pubspecPath].
/// Use [findPubSpec] to find the location.
///
Version? version({required String pubspecPath}) {
  final pubspec = PubSpec.fromFile(pubspecPath);
  return pubspec.version;
}

String versionPath(String pathToPackgeRoot) =>
    join(pathToPackgeRoot, 'lib', 'src', 'version');

String versionLibraryPath(String pathToPackgeRoot) =>
    join(versionPath(pathToPackgeRoot), 'version.g.dart');

/// Makes a backup copy of the version.g.dart source file.
void backupVersionLibrary(String pathToPackageRoot) {
  final versionLibrary = versionLibraryPath(pathToPackageRoot);
  backupFile(versionLibrary);
}

/// Restores the version.g.dart source from a back made
/// by an earlier call to [backupVersionLibrary]
void restoreVersionLibrary(String pathToPackageRoot) {
  final versionLibrary = versionLibraryPath(pathToPackageRoot);
  restoreFile(versionLibrary);
}

/// In a multi-package release (where we have a multi settings file)
/// This method will return the highest version no. used by
/// any of the packages listed in the multi settings file.
/// [pathToPrimaryPackage] so contain the path to the
/// main package of the multi package project that contains
/// the pub_release.multi.yaml file in its tool directory.
/// In reallity it can be the path to any of the project roots.
Version getHigestVersionNo(String pathToPrimaryPackage) {
  final pathTo = join(pathToPrimaryPackage, 'tool', MultiSettings.filename);

  if (!exists(pathTo)) {
    throw PubReleaseException(
        'The ${MultiSettings.filename} was not found at ${dirname(pathTo)}.');
  }

  final settings = MultiSettings.load(pathTo: pathToPrimaryPackage);
  return settings.getHighestVersion();
}

/// Updates the pubspec.yaml and versiong.g.dart with the
/// new version no.
void updateVersion(Version? newVersion, PubSpec pubspec, String pathToPubSpec) {
  updateVersionFromDetails(newVersion, PubSpecDetails(pubspec, pathToPubSpec));
}

/// Updates the pubspec.yaml and versiong.g.dart with the
/// new version no.
void updateVersionFromDetails(
    Version? newVersion, PubSpecDetails pubspecDetails) {
  print('');

  // recreate the version file
  final pathToPackgeRoot = dirname(pubspecDetails.path);

  print(green('Updated pubspec.yaml version to $newVersion'));

  // updated the verions no.
  pubspecDetails.pubspec.version = newVersion;

  // write new version.g.dart file.
  final pathToVersion = versionPath(pathToPackgeRoot);
  final pathToVersionLibrary = versionLibraryPath(pathToPackgeRoot);

  if (!exists(pathToVersion)) {
    createDir(pathToVersion, recursive: true);
  }
  print('Regenerating version file at ${absolute(pathToVersionLibrary)}');
  pathToVersionLibrary
    ..write('/// GENERATED BY pub_release do not modify.')
    ..append('/// ${pubspecDetails.pubspec.name} version')
    ..append("String packageVersion = '$newVersion';");

  // rewrite the pubspec.yaml with the new version
  pubspecDetails.pubspec.saveToFile(pubspecDetails.path);

  /// pause for a moment incase an IDE is monitoring the pubspec.yaml
  /// changes. If we move too soon the .dart_tools directory may not exist.
  sleep(2);
}

/// Ask the user to select the new version no.
/// Pass in  the current [currentVersion] number.
Version askForVersion(Version currentVersion) {
  final options = determineVersionToOffer(currentVersion);

  print('');
  print(blue('What sort of changes have been made since the last release?'));
  final selected = menu(prompt: 'Select the change level:', options: options)
    ..requestVersion();

  return confirmVersion(selected.version);
}

List<NewVersion> determineVersionToOffer(Version currentVersion) {
  final newVersions = <NewVersion>[
    NewVersion('Keep the current Version'.padRight(25), currentVersion)
  ];

  if (!currentVersion.isPreRelease) {
    return newVersions
      ..addAll(defaultVersionToOffer(currentVersion, includePre: true));
  } else {
    final pre = currentVersion.preRelease;

    /// we only know how to handle pre of the form 'beta.1'.
    if (pre.length != 2 || pre[0] is! String || pre[1] is! int) {
      /// don't know how to handle pre-release versions that don't
      /// start with a string such as dev, alpha or beta
      return newVersions
        ..addAll(defaultVersionToOffer(currentVersion, includePre: true));
    }
    final type = pre[0] as String;
    final preVersion = pre[1] as int;
    switch (type) {
      case 'beta':
        newVersions.addAll([
          NewVersion('Small Patch'.padRight(25),
              buildPre(currentVersion, 'beta', preVersion + 1))
        ]);
        break;
      case 'alpha':
        newVersions.addAll([
          NewVersion('Alpha'.padRight(25),
              buildPre(currentVersion, 'alpha', preVersion + 1)),
          NewVersion('Beta'.padRight(25), buildPre(currentVersion, 'beta', 1))
        ]);
        break;
      default:
        newVersions.addAll([
          NewVersion('Small Patch'.padRight(25),
              buildPre(currentVersion, 'dev', preVersion + 1)),
          NewVersion(
              'Alpha'.padRight(25), buildPre(currentVersion, 'alpha', 1)),
          NewVersion('Beta'.padRight(25), buildPre(currentVersion, 'beta', 1))
        ]);

        /// if we don't know the type we treat it as dev.
        break;
    }

    newVersions.addAll(defaultVersionToOffer(currentVersion));
  }

  return newVersions;
}

Version buildPre(Version currentVersion, String preType, int preVersion) =>
    Version(currentVersion.major, currentVersion.minor, currentVersion.patch,
        pre: '$preType.$preVersion');

List<NewVersion> defaultVersionToOffer(Version currentVersion,
    {bool includePre = false}) {
  final versions = <NewVersion>[
    NewVersion((includePre ? 'Small Patch' : 'Release').padRight(25),
        currentVersion.nextPatch)
  ];

  var minor = currentVersion.nextMinor;
  if (minor == currentVersion.nextPatch) {
    minor = minor.nextMinor;
  }
  versions
    ..add(NewVersion('Non-breaking change'.padRight(25), minor))
    ..addAll([
      NewVersion('Breaking change'.padRight(25), currentVersion.nextBreaking),
      if (includePre)
        PreReleaseVersion('Pre-release'.padRight(25), currentVersion),
      CustomVersion('Enter custom version no.'.padRight(25))
    ]);
  return versions;
}

/// Ask the user to confirm the selected version no.
Version confirmVersion(Version version) {
  var confirmedVersion = version;
  print('');
  print(green('The new version is: $confirmedVersion'));
  print('');

  if (!confirm('Is this the correct version')) {
    var valid = false;
    do {
      try {
        final versionString = ask('Enter the new version: ');

        if (!confirm('Is $versionString the correct version')) {
          exit(1);
        }

        confirmedVersion = Version.parse(versionString);
        valid = true;
      } on FormatException catch (e) {
        print(e);
      }
    } while (!valid);
  }
  return confirmedVersion;
}

// ignore: one_member_abstracts
abstract class _Version {
  void requestVersion();
}

/// Used by version menu to provide a nice message
/// for the user.
@visibleForTesting
class NewVersion extends _Version {
  NewVersion(this.message, this._version);
  final String message;
  @protected
  Version _version;

  @override
  String toString() => '$message  ($_version)';

  Version get version => _version;

  @override
  void requestVersion() {}
}

/// Used by the version menu to allow the user to select a custom version.
/// When this classes [version] property is called it triggers
@visibleForTesting
class CustomVersion extends NewVersion {
  @override
  CustomVersion(String message) : super(message, Version.parse('0.0.1'));

  @override
  Version get version => _version;

  /// Ask the user to type a custom version no.
  @override
  void requestVersion() {
    var valid = false;
    do {
      try {
        final entered =
            ask('Enter the new Version No.:', validator: Ask.required);
        _version = Version.parse(entered);
        valid = true;
      } on FormatException catch (e) {
        print(e);
      }
    } while (!valid);
  }

  @override
  String toString() => message;
}

/// Used by the version menu to allow the user to select a custom version.
/// When this classes [version] property is called it triggers
@visibleForTesting
class PreReleaseVersion extends NewVersion {
  @override
  PreReleaseVersion(super.message, super.currentVersion);

  @override
  Version get version => _version;

  /// Ask the user to type a custom version no.
  @override
  void requestVersion() {
    late final String preType;
    if (!version.isPreRelease) {
      final type = ['dev', 'alpha', 'beta'];

      print('');
      print(blue('Select the type of prerelease.'));
      preType = menu(prompt: 'Prerelease type:', options: type);
    }

    final options = getNextVersions(version, preType);

    print('');
    print(blue('What sort of changes have been made since the last release?'));
    final selected = menu(prompt: 'Select the change level:', options: options);
    _version = selected.version;
    if (selected is CustomVersion) {
      selected.requestVersion();
    }
  }

  @override
  String toString() => message;

  List<NewVersion> getNextVersions(Version version, String? type) {
    var small = version.nextPatch;
    var nonBreaking = version.nextMinor;
    var major = version.nextMajor;

    if (!version.isPreRelease) {
      assert(type != null, 'If version is a prerelease you must pass a type');
      final selected = '$type.1';
      small = Version(version.major, version.minor, version.patch + 1,
          pre: selected);

      nonBreaking = Version(version.major, version.minor + 1, 0, pre: selected);

      major = Version(version.major + 1, 0, 0, pre: selected);
    }

    return <NewVersion>[
      NewVersion('Keep the current Version'.padRight(25), version),
      NewVersion('Small Patch'.padRight(25), small),
      NewVersion('Non-breaking change'.padRight(25), nonBreaking),
      NewVersion('Breaking change'.padRight(25), major),
      CustomVersion('Enter custom version no.'.padRight(25))
    ];
  }
}
