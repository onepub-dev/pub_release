import 'dart:io';

import 'package:dshell/dshell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:dshell/src/pubspec/pubspec_file.dart';

/// Walks the user through selecting a new version no.
Version incrementVersion(Version version, PubSpecFile pubspec,
    String pubspecPath, NewVersion selected) {
  version = selected.version;

  print('');

  // recreate the version file
  var packageRootPath = dirname(pubspecPath);

  print('The accepted version is: $version');

  // write new version.g.dart file.
  var versionPath = join(packageRootPath, 'lib', 'src', 'version');
  if (!exists(versionPath)) createDir(versionPath, recursive: true);
  var versionFile = join(versionPath, 'version.g.dart');
  print('Regenerating version file at ${absolute(versionFile)}');
  versionFile.write('/// GENERATED BY pub_release do not modify.');
  versionFile.append('/// ${pubspec.name} version');
  versionFile.append("String packageVersion = '$version';");

  // rewrite the pubspec.yaml with the new version
  pubspec.version = version;
  print('pubspec version is: ${pubspec.version}');
  print('pubspec path is: $pubspecPath');
  pubspec.saveToFile(pubspecPath);
  return version;
}

NewVersion askForVersion(Version version) {
  var options = <NewVersion>[
    NewVersion('Small Patch'.padRight(25), version.nextPatch),
    NewVersion('Non-breaking change'.padRight(25), version.nextMinor),
    NewVersion('Breaking change'.padRight(25), version.nextBreaking),
    NewVersion('Keep the current Version'.padRight(25), version),
    NewVersion('Enter custom version no.'.padRight(25), null,
        getVersion: getCustomVersion),
  ];

  print('');
  print(blue('What sort of changes have been made since the last release?'));
  var selected = menu(prompt: 'Select the change level:', options: options);
  version = selected.version;

  print('');
  print(green('The new version is: $version'));
  print('');
  version = confirmVersion(version);
  return selected;
}

/// Ask the user to confirm the selected version no.
Version confirmVersion(Version version) {
  if (!confirm('Is this the correct version')) {
    try {
      var versionString = ask('Enter the new version: ');

      if (!confirm('Is $versionString the correct version')) {
        exit(1);
      }

      version = Version.parse(versionString);
    } on FormatException catch (e) {
      print(e);
    }
  }
  return version;
}

class NewVersion {
  String message;
  Version _version;
  Version Function() getVersion;

  NewVersion(this.message, this._version, {this.getVersion});

  @override
  String toString() => '$message  (${_version ?? "?"})';

  Version get version {
    _version ??= getVersion();
    return _version;
  }
}

/// Ask the user to type a custom version no.
Version getCustomVersion() {
  Version version;
  do {
    try {
      var entered = ask('Enter the new Version No.:', validator: Ask.required);
      version = Version.parse(entered);
    } on FormatException catch (e) {
      print(e);
    }
  } while (version == null);
  return version;
}
