#! /usr/bin/env dcli

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_release/src/multi_settings.dart';
import 'package:pub_semver/pub_semver.dart';

import 'git.dart';
import 'hooks.dart';
import 'pubspec_helper.dart';
import 'version/version.dart';

enum VersionMethod {
  ask,
  set,
}

class ReleaseRunner {
  ReleaseRunner(this.pathToPackageRoot);

  String pathToPackageRoot;

  void pubRelease(
      {required PubSpecDetails pubSpecDetails,
      required VersionMethod versionMethod,
      Version? setVersion,
      required int lineLength,
      required bool dryrun,
      required bool runTests,
      required bool autoAnswer,
      required String? tags,
      required String? excludeTags}) {
    doRun(
        dryrun: dryrun,
        runRelease: () {
          final projectRootPath = dirname(pubSpecDetails.path);

          if (runTests) {
            if (!doRunTests(projectRootPath,
                tags: tags, excludeTags: excludeTags)) {
              throw UnitTestFailedException(
                  'Some unit tests failed. Release has been halted.');
            }
          }

          final usingGit = gitChecks(projectRootPath);

          final newVersion = determineAndUpdateVersion(
              versionMethod, setVersion, pubSpecDetails,
              dryrun: dryrun);

          runPreReleaseHooks(projectRootPath,
              version: newVersion, dryrun: dryrun);
          prepareReleaseNotes(
              projectRootPath, newVersion, pubSpecDetails.pubspec.version,
              usingGit: usingGit, autoAnswer: autoAnswer, dryrun: dryrun);
          prepareCode(projectRootPath, lineLength, usingGit: usingGit);
          addGitTag(newVersion,
              usingGit: usingGit, autoAnswer: autoAnswer, dryrun: dryrun);

          pubSpecDetails.removeOverrides();

          if (!publish(pubSpecDetails.path,
              autoAnswer: autoAnswer, dryrun: dryrun)) {
            printerr(red('The publish attempt failed.'));
          }
          pubSpecDetails.restoreOverrides();

          runPostReleaseHooks(projectRootPath,
              version: newVersion, dryrun: dryrun);
        });
  }

  bool gitChecks(String projectRootPath) {
    final usingGit = Git().usingGit(projectRootPath)!;
    if (usingGit) {
      print('Found Git project.');
      // we do a premptive git pull as we won't be able to do a push
      // at the end if we are behind head.
      Git().pull();

      print('Checking files are committed.');
      Git().checkAllFilesCommited();
    }

    return usingGit;
  }

  void prepareReleaseNotes(
      String projectRootPath, Version newVersion, Version? currentVersion,
      {required bool usingGit,
      required bool autoAnswer,
      required bool dryrun}) {
    /// the change log is backed up as part of the dry run and restored afterwoods.
    if (!doReleaseNoteExist(newVersion)) {
      print('Generating release notes.');
      generateReleaseNotes(newVersion, currentVersion,
          autoAnswer: autoAnswer, dryrun: dryrun);
      if (!dryrun && usingGit) {
        print('Committing release notes and versioned files');
        Git().commit("Released $newVersion");

        Git().push();
      }
    }
    //}
  }

  /// checks the change log to see if the release notes for [version]
  /// have already been generated.
  bool doReleaseNoteExist(Version version) {
    final note = '# ${version.toString()}';

    return read(changeLogPath).toList().join('\n').contains(note);
  }

  /// Ensure that all code is correctly formatted.
  /// and that it passes all tests.
  void prepareCode(String projectRootPath, int lineLength,
      {required bool usingGit}) {
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
  }

