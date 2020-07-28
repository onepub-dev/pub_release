import 'dart:io';

import 'package:dshell/dshell.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

class Git {
  static final Git _self = Git._internal();
  bool _usingGit;
  factory Git() {
    return _self;
  }

  Git._internal();

  bool usingGit(String packageRoot) {
    _usingGit ??= (Directory(join(packageRoot, '.git')).existsSync());

    return _usingGit;
  }

  bool tagExists(String tagName) {
    assert(_usingGit == true);
    var tags = 'git tag --list'.toList();

    return (tags.contains(tagName));
  }

  void pushRelease() {
    assert(_usingGit == true);
    print('Pushing release to git...');
    'git push'.run;
  }

  /// Check that all files are committed.
  void checkCommited({@required bool autoAnswer}) {
    assert(_usingGit == true);
    var notCommited = 'git status --porcelain'.toList();

    if (notCommited.isNotEmpty) {
      print('');
      print('You have uncommited files');
      print(orange('You should commit them before continuing.'));
      if (autoAnswer || confirm(prompt: 'Do you want to list them')) {
        // we get the list again as the user is likely to have
        // committed files after seeing the question.
        notCommited = 'git status --porcelain'.toList();
        print(notCommited.join('\n'));
      }
      if (!autoAnswer &&
          !confirm(prompt: 'Do you want to continue with the release')) {
        exit(-1);
      }
    }
  }

  String getLatestTag() {
    assert(_usingGit == true);
    return 'git --no-pager tag --sort=-creatordate'.firstLine;
  }

  List<String> getCommitMessages(String fromTag) {
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
    'git push origin :refs/tags/$newVersion'.run;
  }

  void addGitTag(Version version, {@required bool autoAnswer}) {
    assert(_usingGit == true);
    var tagName = '$version';
    if (autoAnswer || confirm(prompt: 'Create a git release tag [$tagName]')) {
      // Check if the tag already exists and offer to replace it if it does.
      if (tagExists(tagName)) {
        if (autoAnswer ||
            confirm(
                prompt:
                    'The tag $tagName already exists. Do you want to replace it?')) {
          'git tag -d $tagName'.run;
          'git push origin :refs/tags/$tagName'.run;
          print('');
        }
      }

      print('creating git tag');
      // 'git tag -a $tagName'.run;

      'git tag -a $tagName -m "released $tagName"'.run;
    }
  }

  void pull() {
    'git pull'.run;
  }
}
