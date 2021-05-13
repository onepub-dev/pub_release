@Timeout(Duration(minutes: 10))
import 'package:dcli/dcli.dart';
import 'package:pub_release/src/multi_release.dart';
import 'package:pub_release/src/release_runner.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

late final testRoot = createTempDir();
void main() {
  setUpAll(() {
    _createTestMonoRepo();
  });
  test('multi release ...', () async {
    multiRelease(
        join(testRoot, 'top'), VersionMethod.set, Version.parse('3.0.0'),
        dryrun: true,
        autoAnswer: true,
        runTests: true,
        tags: null,
        excludeTags: 'bad');
  });
}

void _createTestMonoRepo() {
  final projectRoot = DartProject.fromPath(pwd).pathToProjectRoot;

  copyTree(join(projectRoot, 'test_packages'), testRoot, includeHidden: true);
}
