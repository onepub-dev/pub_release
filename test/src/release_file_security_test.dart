import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_release/src/multi_release.dart';
import 'package:pub_release/src/multi_settings.dart';
import 'package:pub_release/src/overrides.dart';
import 'package:pub_release/src/release_file_guard.dart';
import 'package:pub_release/src/release_runner.dart';
import 'package:pub_release/src/version/version.dart' as v;
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_manager/pubspec_manager.dart' hide Version;
import 'package:test/test.dart';

void main() {
  late Directory workspace;
  late String root;
  late File sentinel;
  late String pubspecPath;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('release_security_test_');
    root = p.join(workspace.path, 'package');
    Directory(root).createSync();
    sentinel = File(p.join(workspace.path, 'outside.txt'))
      ..writeAsStringSync('outside sentinel');
    pubspecPath = p.join(root, 'pubspec.yaml');
    File(pubspecPath).writeAsStringSync('''
name: example
version: 1.0.0
environment:
  sdk: '>=3.2.0 <4.0.0'
''');
  });

  tearDown(() {
    expect(sentinel.readAsStringSync(), 'outside sentinel');
    workspace.deleteSync(recursive: true);
  });

  void updateVersion() => v.updateVersionFromDetails(Version.parse('1.0.1'),
      PubSpecDetails(PubSpec.loadFromPath(pubspecPath), pubspecPath));

  for (final removeOverrides in [false, true]) {
    test('direct pubspec edit rejects link (overrides: $removeOverrides)', () {
      final original = '${File(pubspecPath).readAsStringSync()}'
          'dependency_overrides:\n  example_dependency: ^1.0.0\n';
      final outside = File(p.join(workspace.path, 'outside.yaml'))
        ..writeAsStringSync(original);
      File(pubspecPath).deleteSync();
      Link(pubspecPath).createSync(outside.path);
      final details =
          PubSpecDetails(PubSpec.loadFromPath(pubspecPath), pubspecPath);

      expect(
          () => removeOverrides
              ? details.removeOverrides()
              : v.updateVersionFromDetails(Version.parse('1.0.1'), details),
          throwsA(isA<FileSystemException>()));

      expect(outside.readAsStringSync(), original);
      expect(details.pubspec.version.semVersion, Version.parse('1.0.0'));
      expect(details.pubspec.dependencyOverrides.list, hasLength(1));
      expect(Directory(p.join(root, 'lib')).existsSync(), isFalse);
    });
  }

  for (final artifact in ['pubspec.yaml', 'pubspec.lock', '.gitignore']) {
    for (final dryrun in [false, true]) {
      test('preflight rejects $artifact before action (dryrun: $dryrun)',
          () async {
        final path = p.join(root, artifact);
        if (File(path).existsSync()) {
          File(path).deleteSync();
        }
        Link(path).createSync(sentinel.path);
        var called = false;
        await expectLater(
            ReleaseRunner(root).doRun(
                dryrun: dryrun,
                runRelease: () async {
                  called = true;
                }),
            throwsA(isA<FileSystemException>()));
        expect(called, isFalse);
        expect(Link(path).existsSync(), isTrue);
      });
    }
  }

  test('pub get rejects linked lock before checking SDK', () {
    Link(p.join(root, 'pubspec.lock')).createSync(sentinel.path);
    expect(() => ReleaseRunner(root).runPubGet(root),
        throwsA(isA<FileSystemException>()));
  });

  test('test runner rejects linked ignore before installing or running', () {
    Link(p.join(root, '.gitignore')).createSync(sentinel.path);
    expect(
        () =>
            ReleaseRunner(root).doRunTests(root, tags: null, excludeTags: null),
        throwsA(isA<FileSystemException>()));
  });

  for (final artifact in ['pubspec.yaml', 'pubspec.lock', '.gitignore']) {
    test('multi preflights later package $artifact before any update', () {
      final sibling = Directory(p.join(workspace.path, 'sibling'))
        ..createSync();
      final original = File(pubspecPath).readAsStringSync();
      final siblingPubspec = File(p.join(sibling.path, 'pubspec.yaml'))
        ..writeAsStringSync('name: sibling\nversion: 1.0.0\n');
      final outside = File(p.join(workspace.path, 'outside.yaml'))
        ..writeAsStringSync(siblingPubspec.readAsStringSync());
      final target = p.join(sibling.path, artifact);
      if (File(target).existsSync()) {
        File(target).deleteSync();
      }
      Link(target).createSync(outside.path);
      expect(
          () => updateAllVersions(
              [Package('example', root), Package('sibling', sibling.path)],
              Version.parse('1.0.1')),
          throwsA(isA<FileSystemException>()));
      expect(File(pubspecPath).readAsStringSync(), original);
      expect(outside.readAsStringSync(), 'name: sibling\nversion: 1.0.0\n');
    });
  }

  test('multi version updates accept ordinary sibling packages', () {
    final sibling = Directory(p.join(workspace.path, 'sibling'))..createSync();
    final siblingPubspec = p.join(sibling.path, 'pubspec.yaml');
    File(siblingPubspec).writeAsStringSync('name: sibling\nversion: 1.0.0\n');
    updateAllVersions(
        [Package('example', root), Package('sibling', sibling.path)],
        Version.parse('1.0.1'));
    for (final path in [pubspecPath, siblingPubspec]) {
      expect(PubSpec.loadFromPath(path).version.semVersion,
          Version.parse('1.0.1'));
    }
  });

  for (final component in ['lib', 'lib/src', 'lib/src/version']) {
    test('version rejects linked parent $component', () {
      final outside = Directory(p.join(workspace.path, 'outside'))
        ..createSync();
      final linkPath = p.join(root, component);
      Directory(p.dirname(linkPath)).createSync(recursive: true);
      Link(linkPath).createSync(outside.path);
      final original = File(pubspecPath).readAsStringSync();
      expect(updateVersion, throwsA(isA<FileSystemException>()));
      expect(File(pubspecPath).readAsStringSync(), original);
      expect(outside.listSync(), isEmpty);
    });
  }

  test('version rejects linked output', () {
    final output = v.versionLibraryPath(root);
    Directory(p.dirname(output)).createSync(recursive: true);
    Link(output).createSync(sentinel.path);
    expect(updateVersion, throwsA(isA<FileSystemException>()));
  });

  test('version updates an ordinary existing output', () {
    final output = File(v.versionLibraryPath(root));
    output.parent.createSync(recursive: true);
    output.writeAsStringSync('old version');
    updateVersion();
    expect(output.readAsStringSync(), contains("packageVersion = '1.0.1'"));
  });

  for (final name in [
    'release.notes.tmp.md',
    'CHANGELOG.md',
    'changelog.md',
    'CHANGELOG.md.bak',
  ]) {
    test('release notes reject $name before creating artifacts', () {
      Link(p.join(root, name)).createSync(sentinel.path);
      final runner = ReleaseRunner(root);
      expect(
          () => runner.generateReleaseNotes(Version.parse('1.0.1'), null,
              autoAnswer: true, dryrun: true),
          throwsA(isA<FileSystemException>()));
      if (name != 'CHANGELOG.md') {
        expect(File(p.join(root, 'CHANGELOG.md')).existsSync(), isFalse);
      }
    });
  }

  test('release notes reject a dangling changelog link', () {
    final missing = p.join(workspace.path, 'missing.md');
    Link(p.join(root, 'CHANGELOG.md')).createSync(missing);
    expect(
        () => ReleaseRunner(root)
            .applyReleaseNotesIfMissing(Version.parse('1.0.1'), '# 1.0.1'),
        throwsA(isA<FileSystemException>()));
    expect(File(missing).existsSync(), isFalse);
  });

  test('prepare notes checks temporary output before touching changelog', () {
    Link(p.join(root, 'release.notes.tmp.md')).createSync(sentinel.path);
    expect(
        () => ReleaseRunner(root).prepareReleaseNotes(
            root, Version.parse('1.0.1'), null,
            usingGit: false, autoAnswer: true, dryrun: true),
        throwsA(isA<FileSystemException>()));
    expect(File(p.join(root, 'CHANGELOG.md')).existsSync(), isFalse);
  });

  test('reading release notes rejects a linked changelog', () {
    Link(p.join(root, 'CHANGELOG.md')).createSync(sentinel.path);
    expect(() => ReleaseRunner(root).readReleaseNotes(Version.parse('1.0.1')),
        throwsA(isA<FileSystemException>()));
  });

  test('dry run rejects linked version before backup or action', () async {
    Directory(p.dirname(v.versionLibraryPath(root)))
        .createSync(recursive: true);
    Link(v.versionLibraryPath(root)).createSync(sentinel.path);
    var called = false;
    await expectLater(
        ReleaseRunner(root).doRun(
            dryrun: true,
            runRelease: () async {
              called = true;
            }),
        throwsA(isA<FileSystemException>()));
    expect(called, isFalse);
  });

  test('release notes prepend an ordinary existing changelog', () {
    final changelog = File(p.join(root, 'CHANGELOG.md'))
      ..writeAsStringSync('# 1.0.0\nold notes\n');
    expect(
        ReleaseRunner(root).applyReleaseNotesIfMissing(
            Version.parse('1.0.1'), '# 1.0.1\nnew notes'),
        isTrue);
    expect(changelog.readAsStringSync(), contains('new notes\n\n# 1.0.0'));
  });

  test('guard rejects dangling parents and paths outside package root', () {
    final missing = p.join(workspace.path, 'missing');
    Link(p.join(root, 'lib')).createSync(missing);
    expect(() => guardReleaseFile(root, v.versionLibraryPath(root)),
        throwsA(isA<FileSystemException>()));
    expect(() => guardReleaseFile(root, sentinel.path),
        throwsA(isA<FileSystemException>()));
    expect(Directory(missing).existsSync(), isFalse);
  });

  MultiSettings settings() {
    final sibling = Directory(p.join(workspace.path, 'sibling'))..createSync();
    File(p.join(sibling.path, 'pubspec.yaml'))
        .writeAsStringSync('name: sibling\nversion: 1.0.0\n');
    final settingsPath = p.join(root, MultiSettings.filename);
    File(settingsPath).writeAsStringSync('sibling: "${sibling.path}"\n');
    return MultiSettings.load(pathTo: settingsPath);
  }

  test('overrides reject linked output before invoking action', () async {
    Link(p.join(root, 'pubspec_overrides.yaml')).createSync(sentinel.path);
    var called = false;
    await expectLater(
        withOverridesFile<void>(
            packageRoot: root,
            multiSettings: settings(),
            action: () async {
              called = true;
            }),
        throwsA(isA<FileSystemException>()));
    expect(called, isFalse);
  });

  test('overrides reject dangling output', () async {
    final missing = p.join(workspace.path, 'missing.yaml');
    Link(p.join(root, 'pubspec_overrides.yaml')).createSync(missing);
    await expectLater(
        withOverridesFile<void>(
            packageRoot: root, multiSettings: settings(), action: () async {}),
        throwsA(isA<FileSystemException>()));
    expect(File(missing).existsSync(), isFalse);
  });

  for (final throwsAction in [false, true]) {
    test('overrides restore and clean backup (action throws: $throwsAction)',
        () async {
      final overrides = File(p.join(root, 'pubspec_overrides.yaml'));
      final original = '# original overrides for ${workspace.path}\n';
      overrides.writeAsStringSync(original);
      Link('${overrides.path}.pub_release.bak').createSync(sentinel.path);
      final actionError = StateError('action failed');
      final backups = <Directory>[];
      final backupRoot = Directory(p.join(workspace.path, 'backups'))
        ..createSync();
      final operation = IOOverrides.runZoned(
          () => withOverridesFile<int>(
              packageRoot: root,
              multiSettings: settings(),
              action: () async {
                expect(overrides.readAsStringSync(), contains('  sibling:'));
                expect(overrides.readAsStringSync(),
                    contains(p.join(workspace.path, 'sibling')));
                for (final directory
                    in backupRoot.listSync().whereType<Directory>()) {
                  final backup =
                      File(p.join(directory.path, 'pubspec_overrides.yaml'));
                  if (backup.existsSync() &&
                      backup.readAsStringSync() == original) {
                    backups.add(directory);
                  }
                }
                expect(backups, hasLength(1));
                if (throwsAction) {
                  throw actionError;
                }
                return 42;
              }),
          getSystemTempDirectory: () => backupRoot);
      if (throwsAction) {
        await expectLater(operation, throwsA(same(actionError)));
      } else {
        expect(await operation, 42);
      }
      expect(overrides.readAsStringSync(), original);
      expect(backups.single.existsSync(), isFalse);
      expect(Link('${overrides.path}.pub_release.bak').existsSync(), isTrue);
    });
  }

  test('overrides do not restore a stale fixed backup when none existed',
      () async {
    final overrides = File(p.join(root, 'pubspec_overrides.yaml'));
    final stale = File('${overrides.path}.pub_release.bak')
      ..writeAsStringSync('stale backup');
    await withOverridesFile<void>(
        packageRoot: root, multiSettings: settings(), action: () async {});
    expect(overrides.existsSync(), isFalse);
    expect(stale.readAsStringSync(), 'stale backup');
  });

  test('overrides clean up after action exception with no original', () async {
    final backupRoot = Directory(p.join(workspace.path, 'backups'))
      ..createSync();
    final actionError = StateError('action failed');
    final operation = IOOverrides.runZoned(
        () => withOverridesFile<void>(
            packageRoot: root,
            multiSettings: settings(),
            action: () => Future<void>.error(actionError)),
        getSystemTempDirectory: () => backupRoot);
    await expectLater(operation, throwsA(same(actionError)));
    expect(File(p.join(root, 'pubspec_overrides.yaml')).existsSync(), isFalse);
    expect(backupRoot.listSync(), isEmpty);
  });
}
