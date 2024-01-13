@Timeout(Duration(minutes: 10))
library;

import 'package:dcli/dcli.dart';
import 'package:path/path.dart' hide equals;
import 'package:pub_release/src/multi_settings.dart';
import 'package:pub_release/src/overrides.dart';
import 'package:pubspec_manager/pubspec_manager.dart';
import 'package:test/test.dart';

final monoRoot = createTempDir();

const primaryName = 'primary';
const middleName = 'middle';
const outermostName = 'outermost';

const donttouchmepath = '../some/path/';

final primaryProject = join(monoRoot, primaryName);
final middleProject = join(monoRoot, middleName);
final outermostProject = join(monoRoot, outermostName);

final primaryPubspec = join(primaryProject, 'pubspec.yaml');
final middlePubspec = join(middleProject, 'pubspec.yaml');
final outermostPubspec = join(outermostProject, 'pubspec.yaml');

final multiSettingsPathTo =
    join(primaryProject, 'tool', MultiSettings.filename);

void main() {
  setUpAll(() async {
    createSampleMonoProject();
  });

  test('overrides ...', () async {
    MultiSettings.homeProjectPath = primaryProject;
    var pubspecPrimary = PubSpec.loadFromPath(primaryPubspec);
    var pubspecMiddle = PubSpec.loadFromPath(middlePubspec);
    var pubspecOutermost = PubSpec.loadFromPath(outermostPubspec);
    addOverrides(primaryProject);

    /// reload the pubspec as we have just changed them.
    pubspecPrimary = PubSpec.loadFromPath(primaryPubspec);
    pubspecMiddle = PubSpec.loadFromPath(middlePubspec);
    pubspecOutermost = PubSpec.loadFromPath(outermostPubspec);

    expect(pubspecPrimary.dependencyOverrides.length, equals(3));
    expect(pubspecPrimary.dependencyOverrides.exists('donttouchme'), isTrue);
    expect(pubspecPrimary.dependencyOverrides['donttouchme']! is DependencyPath,
        isTrue);
    expect(
        (pubspecPrimary.dependencyOverrides['donttouchme']! as DependencyPath)
            .path,
        equals(donttouchmepath));

    expectPath(pubspecPrimary, middleName, middleProject);
    expectPath(pubspecPrimary, outermostName, outermostProject);

    expect(pubspecMiddle.dependencyOverrides.length, equals(1));
    expectPath(pubspecMiddle, outermostName, outermostProject);

    expect(pubspecOutermost.dependencyOverrides.length, equals(0));
  });
}

void expectPath(PubSpec pubspec, String name, String projectPath) {
  expect(pubspec.dependencyOverrides.exists(name), isTrue);
  expect(pubspec.dependencyOverrides[name]!.name, equals(name));
  expect(pubspec.dependencyOverrides[name]! is DependencyPath, isTrue);
  expect((pubspec.dependencyOverrides[name]! as DependencyPath).path,
      equals(relative(projectPath, from: primaryProject)));
}

void createSampleMonoProject() {
  print('creating mono repo in $monoRoot');
  _createPrimaryProject();
  _createMiddleProject();
  _createOutermostProject();

  _createMultiSettings();
}

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

dependency_overrides:
  donttouchme:
    path: $donttouchmepath
''';
  PubSpec.loadFromString(pubspecString).saveTo(primaryPubspec);

  /// pause for a moment incase an IDE is monitoring the pubspec.yaml
  /// changes. If we move too soon the .dart_tools directory may not exist.
  sleep(2);
}

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
