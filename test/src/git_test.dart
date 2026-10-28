import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_release/src/git.dart';
import 'package:test/test.dart';

void main() {
  late Directory repository;
  late Git git;

  String runGit(List<String> arguments) {
    final result = Process.runSync('git', arguments,
        workingDirectory: repository.path,
        environment: {
          'GIT_CONFIG_NOSYSTEM': '1',
          'GIT_CONFIG_GLOBAL': Platform.isWindows ? 'NUL' : '/dev/null',
          'GIT_AUTHOR_NAME': 'Git test',
          'GIT_AUTHOR_EMAIL': 'test@example.invalid',
          'GIT_COMMITTER_NAME': 'Git test',
          'GIT_COMMITTER_EMAIL': 'test@example.invalid'
        });
    if (result.exitCode != 0) {
      throw ProcessException(
          'git', arguments, result.stderr as String, result.exitCode);
    }
    return (result.stdout as String).trim();
  }

  setUp(() {
    repository = Directory.systemTemp.createTempSync('pub-release-git-');
    runGit(['init']);
    runGit([
      '-c',
      'commit.gpgsign=false',
      'commit',
      '--allow-empty',
      '-m',
      'base'
    ]);
    final package = Directory(p.join(repository.path, 'nested_package'))
      ..createSync();
    git = Git(package.path);
    expect(git.usingGit, isTrue);
  });

  tearDown(() {
    repository.deleteSync(recursive: true);
  });

  void addCommit() {
    runGit([
      '-c',
      'commit.gpgsign=false',
      'commit',
      '--allow-empty',
      '-m',
      'after release'
    ]);
  }

  test('no tags returns all history in the specified repository', () {
    addCommit();
    expect(git.getLatestTag(), isNull);
    expect(git.getCommitMessages(null), ['after release', 'base']);
  });

  for (final annotated in [false, true]) {
    test(
        'reads history after an ${annotated ? 'annotated' : 'lightweight'} tag',
        () {
      runGit(annotated
          ? ['-c', 'tag.gpgsign=false', 'tag', '-a', 'v1.0.0', '-m', 'release']
          : ['-c', 'tag.gpgsign=false', 'tag', 'v1.0.0']);
      addCommit();
      expect(git.getLatestTag(), 'v1.0.0');
      expect(git.getCommitMessages('v1.0.0'), ['after release']);
    });
  }

  test('a quote-bearing valid tag cannot inject git log options', () {
    final proof = File(p.join(repository.path, 'proof'));
    final tag = 'HEAD""--all""--output=${proof.path}""--format=AUDIT""';
    runGit(['check-ref-format', 'refs/tags/$tag']);
    runGit(['-c', 'tag.gpgsign=false', 'tag', tag]);
    addCommit();
    expect(git.getLatestTag(), tag);
    expect(git.getCommitMessages(tag), ['after release']);
    expect(proof.existsSync(), isFalse);
  },
      skip: Platform.isWindows
          ? 'Tag contains characters forbidden on Windows'
          : false);

  test('missing tags fail closed even when a branch has the same name', () {
    runGit(['branch', 'missing']);
    expect(() => git.getCommitMessages('missing'),
        throwsA(isA<ProcessException>()));
  });

  test('missing exact tag does not resolve a shadow ref', () {
    runGit(['update-ref', 'refs/refs/tags/shadow', 'HEAD']);
    expect(() => git.getCommitMessages('shadow'),
        throwsA(isA<ProcessException>()));
  });

  test('revision expressions cannot replace an exact tag', () {
    runGit(['-c', 'tag.gpgsign=false', 'tag', 'release']);
    for (final tag in [
      'release^{}',
      'release~0',
      'release..HEAD',
      'release@{0}'
    ]) {
      expect(
          () => git.getCommitMessages(tag), throwsA(isA<ProcessException>()));
    }
  });

  test('tags pointing at non-commit objects fail closed', () {
    final tree = runGit(['rev-parse', 'HEAD^{tree}']);
    runGit(['update-ref', 'refs/tags/tree', tree]);
    expect(
        () => git.getCommitMessages('tree'), throwsA(isA<ProcessException>()));
  });

  test('a tag at HEAD returns no messages', () {
    runGit(['-c', 'tag.gpgsign=false', 'tag', 'current']);
    expect(git.getCommitMessages('current'), isEmpty);
  });
}
