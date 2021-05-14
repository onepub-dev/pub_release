@Timeout(Duration(minutes: 10))
import 'package:dcli/dcli.dart' hide equals;
import 'package:pub_release/src/overrides.dart';
import 'package:pub_release/src/multi_settings.dart';
import 'package:pubspec/pubspec.dart' show PathReference;
import 'package:test/test.dart';

late final monoRoot = createTempDir();

const primaryName = 'primary';
const middleName = 'middle';
const outermostName = 'outermost';

const donttouchmepath = '../some/path/';

late final primaryProject = join(monoRoot, primaryName);
late final middleProject = join(monoRoot, middleName);
late final outermostProject = join(monoRoot, outermostName);

late final primaryPubspec = join(primaryProject, 'pubspec.yaml');
late final middlePubspec = join(middleProject, 'pubspec.yaml');
late final outermostPubspec = join(outermostProject, 'pubspec.yaml');

late final multiSettingsPathTo =
    join(primaryProject, 'tool', MultiSettings.filename);

void main() {
  setUpAll(() async {
    createSampleMonoProject();
  });

  test('overrides ...', () async {
    MultiSettings.homeProjectPath = primaryProject;
    var pubspecPrimary = PubSpec.fromFile(primaryPubspec);
    var pubspecMiddle = PubSpec.fromFile(middlePubspec);
    var pubspecOutermost = PubSpec.fromFile(outermostPubspec);
    addOverrides(primaryProject);

    /// reload the pubspec as we have just changed them.
    pubspecPrimary = PubSpec.fromFile(primaryPubspec);
    pubspecMiddle = PubSpec.fromFile(middlePubspec);
    pubspecOutermost = PubSpec.fromFile(outermostPubspec);

    expect(pubspecPrimary.dependencyOverrides.entries.length, equals(3));
    expect(
        pubspecPrimary.dependencyOverrides.containsKey('donttouchme'), isTrue);
    expect(
        pubspecPrimary.dependencyOverrides['donttouchme']!.reference
            is PathReference,
        isTrue);
    expect(
        (pubspecPrimary.dependencyOverrides['donttouchme']!.reference
                as PathReference)
            .path,
        equals(donttouchmepath));

    expectPath(pubspecPrimary, middleName, middleProject);
    expectPath(pubspecPrimary, outermostName, outermostProject);

    expect(pubspecMiddle.dependencyOverrides.entries.length, equals(1));
    expectPath(pubspecMiddle, outermostName, outermostProject);

    expect(pubspecOutermost.dependencyOverrides.entries.length, equals(0));
  });
}

void expectPath(PubSpec pubspec, String name, String projectPath) {
  expect(pubspec.dependencyOverrides.containsKey(name), isTrue);
  expect(pubspec.dependencyOverrides[name]!.name, equals(name));
  expect(pubspec.dependencyOverrides[name]!.reference is PathReference, isTrue);
  expect((pubspec.dependencyOverrides[name]!.reference as PathReference).path,
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

  const pubspecString = '''
name: $primaryName

dependencies:
  donttouchme: 1.2.0
  $middleName: 1.0.0
  $outermostName: 2.0.0

dependency_overrides:
  donttouchme:
    path: $donttouchmepath
''';
  final pubspec = PubSpec.fromString(pubspecString);

  pubspec.saveToFile(primaryPubspec);
}

void _createMiddleProject() {
  if (exists(middleProject)) {
    deleteDir(middleProject);
  }
  createDir(middleProject);

  const pubspecString = '''
name: $middleName

dependencies:
  $outermostName: 2.0.0
''';
  final pubspec = PubSpec.fromString(pubspecString);

  pubspec.saveToFile(middlePubspec);
}

void _createOutermostProject() {
  if (exists(outermostProject)) {
    deleteDir(outermostProject);
  }
  createDir(outermostProject);

  final pubspec = PubSpec.fromString("name: $outermostName");

  pubspec.saveToFile(outermostPubspec);
}