  Version determineAndUpdateVersion(
    VersionMethod versionMethod,
    Version? passedVersion,
    PubSpecDetails pubspecDetails, {
    required bool dryrun,
  }) {
    Version newVersion = pubspecDetails.pubspec.version!;

    if (versionMethod == VersionMethod.set) {
      // we were passed the new version so just updated everything.
      newVersion = passedVersion!;
      updateVersion(newVersion, pubspecDetails);
    } else {
      // Ask the user for the new version
      newVersion = askForVersion(pubspecDetails.pubspec.version!);
      updateVersion(newVersion, pubspecDetails);
    }
    return newVersion;
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

  bool publish(String pubspecPath,
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
    if (autoAnswer && !dryrun) {
      cmd += ' --force';
    }

    // if (!waitForEx(cli.check(cmd, workingDirectory: projectRoot))) {
    //   throw PubReleaseException('The publish attempt failed.');
    // }

    final progress = cmd.start(
        terminal: true,
        workingDirectory: projectRoot,
        progress: Progress.print(),
        nothrow: true);

    return progress.exitCode == 0;
  }

  late final changeLogPath = join(pathToPackageRoot, 'CHANGELOG.md');

  void generateReleaseNotes(Version? newVersion, Version? currentVersion,
      {required bool autoAnswer, required bool dryrun}) {
    // see https://blogs.sap.com/2018/06/22/generating-release-notes-from-git-commit-messages-using-basic-shell-commands-gitgrep/
    // for better ideas.

    if (!exists(changeLogPath)) {
      touch(changeLogPath, create: true);
    }
    final tmpReleaseNotes = join(pathToPackageRoot, 'release.notes.tmp');
    tmpReleaseNotes.write('# ${newVersion.toString()}');

    final usingGit = Git().usingGit(pathToPackageRoot)!;

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
    if (!autoAnswer &&
        !dryrun &&
        confirm('Would you like to edit the CHANGELOG.md notes')) {
      showEditor(tmpReleaseNotes);
    }

    // write the edited commit messages to the change log.
    final backup = '$changeLogPath.bak';

    /// move the change log out of the way.
    move(changeLogPath, backup);

    /// replace the newly updated change log over the old one.
    move(tmpReleaseNotes, changeLogPath);

    delete(backup);
  }

  /// checks with the user that we are operating on the correct package
  /// and returns details of the packages pubspec.yaml.
  ///
  /// Als prints the version of the package we found.
  ///
  /// If [autoAnswer] is false we don't ask the user to confirm the package.
  PubSpecDetails checkPackage({required bool autoAnswer}) {
    final pubspecPath = findPubSpec(startingDir: pathToPackageRoot);
    if (pubspecPath == null) {
      print(
          'Unable to find pubspec.yaml, run ${DartScript.current.exeName} from the '
          "package's root directory.");
      exit(-1);
    }

    final pubspec = PubSpec.fromFile(pubspecPath);

    pubspec.version = pubspec.version ?? Version.parse('0.0.1');

    print(green('Found pubspec.yaml for ${orange(pubspec.name!)}.'));
    print('');
    if (!autoAnswer) {
      if (!confirm('Is this the correct package?')) exit(-1);
      print('');
    }

    print(green('Current ${pubspec.name} version is ${pubspec.version}'));

    return PubSpecDetails(pubspec, pubspecPath);
  }

  void addGitTag(
    Version newVersion, {
    required bool usingGit,
    required bool autoAnswer,
    required bool dryrun,
  }) {
    if (usingGit && !dryrun) {
      print('add tag');
      Git().addGitTag(newVersion, autoAnswer: autoAnswer);
    }
  }

  /// Runs the release process.
  /// If we are running a dry run we back up key files that we have
  /// to change for the pub.dev publish dry run to work but
  /// which we don't actually want to changes as we are doing a dry run.
  /// At the end of the dry run we restore these key files.
  void doRun({required bool dryrun, required void Function() runRelease}) {
    if (dryrun) {
      backupFile(join(pathToPackageRoot, 'pubspec.yaml'));
      backupFile(join(pathToPackageRoot, 'CHANGELOG.md'));

      backupVersionLibrary(pathToPackageRoot);
    }
    try {
      runRelease();
    } finally {
      if (dryrun) {
        restoreFile(join(pathToPackageRoot, 'pubspec.yaml'));
        restoreFile(join(pathToPackageRoot, 'CHANGELOG.md'));

        restoreVersionLibrary(pathToPackageRoot);
      }
    }
  }

  bool doRunTests(String projectRootPath,
      {required String? tags, required String? excludeTags}) {
    if (which('critical_test').notfound) {
      DartSdk().globalActivate('critical_test');
    }
    final progress = startFromArgs(
        'critical_test',
        [
          if (tags != null) '--tags="$tags"',
          if (excludeTags != null) '--exclude-tags="$excludeTags"',
        ],
        terminal: true,
        workingDirectory: projectRootPath,
        nothrow: true);
    final success = progress.exitCode == 0;
    if (success) {
      print(green('All unit tests passed.'));
    }
    return success;
  }
}

class PubSpecDetails {
  PubSpec pubspec;
  String path;

  PubSpecDetails(this.pubspec, this.path);

  /// Removes all of the dependency_overrides for each of the packages
  /// listed in the pubsem.yaml file.
  void removeOverrides() {
    backupFile(path);
    pubspec.dependencyOverrides = <String, Dependency>{};
    pubspec.saveToFile(path);
  }

  void restoreOverrides() {
    restoreFile(path);
  }
}

class UnitTestFailedException extends PubReleaseException {
  UnitTestFailedException(String message) : super(message);
}
