#! /usr/bin/env dcli

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

import 'git.dart';
import 'hooks.dart';
import 'version/version.dart';
import 'pubspec_helper.dart';

class Release {
  static final _self = Release._internal();
  Release._internal();

  factory Release() => _self;

  void pub_release(bool incVersion, {bool setVersion, String passedVersion}) {
    print('');

    /// If the user has set the version from the cli we assume they want to answer
    /// yes to all questions.
    var autoAnswer = setVersion;
    //print('Running pub_release version: $packageVersion');

    var pubspec = getPubSpec();
    var pubspecPath = findPubSpec();
    var projectRootPath = dirname(pubspecPath);
    var currentVersion = pubspec.version;

    check_hooks(projectRootPath);

    print(green('Found pubspec.yaml for ${orange(pubspec.name)}.'));
    print('');
    if (!autoAnswer && !confirm('Is this the correct package?')) exit(-1);

    print('');
    print(green('Current ${pubspec.name} version is $currentVersion'));

    var usingGit = Git().usingGit(projectRootPath);
    // we do a premptive git pull as we won't be able to do a push
    // at then end if we are behind head.
    Git().pull();

    Version newVersion;
    if (setVersion) {
      // we were passed the new version so just updated everything.
      newVersion = Version.parse(passedVersion);
      print(green('Setting version to $passedVersion'));

      updateVersion(newVersion, pubspec, pubspecPath);
    } else {
      // Ask the user for the new version
      if (incVersion) {
        newVersion = askForVersion(currentVersion);
        updateVersion(newVersion, pubspec, pubspecPath);
      }
    }

    run_pre_release_hook(projectRootPath, version: newVersion);

    // ensure that all code is correctly formatted.
    formatCode(projectRootPath);

    var progress = start('dartanalyzer .',
        workingDirectory: projectRootPath,
        nothrow: true,
        progress: Progress.print());
    if (progress.exitCode != 0) {
      printerr(red('dartanayzer failed. Please fix the errors and try again.'));
      exit(1);
    }

    if (usingGit) {
      if (Git().tagExists(newVersion.toString())) {
        print('');
        print(red('The tag $newVersion already exists.'));
        if (autoAnswer ||
            confirm('If you proceed the tag will be deleted and re-created. '
                'Proceed?')) {
          Git().deleteGitTag(newVersion);
        } else {
          exit(1);
        }
      }
    }

    print('generating release notes');
    generateReleaseNotes(projectRootPath, newVersion, currentVersion,
        autoAnswer: autoAnswer);

    if (usingGit) {
      print('Checking commit');
      Git().checkCommited(autoAnswer: autoAnswer);

      Git().pushRelease();

      print('add tag');
      Git().addGitTag(newVersion, autoAnswer: autoAnswer);
    }

    print('publish');
    publish(pubspecPath, autoAnswer: autoAnswer);

    run_post_release_hook(projectRootPath, version: newVersion);
  }

  void formatCode(String projectRootPath) {
    // ensure that all code is correctly formatted.
    print('Formatting code...');
    'dartfmt -w ${join(projectRootPath, 'bin')}'
            ' ${join(projectRootPath, 'lib')}'
            ' ${join(projectRootPath, 'test')}'
        .forEach(devNull, stderr: print);
  }

  void publish(String pubspecPath, {@required bool autoAnswer}) {
    var projectRoot = dirname(pubspecPath);

    var cmd = 'pub publish';
    if (autoAnswer) {
      cmd += ' --force';
    }
    cmd.start(workingDirectory: projectRoot, terminal: true, nothrow: true);
  }

  void generateReleaseNotes(
      String projectRootPath, Version newVersion, Version currentVersion,
      {@required bool autoAnswer}) {
    // see https://blogs.sap.com/2018/06/22/generating-release-notes-from-git-commit-messages-using-basic-shell-commands-gitgrep/
    // for better ideas.

    var changeLogPath = join(projectRootPath, 'CHANGELOG.md');

    if (!exists(changeLogPath)) {
      touch(changeLogPath, create: true);
    }
    var releaseNotes = join(projectRootPath, 'release.notes.tmp');
    releaseNotes.write('# ${newVersion.toString()}');

    var usingGit = Git().usingGit(projectRootPath);

    /// add commit messages to release notes.
    if (usingGit) {
      var lastTag = Git().getLatestTag();

      // just the messages from each commit
      var messages = Git().getCommitMessages(lastTag);

      for (var message in messages) {
        releaseNotes.append(message);
      }
      releaseNotes.append('');
    }

    // give the user a chance to clean up the change log.
    if (!autoAnswer && confirm('Would you like to edit the release notes')) {
      showEditor(releaseNotes);
    }

    // write the edited commit messages to the change log.
    var backup = '$changeLogPath.bak';

    /// move the change log out of the way.
    move(changeLogPath, backup);

    /// write release notes to the change log.
    read(releaseNotes).forEach((line) => changeLogPath.append(line));

    /// append the old notes to the change log.
    read(backup).forEach((line) => changeLogPath.append(line));
    delete(backup);
    delete(releaseNotes);
  }
}
