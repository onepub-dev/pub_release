@Timeout(Duration(minutes: 10))
library;

import 'package:dcli/dcli.dart';
import 'package:path/path.dart' hide equals;
import 'package:pub_release/src/multi_settings.dart';
import 'package:pub_release/src/overrides.dart';
import 'package:pubspec_manager/pubspec_manager.dart';
import 'package:test/test.dart';

final String monoRoot = createTempDir();

const primaryName = 'primary';
const middleName = 'middle';
const outermostName = 'outermost';

const donttouchmepath = '../some/path/';

final String primaryProject = join(monoRoot, primaryName);
final String middleProject = join(monoRoot, middleName);
final String outermostProject = join(monoRoot, outermostName);

final String primaryPubspec = join(primaryProject, 'pubspec.yaml');
final String middlePubspec = join(middleProject, 'pubspec.yaml');
final String outermostPubspec = join(outermostProject, 'pubspec.yaml');
final String primaryOverrides = join(primaryProject, 'pubspec_overrides.yaml');

final String multiSettingsPathTo =
    join(primaryProject, 'tool', MultiSettings.filename);

/// @Throwing(ArgumentError)
/// @Throwing(ReadException)
void main() {
  setUpAll(createSampleMonoProject);

  test('withOverridesFile writes and restores overrides', () async {
    MultiSettings.homeProjectPath = primaryProject;
    final settings = MultiSettings.load();

    const originalOverrides = '''
dependency_overrides:
  donttouchme:
    path: $donttouchmepath
''';
    primaryOverrides.write(originalOverrides.trim());

    await withOverridesFile<bool>(
        packageRoot: primaryProject,
        multiSettings: settings,
        action: () async {
          final contents = read(primaryOverrides).toList().join('\n');
          expect(contents.contains('dependency_overrides:'), isTrue);
          expect(contents.contains('donttouchme'), isFalse);
          expect(contents.contains('  $middleName:'), isTrue);
          expect(contents.contains('    path: $middleProject'), isTrue);
          expect(contents.contains('  $outermostName:'), isTrue);
          expect(contents.contains('    path: $outermostProject'), isTrue);
          return true;
        });

    expect(read(primaryOverrides).toList().join('\n').trim(),
        equals(originalOverrides.trim()));

    await withOverridesFile<bool>(
        packageRoot: middleProject,
        multiSettings: settings,
        action: () async {
          final overridesPath = join(middleProject, 'pubspec_overrides.yaml');
          final contents = read(overridesPath).toList().join('\n');
          expect(contents.contains('  $primaryName:'), isTrue);
          expect(contents.contains('    path: $primaryProject'), isTrue);
          expect(contents.contains('  $outermostName:'), isTrue);
          expect(contents.contains('    path: $outermostProject'), isTrue);
          return true;
        });

    await withOverridesFile<bool>(
        packageRoot: outermostProject,
        multiSettings: settings,
        action: () async {
          final overridesPath =
              join(outermostProject, 'pubspec_overrides.yaml');
          final contents = read(overridesPath).toList().join('\n');
          expect(contents.contains('  $primaryName:'), isTrue);
          expect(contents.contains('    path: $primaryProject'), isTrue);
          expect(contents.contains('  $middleName:'), isTrue);
          expect(contents.contains('    path: $middleProject'), isTrue);
          return true;
        });
  });
}

/// @Throwing(ArgumentError)
/// @Throwing(CreateDirException)
/// @Throwing(DeleteDirException)
/// @Throwing(DuplicateKeyException)
/// @Throwing(PubSpecException)
/// @Throwing(VersionException)
void createSampleMonoProject() {
  print('creating mono repo in $monoRoot');
  _createPrimaryProject();
  _createMiddleProject();
  _createOutermostProject();

  _createMultiSettings();
}

/// @Throwing(ArgumentError)
/// @Throwing(CreateDirException)
void _createMultiSettings() {
  const multiSettings = '''
primary: "."
middle: "../middle"
outermost: "../outermost"
''';

  if (!exists(dirname(multiSettingsPathTo))) {
    createDir(dirname(multiSettingsPathTo));
  }
  multiSettingsPathTo.write(multiSettings);
}

/// @Throwing(ArgumentError)
/// @Throwing(CreateDirException)
/// @Throwing(DeleteDirException)
/// @Throwing(DuplicateKeyException)
/// @Throwing(PubSpecException)
/// @Throwing(VersionException)
void _createPrimaryProject() {
  if (exists(primaryProject)) {
    deleteDir(primaryProject);
  }
  createDir(primaryProject);

  /// Primary pubspec.yaml
  const pubspecString = '''
name: $primaryName
version: 1.0.0
description: a atest
environment:
  sdk: 1.0.0

dependencies:
  donttouchme: 1.2.0
  $middleName: 1.0.0
  $outermostName: 2.0.0
''';
  PubSpec.loadFromString(pubspecString).saveTo(primaryPubspec);

  /// pause for a moment incase an IDE is monitoring the pubspec.yaml
  /// changes. If we move too soon the .dart_tools directory may not exist.
  sleep(2);
}

/// @Throwing(ArgumentError)
/// @Throwing(CreateDirException)
/// @Throwing(DeleteDirException)
/// @Throwing(DuplicateKeyException)
/// @Throwing(PubSpecException)
/// @Throwing(VersionException)
void _createMiddleProject() {
  if (exists(middleProject)) {
    deleteDir(middleProject);
  }
  createDir(middleProject);

  /// Middle pubspec.yaml
  const pubspecString = '''
name: $middleName
version: 1.0.2
description: a atest
environment:
  sdk: 1.0.0

dependencies:
  $outermostName: 2.0.0
''';
  PubSpec.loadFromString(pubspecString).saveTo(middlePubspec);

  /// pause for a moment incase an IDE is monitoring the pubspec.yaml
  /// changes. If we move too soon the .dart_tools directory may not exist.
  sleep(2);
}

/// @Throwing(ArgumentError)
/// @Throwing(CreateDirException)
/// @Throwing(DeleteDirException)
/// @Throwing(DuplicateKeyException)
/// @Throwing(PubSpecException)
/// @Throwing(VersionException)
void _createOutermostProject() {
  if (exists(outermostProject)) {
    deleteDir(outermostProject);
  }
  createDir(outermostProject);

  /// outer
  const pubspecString = '''
name: $outermostName
version: 0.0.3
description: a atest
environment:
  sdk: 1.0.0
''';

  /// Outermost pubspec.yaml
  PubSpec.loadFromString(pubspecString).saveTo(outermostPubspec);

  /// pause for a moment incase an IDE is monitoring the pubspec.yaml
  /// changes. If we move too soon the .dart_tools directory may not exist.
  sleep(2);
}
