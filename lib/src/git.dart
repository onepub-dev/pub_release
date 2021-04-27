import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_semver/pub_semver.dart';

class Git {
  static final Git _self = Git._internal();
  bool? _usingGit;
  factory Git() {
    return _self;
  }

  Git._internal();

  bool? usingGit(String packageRoot) {
    if (_usingGit == null) {
      // search up the tree for the .git directory
      var current = packageRoot;
      var found = false;
      while (current != rootPath && found == false) {
        found = Directory(join(current, '.git')).existsSync();
        current = dirname(current);
      }
      _usingGit = found;
    }

    return _usingGit;
  }

  bool tagExists(String tagName) {
    assert(_usingGit == true);
    final tags = 'git tag --list'.toList();

    return tags.contains(tagName);
  }

  void push() {
    assert(_usingGit == true);
    print('Pushing release to git...');
    'git push'.run;
  }

  /// Check that all files are committed.
  void checkAllFilesCommited() {
    assert(_usingGit == true);

    if (isCommitRequired) {
      print('');
      print('You have uncommited files');
      print(red('You MUST commit them before continuing.'));

      exit(-1);
    }
  }

  void commit(String message) {
    'git add CHANGELOG.md'.run;
    'git add lib/src/version/version.g.dart'.run;
    'git add pubspec.yaml'.run;

    /// occasionally there will be nothing commit.
    /// this can occur after a failed release when
    /// we try re-run the release.
    if (isCommitRequired) {
      'git commit -m "$message"'.run;
    }
  }

  bool get isCommitRequired {
    return 'git status --porcelain'.toList().isNotEmpty;
  }

  /// Check that all files are committed.
  void checkCommit({required bool autoAnswer}) {
    assert(_usingGit == true);

    if (isCommitRequired) {
      print('');
      print('You have uncommited files');
      print(orange('You MUST commit them before continuing.'));

      if (autoAnswer || confirm('Do you want to list them')) {
        // we get the list again as the user is likely to have
        // committed files after seeing the question.
        final notCommited = 'git status --porcelain'.toList();
        print(notCommited.join('\n'));
      }
      if (!autoAnswer && !confirm('Do you want to continue with the release')) {
        exit(-1);
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
    'git tag -d $newVersion'.run;
    // 'git push origin :refs/tags/$newVersion'.run;
    'git push --follow-tags'.run;
  }

  void addGitTag(Version? version, {required bool autoAnswer}) {
    assert(_usingGit == true);
    final tagName = '$version';
    // Check if the tag already exists and offer to replace it if it does.
    if (tagExists(tagName)) {
      if (autoAnswer ||
          confirm(
              'The tag $tagName already exists. Do you want to replace it?')) {
        'git tag -d $tagName'.run;
        //     'git push origin :refs/tags/$tagName'.run;
        'git push --follow-tags'.run;
        print('');
      }
    }

    print('creating git tag');

    'git tag -a $tagName -m "released $tagName"'.run;
    print('pushing tag');
    'git push origin :refs/tags/$tagName'.run;
    'git push --follow-tags'.run;
  }

  void pull() {
    'git pull'.run;
  }
}
