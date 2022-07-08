/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_semver/pub_semver.dart';

class Git {
  Git(this.pathToPackageRoot);
  bool? _usingGit;
  String pathToPackageRoot;

  bool get usingGit {
    if (_usingGit == null) {
      final root = findGitRoot();
      _usingGit = root != null;
    }

    return _usingGit ?? false;
  }

  String? get pathToGitRoot => findGitRoot();

  String? findGitRoot() {
    var current = pathToPackageRoot;
    var found = false;
    while (current != rootPath && found == false) {
      found = Directory(join(current, '.git')).existsSync();
      if (found) {
        break;
      }
      current = dirname(current);
    }

    return found ? current : null;
  }

  bool tagExists(String tagName) {
    assert(_usingGit ?? false, 'Must be using git');
    final tags = 'git tag --list'.toList();

    return tags.contains(tagName);
  }

  void push(String tag) {
    assert(_usingGit ?? false, 'Must be using git');
    print('Pushing release to git...');
    if (hasRemote) {
      'git push origin "$tag"'.start(workingDirectory: pathToGitRoot);
    } else {
      print(orange('Skipping git push as no git remote has been defined.'));
    }
  }

  /// Check that all files are committed.
  void checkAllFilesCommited() {
    assert(_usingGit ?? false, 'Must be using git');

    if (isCommitRequired) {
      print('');
      print('You have uncommited files');
      print(red('You MUST commit them before continuing.'));

      exit(1);
    }
  }

  void commitAll(String message) {
    final uncommited = getUncommited();
    addAll(uncommited);
    commit(message);
  }

  // void commitVersion(String message) {
  //   add('CHANGELOG.md');
  //   add('lib/src/version/version.g.dart');
  //   add('pubspec.yaml');
  //   add('pubspec.lock');

  //   if (isCommitRequired) {
  //     commit(message);
  //   }
  // }

  void add(String pathToFile) {
    'git add $pathToFile'.start(workingDirectory: pathToGitRoot);
  }

  void addAll(List<String> commitList) {
    commitList.forEach(add);
  }

  void commit(String message) {
    /// occasionally there will be nothing commit.
    /// this can occur after a failed release when
    /// we try re-run the release.
    if (isCommitRequired) {
      'git commit -m "$message"'.start(workingDirectory: pathToGitRoot);
    }
  }

  bool get isCommitRequired =>
      usingGit &&
      'git status --porcelain'
          .start(workingDirectory: pathToGitRoot, progress: Progress.capture())
          .lines
          .isNotEmpty;

  /// Check that all files are committed.
  void checkCommit({required bool autoAnswer}) {
    assert(_usingGit ?? false, 'Must be using git');

    if (isCommitRequired) {
      print('');
      print('You have uncommited file.');
      print(orange('You MUST commit them before continuing.'));

      if (autoAnswer || confirm('Do you want to list them?')) {
        // we get the list again as the user is likely to have
        // committed files after seeing the question.
        final notCommited = getUncommited();
        print(notCommited.join('\n'));
      }
      if (!autoAnswer &&
          !confirm('Do you want to continue with the release?')) {
        exit(1);
      }
    }
  }

  /// Returns the list of uncommited files with paths relative
  /// to the git root.
  List<String> getUncommited() {
    final lines = 'git status --porcelain'
        .start(workingDirectory: pathToGitRoot, progress: Progress.capture())
        .lines;

    final uncommited = <String>[];
    for (final line in lines) {
      final parts = line.trim().split(' ');
      uncommited.add(parts[1]);
      print(parts[1]);
    }
    return uncommited;
  }

  String? getLatestTag() {
    assert(_usingGit ?? false, 'Must be using git');
    return 'git --no-pager tag --sort=-creatordate'.firstLine;
  }

  List<String> getCommitMessages(String? fromTag) {
    assert(_usingGit ?? false, 'Must be using git');

    if (fromTag == null) {
      return 'git --no-pager log --pretty=format:"%s" HEAD'.toList();
    } else {
      return 'git --no-pager log --pretty=format:"%s" $fromTag..HEAD'.toList();
    }
  }

  void deleteGitTag(Version newVersion) {
    assert(_usingGit ?? false, 'Must be using git');
    'git tag -d $newVersion'.start(workingDirectory: pathToGitRoot);
    if (hasRemote) {
      'git push --follow-tags'.start(workingDirectory: pathToGitRoot);
    }
  }

  void pushReleaseTag(Version? version, {required bool autoAnswer}) {
    assert(_usingGit ?? false, 'Must be using git');
    final tagName = '$version';
    // Check if the tag already exists and offer to replace it if it does.
    if (tagExists(tagName)) {
      if (autoAnswer ||
          confirm(
              'The tag $tagName already exists. Do you want to replace it?')) {
        'git tag -d $tagName'.start(workingDirectory: pathToGitRoot);
        if (hasRemote) {
          'git push --follow-tags'.start(workingDirectory: pathToGitRoot);
        }
        print('');
      }
    }

    print('Creating git tag.');
    'git tag -a $tagName -m "released $tagName"'
        .start(workingDirectory: pathToGitRoot);
    if (hasRemote) {
      'git push origin :refs/tags/$tagName'
          .start(workingDirectory: pathToGitRoot);
      'git push --follow-tags'.start(workingDirectory: pathToGitRoot);
    }
  }

  void pull() {
    'git pull'.start(
        workingDirectory: pathToGitRoot,
        nothrow: true,
        progress: Progress.printStdErr());
  }

  bool get hasRemote => 'git remote'
      .start(
          workingDirectory: pathToGitRoot,
          progress: Progress.capture(captureStderr: false))
      .lines
      .isNotEmpty;

  String get pathToGitIgnore => join(pathToPackageRoot, '.gitignore');

  void addGitIgnore(String fileToIgnore) {
    if (!exists(pathToGitIgnore)) {
      touch(pathToGitIgnore, create: true);
    }

    /// check that we don't already ignore it.
    if (!read(pathToGitIgnore).toList().contains(fileToIgnore)) {
      pathToGitIgnore.append(fileToIgnore);

      add(pathToGitIgnore);
      commit('ignored $fileToIgnore');
    }
  }
}
