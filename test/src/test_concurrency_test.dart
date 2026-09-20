import 'dart:io';

import 'package:args/args.dart';
import 'package:dcli/dcli.dart' hide Settings, isEmpty;
import 'package:dcli/posix.dart';
import 'package:path/path.dart' hide equals;
import 'package:pub_release/pub_release.dart';
import 'package:test/test.dart';

import '../../bin/pub_release.dart' as cli;

void main() {
  late Directory temp;
  late String settingsPath;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('pub_release_concurrency_');
    settingsPath = join(temp.path, '.pubrelease.yaml');
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
  });

  Settings loadSettings(String yaml) {
    File(settingsPath).writeAsStringSync(yaml);
    return Settings.loadFromPath(pathToSettings: settingsPath);
  }

  ArgResults parse(List<String> args) =>
      (ArgParser()..addOption('test-concurrency')).parse(args);

  test('missing setting preserves the runner default', () {
    final settings = loadSettings('format: false\n');
    expect(settings.testConcurrency, isNull);
    expect(cli.getTestConcurrency(parse([]), settings), isNull);
  });

  test('loads concurrency from YAML', () {
    final settings = loadSettings('test-concurrency: 1\n');
    expect(settings.testConcurrency, 1);
    expect(cli.getTestConcurrency(parse([]), settings), 1);
  });

  test('CLI overrides YAML', () {
    final settings = loadSettings('test-concurrency: 1\n');
    expect(
        cli.getTestConcurrency(parse(['--test-concurrency=4']), settings), 4);
  });

  test('CLI works without a YAML concurrency setting', () {
    final settings = loadSettings('format: false\n');
    expect(
        cli.getTestConcurrency(parse(['--test-concurrency=2']), settings), 2);
  });

  for (final value in ['0', '-1', '1.5', 'true', 'many', '"2"']) {
    test('rejects invalid YAML concurrency $value', () {
      expect(() => loadSettings('test-concurrency: $value\n'),
          throwsA(isA<PubReleaseException>()));
    });
  }

  for (final value in ['0', '-1', '1.5', 'many', '']) {
    test('rejects invalid CLI concurrency "$value"', () {
      final settings = loadSettings('test-concurrency: 1\n');
      expect(
          () => cli.getTestConcurrency(
              parse(['--test-concurrency=$value']), settings),
          throwsA(isA<PubReleaseException>()));
    });
  }

  for (final concurrency in <int?>[null, 1, 4]) {
    test('test runner forwards concurrency $concurrency', () async {
      final executable = join(temp.path, 'critical_test');
      File(executable).writeAsStringSync('#!/bin/sh\n'
          r'''printf '%s\n' "$@" > test-args.txt'''
          '\n');
      chmod(executable, permission: '700');
      Directory(join(temp.path, 'test')).createSync();
      // Avoid git changes: the tracker is already ignored in this fixture.
      File(join(temp.path, '.gitignore'))
          .writeAsStringSync('.failed_tracker\n');

      await withEnvironmentAsync(() async {
        final success = ReleaseRunner(temp.path).doRunTests(temp.path,
            tags: 'unit', excludeTags: 'slow', testConcurrency: concurrency);
        expect(success, isTrue);
      }, environment: {'PATH': '${temp.path}:${env['PATH']}'});

      final arguments =
          File(join(temp.path, 'test-args.txt')).readAsLinesSync();
      expect(arguments, containsAll(['--tags=unit', '--exclude-tags=slow']));
      expect(
          arguments.where((arg) => arg.startsWith('--concurrency=')),
          concurrency == null
              ? isEmpty
              : equals(['--concurrency=$concurrency']));
    }, skip: Platform.isWindows ? 'Uses a POSIX executable fixture.' : false);
  }
}
