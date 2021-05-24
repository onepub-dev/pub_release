import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_semver/pub_semver.dart';

class Git {
  Git(this.pathToPackageRoot);
  bool? _usingGit;
  String pathToPackageRoot;

  bool get usingGit {
    if (_usingGit == null) {
      // search up the tree for the .git directory
      var current = pathToPackageRoot;
      var found = false;
      while (current != rootPath && found == false) {
        found = Directory(join(current, '.git')).existsSync();
        current = dirname(current);
      }
      _usingGit = found;
    }

    return _usingGit ?? false;
  }

  bool tagExists(String tagName) {
    assert(_usingGit == true);
    final tags = 'git tag --list'.toList();

    return tags.contains(tagName);
  }

  void push() {
    assert(_usingGit == true);
    print('Pushing release to git...');
    'git push'.start(workingDirectory: pathToPackageRoot);
  }

  /// Check that all files are committed.
  void checkAllFilesCommited() {
    assert(_usingGit == true);

    if (isCommitRequired) {
      print('');
      print('You have uncommited files');
      print(red('You MUST commit them before continuing.'));

      exit(1);
    }
  }

  void commit(String message) {
    'git add CHANGELOG.md'.start(workingDirectory: pathToPackageRoot);
    'git add lib/src/version/version.g.dart'
        .start(workingDirectory: pathToPackageRoot);
    'git add pubspec.yaml'.start(workingDirectory: pathToPackageRoot);

    /// occasionally there will be nothing commit.
    /// this can occur after a failed release when
    /// we try re-run the release.
    if (isCommitRequired) {
      'git commit -m "$message"'.start(workingDirectory: pathToPackageRoot);
    }
  }

  bool get isCommitRequired {
    return 'git status --porcelain'
        .start(
            workingDirectory: pathToPackageRoot, progress: Progress.capture())
        .lines
        .isNotEmpty;
  }

  /// Check that all files are committed.
  void checkCommit({required bool autoAnswer}) {
    assert(_usingGit == true);

    if (isCommitRequired) {
      print('');
      print('You have uncommited file.');
      print(orange('You MUST commit them before continuing.'));

      if (autoAnswer || confirm('Do you want to list them')) {
        // we get the list again as the user is likely to have
        // committed files after seeing the question.
        final notCommited = 'git status --porcelain'.toList();
        print(notCommited.join('\n'));
      }
      if (!autoAnswer && !confirm('Do you want to continue with the release')) {
        exit(1);
      }
    }
  }

  String? getLatestTag() {
    assert(_usingGit == true);
    return 'git --no-pager tag --sort=-creatordate'.firstLine;
  }

  List<String?> getCommitMessages(String? fromTag) {
    assert(_usingGit == true);

    if (fromTag == null) {
      return 'git --no-pager log --pretty=format:"%s" HEAD'.toList();
    } else {
      return 'git --no-pager log --pretty=format:"%s" $fromTag..HEAD'.toList();
    }
  }

  void deleteGitTag(Version newVersion) {
    assert(_usingGit == true);
    'git tag -d $newVersion'.start(workingDirectory: pathToPackageRoot);
    'git push --follow-tags'.start(workingDirectory: pathToPackageRoot);
  }

  void addGitTag(Version? version, {required bool autoAnswer}) {
    assert(_usingGit == true);
    final tagName = '$version';
    // Check if the tag already exists and offer to replace it if it does.
    if (tagExists(tagName)) {
      if (autoAnswer ||
          confirm(
              'The tag $tagName already exists. Do you want to replace it?')) {
        'git tag -d $tagName'.start(workingDirectory: pathToPackageRoot);
        'git push --follow-tags'.start(workingDirectory: pathToPackageRoot);
        print('');
      }
    }

    print('creating git tag');

    'git tag -a $tagName -m "released $tagName"'
        .start(workingDirectory: pathToPackageRoot);
    print('pushing tag');
    'git push origin :refs/tags/$tagName'
        .start(workingDirectory: pathToPackageRoot);
    'git push --follow-tags'.start(workingDirectory: pathToPackageRoot);
  }

  void pull() {
    print('Running git pull.');
    'git pull'.start(workingDirectory: pathToPackageRoot);
  }

  bool get hasRemote {
    return 'git remote'
        .start(
            workingDirectory: pathToPackageRoot,
            progress: Progress.capture(captureStderr: false))
        .lines
        .isNotEmpty;
  }
}
