#! /usr/bin/env dcli

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_semver/pub_semver.dart';

import 'git.dart';
import 'hooks.dart';
import 'pubspec_helper.dart';
import 'version/version.dart';

class Release {
  static final _self = Release._internal();

  factory Release() => _self;

  Release._internal();

  void pubRelease(
      {bool? incVersion,
      required bool setVersion,
      String? passedVersion,
      required int lineLength,
      required bool dryrun}) {
    print('');

    /// If the user has set the version from the cli we assume they want to answer
    /// yes to all questions.
    final autoAnswer = setVersion;
    //print('Running pub_release version: $packageVersion');

    final pubspecPath = findPubSpec();
    if (pubspecPath == null) {
      print('Unable to find pubspec.yaml, run release from the '
          "package's root directory.");
      exit(-1);
    }

    final pubspec = PubSpec.fromFile(pubspecPath);

    final projectRootPath = dirname(pubspecPath);
    final currentVersion = pubspec.version;

    checkHooksAreReadyToRun(projectRootPath);

    print(green('Found pubspec.yaml for ${orange(pubspec.name!)}.'));
    print('');
    if (!autoAnswer && !confirm('Is this the correct package?')) exit(-1);

    print('');
    print(green('Current ${pubspec.name} version is $currentVersion'));

    final usingGit = Git().usingGit(projectRootPath)!;

    if (usingGit) {
      print('Found Git project.');

      // we do a premptive git pull as we won't be able to do a push
      // at the end if we are behind head.
      Git().pull();

      print('Checking files are committed.');
      Git().checkAllFilesCommited();
    }

    Version? newVersion;
    if (setVersion) {
      // we were passed the new version so just updated everything.
      newVersion = Version.parse(passedVersion!);
      print(green('Setting version to $passedVersion'));

      if (!dryrun) {
        updateVersion(newVersion, pubspec, pubspecPath);
      }
    } else {
      // Ask the user for the new version
      if (incVersion!) {
        newVersion = askForVersion(currentVersion!);
        if (!dryrun) {
          updateVersion(newVersion, pubspec, pubspecPath);
        }
      }
    }

    runPreReleaseHooks(projectRootPath, version: newVersion, dryrun: dryrun);

    // ensure that all code is correctly formatted.
    formatCode(projectRootPath, usingGit: usingGit, lineLength: lineLength);

    final progress = start('dart analyze',
        workingDirectory: projectRootPath,
        nothrow: true,
        progress: Progress.print());
    if (progress.exitCode != 0) {
      printerr(
          red('dart analyze failed. Please fix the errors and try again.'));
      exit(1);
    }
    print('Generating release notes.');
    if (!dryrun) {
      generateReleaseNotes(projectRootPath, newVersion, currentVersion,
          autoAnswer: autoAnswer, dryrun: dryrun);
    }

    if (usingGit && !dryrun) {
      print('Committing release notes and versioned files');
      Git().commit("Released $newVersion");

      Git().push();

      print('add tag');
      Git().addGitTag(newVersion, autoAnswer: autoAnswer);
    }

    print('publish');
    publish(pubspecPath, autoAnswer: autoAnswer, dryrun: dryrun);

    runPostReleaseHooks(projectRootPath, version: newVersion, dryrun: dryrun);
  }

  void formatCode(String projectRootPath,
      {required bool usingGit, required int lineLength}) {
    // ensure that all code is correctly formatted.
    print('Formatting code...');

    _formatCode(join(projectRootPath, 'bin'), usingGit, lineLength);
    _formatCode(join(projectRootPath, 'lib'), usingGit, lineLength);
    _formatCode(join(projectRootPath, 'test'), usingGit, lineLength);
  }

  void _formatCode(String srcPath, bool usingGit, int lineLength) {
    final output = <String>[];

    'dart format --summary none --line-length=$lineLength $srcPath'
        .forEach((line) => output.add(line), stderr: print);

    if (usingGit) {
      for (final line in output) {
        if (line.startsWith('Formatted')) {
          final filePath = line.substring('Formatted '.length);
          'git add ${join(srcPath, filePath)}'.run;
        }
      }
    }
  }

  void publish(String pubspecPath,
      {required bool autoAnswer, required bool dryrun}) {
    final projectRoot = dirname(pubspecPath);

    final version = Version.parse(Platform.version.split(' ')[0]);
    var cmd = 'dart pub publish';
    if (version.major == 2 && version.minor < 9) {
      cmd = 'pub publish';
    }

    if (dryrun) {
      cmd += ' --dry-run';
    }
    if (autoAnswer) {
      cmd += ' --force';
    }
    cmd.start(workingDirectory: projectRoot, terminal: true, nothrow: true);
  }

  void generateReleaseNotes(
      String projectRootPath, Version? newVersion, Version? currentVersion,
      {required bool autoAnswer, required bool dryrun}) {
    // see https://blogs.sap.com/2018/06/22/generating-release-notes-from-git-commit-messages-using-basic-shell-commands-gitgrep/
    // for better ideas.

    final changeLogPath = join(projectRootPath, 'CHANGELOG.md');

    if (!exists(changeLogPath)) {
      touch(changeLogPath, create: true);
    }
    final tmpReleaseNotes = join(projectRootPath, 'release.notes.tmp');
    tmpReleaseNotes.write('# ${newVersion.toString()}');

    final usingGit = Git().usingGit(projectRootPath)!;

    /// add commit messages to release notes.
    if (usingGit) {
      final lastTag = Git().getLatestTag();

      // just the messages from each commit
      final messages = Git().getCommitMessages(lastTag);

      for (final message in messages) {
        tmpReleaseNotes.append(message!);
      }
      tmpReleaseNotes.append('');
    }

    /// append the changelog to the new release notes
    read(changeLogPath).toList().forEach((line) {
      tmpReleaseNotes.append(line);
    });

    // give the user a chance to clean up the change log.
    if (!autoAnswer && confirm('Would you like to edit the release notes')) {
      showEditor(tmpReleaseNotes);
    }

    if (!dryrun) {
      // write the edited commit messages to the change log.
      final backup = '$changeLogPath.bak';

      /// move the change log out of the way.
      move(changeLogPath, backup);

      /// replace the newly updated change log over the old one.
      move(tmpReleaseNotes, changeLogPath);

      delete(backup);
    } else {
      delete(tmpReleaseNotes);
    }
  }
}
