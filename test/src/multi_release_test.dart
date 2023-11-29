@Timeout(Duration(minutes: 10))
library;

import 'package:dcli/dcli.dart';
import 'package:path/path.dart' hide equals;
import 'package:pub_release/src/multi_release.dart';
import 'package:pub_release/src/multi_settings.dart';
import 'package:pub_release/src/release_runner.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {});
  test('multi release ...', () async {
    withTempDir((testRoot) {
      _createTestMonoRepo(testRoot);
      multiRelease(
          join(testRoot, 'top'), VersionMethod.set, Version.parse('3.0.0'),
          dryrun: true,
          autoAnswer: true,
          runTests: true,
          tags: null,
          excludeTags: 'bad',
          format: true,
          useGit: true);
    }, keep: true);
  });

  // test('multi release dcli', () async {
  //   withTempDir((testRoot) {
  //     multiRelease(join(HOME, 'git', 'dcli', 'dcli'), VersionMethod.set,
  //         Version.parse('3.0.0'),
  //         dryrun: true,
  //         autoAnswer: true,
  //         runTests: false,
  //         tags: null,
  //         excludeTags: 'bad',
  //         useGit: false);
  //   }, keep: true);
  // });

  test('highest version', () {
    withTempDir((testRoot) {
      _createTestMonoRepo(testRoot);
      MultiSettings.homeProjectPath = join(testRoot, 'top');
      final settings = MultiSettings.load(
          pathTo: join(testRoot, 'top', 'tool', MultiSettings.filename));
      final version = settings.getHighestVersion();
      expect(version, equals(Version.parse('1.0.3')));
    });
  });
}

void _createTestMonoRepo(String testRoot) {
  final projectRoot = DartProject.fromPath(pwd).pathToProjectRoot;

  copyTree(join(projectRoot, 'test_packages'), testRoot, includeHidden: true);

  /// git init the project so that we can test the git management.
  'git init'.start(workingDirectory: testRoot);
  'git add *'.start(workingDirectory: testRoot);
  'git commit -m "Initial commit"'.start(workingDirectory: testRoot);
}
