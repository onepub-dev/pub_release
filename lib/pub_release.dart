#! /usr/bin/env dshell

import 'dart:io';

import 'package:dshell/dshell.dart';
import 'package:dshell/src/pubspec/pubspec_file.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

import 'git.dart';
import 'version.dart';

void pub_release(bool incVersion, {bool setVersion, String passedVersion}) {
  print('');

  /// If the user has set the version from the cli we assume they want to answer
  /// yes to all questions.
  var autoAnswer = setVersion;
  //print('Running pub_release version: $packageVersion');

  // climb the path searching for the pubspec
  var pubspecPath = findPubSpec();
  var projectRootPath = dirname(pubspecPath);
  var pubspec = getPubSpec(pubspecPath);
  var currentVersion = pubspec.version;

  print(green('Found pubspec.yaml for ${orange(pubspec.name)}.'));
  print('');
  if (!autoAnswer && !confirm(prompt: 'Is this the correct package?')) exit(-1);

  print('');
  print(green('Current ${pubspec.name} version is $currentVersion'));

  var usingGit = Git().usingGit(projectRootPath);
  // we do a premptive git pull as we won't be able to do a push
  // at then end if we are behind head.
  Git().pull();

  var newVersion = currentVersion;
  if (setVersion) {
    newVersion = Version.parse(passedVersion);
    print(green('Setting version to $passedVersion'));
    newVersion = incrementVersion(currentVersion, pubspec, pubspecPath,
        NewVersion('Not Used', newVersion));
  } else {
    if (incVersion) {
      var selected = askForVersion(newVersion);
      newVersion =
          incrementVersion(currentVersion, pubspec, pubspecPath, selected);
    }
  }

  // ensure that all code is correctly formatted.
  formatCode(projectRootPath);

  if (usingGit) {
    if (Git().tagExists(newVersion.toString())) {
      print('');
      print(red('The tag $newVersion already exists.'));
      if (autoAnswer ||
          confirm(
              prompt: 'If you proceed the tag will be deleted and re-created. '
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
    print('check commit');
    Git().checkCommited(autoAnswer: autoAnswer);

    Git().pushRelease();

    print('add tag');
    Git().addGitTag(newVersion, autoAnswer: autoAnswer);
  }

  print('publish');
  publish(pubspecPath, autoAnswer: autoAnswer);
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
  if (!autoAnswer &&
      confirm(prompt: 'Would you like to edit the release notes')) {
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

/// Returns the path to the pubspec.yaml.
String findPubSpec() {
  var pubspecName = 'pubspec.yaml';
  var cwd = pwd;
  var found = true;

  var pubspecPath = join(cwd, pubspecName);
  // climb the path searching for the pubspec
  while (!exists(pubspecPath)) {
    cwd = dirname(cwd);
    // Have we found the root?
    if (cwd == rootPath) {
      found = false;
      break;
    }
    pubspecPath = join(cwd, pubspecName);
  }

  if (!found) {
    print('Unable to find pubspec.yaml, run release from the'
        "package's root directory.");
    exit(-1);
  }
  return truepath(pubspecPath);
}

/// Read the pubspec.yaml file.
PubSpecFile getPubSpec(String pubspecPath) {
  var pubspec = PubSpecFile.fromFile(pubspecPath);
  return pubspec;
}
