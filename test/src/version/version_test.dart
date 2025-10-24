import 'package:pub_release/src/version/version.dart' as v;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('version', () {
    test('minor to dev', () {
      final currentVersion = Version.parse('7.1.19');
      final version = v.PreReleaseVersion('Select version', currentVersion);
      final results = version.getNextVersions(currentVersion, 'dev');
      expect(results.length, equals(5));
      expect(results[0].version, equals(currentVersion));
      expect(results[1].version, equals(Version.parse('7.1.20-dev.1')));
      expect(results[2].version, equals(Version.parse('7.2.0-dev.1')));
      expect(results[3].version, equals(Version.parse('8.0.0-dev.1')));
      expect(results[4] is v.CustomVersion, isTrue);
    });

    test('patch to beta', () {
      final currentVersion = Version.parse('7.1.19');
      final version = v.PreReleaseVersion('Select version', currentVersion);
      final results = version.getNextVersions(currentVersion, 'beta');
      expect(results.length, equals(5));
      expect(results[0].version, equals(currentVersion));
      expect(results[1].version, equals(Version.parse('7.1.20-beta.1')));
      expect(results[2].version, equals(Version.parse('7.2.0-beta.1')));
      expect(results[3].version, equals(Version.parse('8.0.0-beta.1')));
      expect(results[4] is v.CustomVersion, isTrue);
    });

    test('minor to beta', () {
      final currentVersion = Version.parse('7.1.0');
      final version = v.PreReleaseVersion('Select version', currentVersion);
      final results = version.getNextVersions(currentVersion, 'beta');
      expect(results.length, equals(5));
      expect(results[0].version, equals(currentVersion));
      expect(results[1].version, equals(Version.parse('7.1.1-beta.1')));
      expect(results[2].version, equals(Version.parse('7.2.0-beta.1')));
      expect(results[3].version, equals(Version.parse('8.0.0-beta.1')));
      expect(results[4] is v.CustomVersion, isTrue);
    });

    test('major to beta', () {
      final currentVersion = Version.parse('7.0.0');
      final version = v.PreReleaseVersion('Select version', currentVersion);
      final results = version.getNextVersions(currentVersion, 'beta');
      expect(results.length, equals(5));
      expect(results[0].version, equals(currentVersion));
      expect(results[1].version, equals(Version.parse('7.0.1-beta.1')));
      expect(results[2].version, equals(Version.parse('7.1.0-beta.1')));
      expect(results[3].version, equals(Version.parse('8.0.0-beta.1')));
      expect(results[4] is v.CustomVersion, isTrue);
    });

    test('dev ', () {
      final currentVersion = Version.parse('7.1.1-dev.1');
      final results = v.determineVersionToOffer(currentVersion);
      expect(results.length, equals(8));
      expect(results[0].version, equals(currentVersion));
      expectVersion(results[1], '7.1.1-dev.2', 'Small Patch');
      expectVersion(results[2], '7.1.1-alpha.1', 'Alpha');
      expectVersion(results[3], '7.1.1-beta.1', 'Beta');
      expectVersion(results[4], '7.1.1', 'Release');
      expectVersion(results[5], '7.2.0', 'Non-breaking change');
      expectVersion(results[6], '8.0.0', 'Breaking change');
      expect(results[7] is v.CustomVersion, isTrue);
    });
    test('alpha to beta', () {
      final currentVersion = Version.parse('7.0.0-alpha.1');
      final results = v.determineVersionToOffer(currentVersion);
      expect(results.length, equals(7));
      expect(results[0].version, equals(currentVersion));
      expect(results[1].version, equals(Version.parse('7.0.0-alpha.2')));
      expect(results[2].version, equals(Version.parse('7.0.0-beta.1')));
      expect(results[3].version, equals(Version.parse('7.0.0')));
      expect(results[4].version, equals(Version.parse('7.1.0')));
      expect(results[5].version, equals(Version.parse('8.0.0')));
      expect(results[6] is v.CustomVersion, isTrue);
    });

    test('beta to release', () {
      final currentVersion = Version.parse('7.1.1-beta.1');
      final results = v.determineVersionToOffer(currentVersion);
      expect(results.length, equals(6));
      expect(results[0].version, equals(currentVersion));
      expectVersion(results[1], '7.1.1-beta.2', 'Small Patch');
      expectVersion(results[2], '7.1.1', 'Release');
      expectVersion(results[3], '7.2.0', 'Non-breaking change');
      expectVersion(results[4], '8.0.0', 'Breaking change');
      expect(results[5] is v.CustomVersion, isTrue);
    });

    test('release to pre-release', () {
      final currentVersion = Version.parse('7.1.1');
      final results = v.determineVersionToOffer(currentVersion);
      expect(results.length, equals(6));
      expect(results[0].version, equals(currentVersion));
      expectVersion(results[1], '7.1.2', 'Small Patch');
      expectVersion(results[2], '7.2.0', 'Non-breaking change');
      expectVersion(results[3], '8.0.0', 'Breaking change');
      expect(results[4] is v.PreReleaseVersion, isTrue);
      expect(results[5] is v.CustomVersion, isTrue);
    });
  });
}

void expectVersion(v.NewVersion result, String version, String message) {
  expect(result.version, equals(Version.parse(version)));
  expect(result.message, equals(message.padRight(25)));
}

/*
Paths
release to prerelease

User is on dev 
7.1.1.dev-1 -> 
 -> 7.1.1-dev.2
 -> 7.1.1-alpha.1
 -> 7.1.1-beta.1
 -> 7.1.1
 -> 7.2.0
 -> 8.0.0


User is on alpha 
7.1.1.alpha-1 -> 
 -> 7.1.1-alpha.2
 -> 7.1.1-beta.1
 -> 7.1.1
 -> 7.2.0
 -> 8.0.0

User is on beta 
7.1.1.beta-1 -> 
 -> 7.1.1-beta.2
 -> 7.1.1
 -> 7.2.0
 -> 8.0.0




*/
