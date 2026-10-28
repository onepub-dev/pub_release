import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_release/src/create_release.dart';
import 'package:pubspec_manager/pubspec_manager.dart';
import 'package:test/test.dart';

// These tests only resolve local paths. They never compile or contact GitHub.
void main() {
  late Directory sandbox;
  late Directory package;
  late Directory bin;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('release_resolution_test_');
    package = Directory(p.join(sandbox.path, 'package'))..createSync();
    bin = Directory(p.join(package.path, 'bin'))..createSync();
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  PubSpec executable(String name, {String? script}) =>
      PubSpec.loadFromString('name: example\n')
        ..executables.add(name: name, script: script);

  test('unmapped executable resolves its own source', () {
    final source = File(p.join(bin.path, 'tool.dart'))..writeAsStringSync('');
    final result =
        resolveExecutableAssets(executable('tool'), packageRoot: package.path);

    expect(result.single.scriptPath, source.resolveSymbolicLinksSync());
    expect(result.single.assetName, 'tool');
  });

  test('script mapping selects source and retains advertised asset alias', () {
    final source = File(p.join(bin.path, 'main.dart'))..writeAsStringSync('');
    final result = resolveExecutableAssets(executable('tool', script: 'main'),
        packageRoot: package.path);

    expect(result.single.scriptPath, source.resolveSymbolicLinksSync());
    expect(result.single.assetName, 'tool');
    expect(File(p.join(bin.path, 'tool.dart')).existsSync(), isFalse);
  });

  test('loaded pubspec determines root independently of working directory', () {
    final source = File(p.join(bin.path, 'main.dart'))..writeAsStringSync('');
    final pubspecFile = File(p.join(package.path, 'pubspec.yaml'))
      ..writeAsStringSync('name: example\nexecutables:\n  tool: main\n');
    final result =
        resolveExecutableAssets(PubSpec.loadFromPath(pubspecFile.path));

    expect(result.single.scriptPath, source.resolveSymbolicLinksSync());
    expect(result.single.assetName, 'tool');
  });

  for (final invalid in [
    '',
    '.',
    '..',
    '../outside',
    '../../outside',
    'nested/tool',
    r'..\outside',
    r'nested\tool',
    '/absolute',
    r'C:\absolute',
    'C:relative',
    r'\\server\share',
    'tool:stream',
    'tool.',
    'tool ',
    'NUL',
  ]) {
    test('rejects advertised name "$invalid" even with a safe mapping', () {
      File(p.join(bin.path, 'main.dart')).writeAsStringSync('');
      final pubspec = executable('tool', script: 'main');
      pubspec.executables.list.single.name = invalid;

      expect(() => resolveExecutableAssets(pubspec, packageRoot: package.path),
          throwsArgumentError);
    });

    if (invalid.isNotEmpty) {
      test('rejects script mapping "$invalid" with a safe alias', () {
        final pubspec = executable('tool');
        pubspec.executables.list.single.script = invalid;

        expect(
            () => resolveExecutableAssets(pubspec, packageRoot: package.path),
            throwsArgumentError);
      });
    }
  }

  test('rejects traversal to an existing adjacent Dart source', () {
    File(p.join(sandbox.path, 'outside.dart')).writeAsStringSync('');
    expect(
        () => resolveExecutableAssets(
            executable('tool', script: '../../outside'),
            packageRoot: package.path),
        throwsArgumentError);
  });

  test('rejects missing source and directory masquerading as source', () {
    expect(
        () => resolveExecutableAssets(executable('tool'),
            packageRoot: package.path),
        throwsArgumentError);
    Directory(p.join(bin.path, 'tool.dart')).createSync();
    expect(
        () => resolveExecutableAssets(executable('tool'),
            packageRoot: package.path),
        throwsArgumentError);
  });

  test('rejects source symlink to adjacent package source', () {
    final outside = File(p.join(sandbox.path, 'outside.dart'))
      ..writeAsStringSync('');
    Link(p.join(bin.path, 'tool.dart')).createSync(outside.path);

    expect(
        () => resolveExecutableAssets(executable('tool'),
            packageRoot: package.path),
        throwsArgumentError);
  },
      skip:
          Platform.isWindows ? 'Symlink creation requires privileges.' : false);

  test('allows source link that remains inside package', () {
    final lib = Directory(p.join(package.path, 'lib'))..createSync();
    final source = File(p.join(lib.path, 'main.dart'))..writeAsStringSync('');
    Link(p.join(bin.path, 'tool.dart')).createSync(source.path);

    final result =
        resolveExecutableAssets(executable('tool'), packageRoot: package.path);

    expect(result.single.scriptPath, source.resolveSymbolicLinksSync());
  },
      skip:
          Platform.isWindows ? 'Symlink creation requires privileges.' : false);

  test('allows bin link that remains inside package', () {
    final scripts = Directory(p.join(package.path, 'scripts'))..createSync();
    final source = File(p.join(scripts.path, 'tool.dart'))
      ..writeAsStringSync('');
    bin.deleteSync();
    Link(bin.path).createSync(scripts.path);

    final result =
        resolveExecutableAssets(executable('tool'), packageRoot: package.path);

    expect(result.single.scriptPath, source.resolveSymbolicLinksSync());
  },
      skip:
          Platform.isWindows ? 'Symlink creation requires privileges.' : false);

  test('rejects linked bin directory outside package', () {
    final outside = Directory(p.join(sandbox.path, 'outside'))..createSync();
    File(p.join(outside.path, 'tool.dart')).writeAsStringSync('');
    bin.deleteSync();
    Link(bin.path).createSync(outside.path);

    expect(
        () => resolveExecutableAssets(executable('tool'),
            packageRoot: package.path),
        throwsArgumentError);
  },
      skip:
          Platform.isWindows ? 'Symlink creation requires privileges.' : false);
}
