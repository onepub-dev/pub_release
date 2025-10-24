#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io' as io;

import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart' as sm;
import 'package:pubspec_manager/pubspec_manager.dart' hide Version;

import 'git.dart';
import 'multi_settings.dart';
import 'pubspec_helper.dart';
import 'run_hooks.dart';
import 'version/version.dart';

enum VersionMethod {
  ask,
  set,
}

class ReleaseRunner {
  String pathToPackageRoot;

  /// git books writes out changelog.md as lower case. We also have the issue
  /// that on Windows file names are case insensitive.
  /// As such we look for both versions given the upper case version precedence.
  late final changeLogPathUpper = join(pathToPackageRoot, 'CHANGELOG.md');

  late final changeLogPathLower = join(pathToPackageRoot, 'changelog.md');

  ReleaseRunner(this.pathToPackageRoot);

  Future<bool> pubRelease({
    required PubSpecDetails pubSpecDetails,
    required VersionMethod versionMethod,
    required int lineLength,
    required bool format,
    required bool dryrun,
    required bool runTests,
    required bool autoAnswer,
    required String? tags,
    required String? excludeTags,
    required bool useGit,
    sm.Version? setVersion,
  }) async {
    var success = false;
    await doRun(
        dryrun: dryrun,
        runRelease: () async {
          final projectRootPath = dirname(pubSpecDetails.path);

          final newVersion = determineAndUpdateVersion(
              versionMethod, setVersion, pubSpecDetails,
              dryrun: dryrun);

          runPubGet(projectRootPath);

          if (runTests) {
            if (!doRunTests(projectRootPath,
                tags: tags, excludeTags: excludeTags)) {
              throw UnitTestFailedException(
                  'Some unit tests failed. Release has been halted.');
            }
          }

          final usingGit = useGit && gitChecks(projectRootPath);

          runPreReleaseHooks(projectRootPath,
              version: newVersion, dryrun: dryrun);
          prepareReleaseNotes(projectRootPath, newVersion,
              pubSpecDetails.pubspec.version.semVersion,
              usingGit: usingGit, autoAnswer: autoAnswer, dryrun: dryrun);
          prepareCode(projectRootPath, lineLength,
              format: format, usingGit: usingGit);

          commitRelease(newVersion, projectRootPath,
              usingGit: usingGit, autoAnswer: autoAnswer, dryrun: dryrun);

          // protect the pubspec.yaml as need to remove the
          // overrides
          await withFileProtectionAsync([pubSpecDetails.path], () async {
            pubSpecDetails.removeOverrides();
            success = publish(pubSpecDetails.path,
                autoAnswer: autoAnswer, dryrun: dryrun);
          });

          runPostReleaseHooks(projectRootPath,
              version: newVersion, dryrun: dryrun);

          if (!success) {
            printerr(red('The publish attempt failed.'));
          }
        });

    return success;
  }

  /// Run pub get to ensure that the project is in a runnable state.
  /// This may result in pubspec.lock being updated and
  /// as we don't allow the project to have any uncommited files
  /// we need to commit it.
  /// It will almost certainly change if we are doing a multi-package
  /// release as the dependencies we are releasing will have their version
  /// no.s changed.
  void runPubGet(String projectRootPath) {
    if (DartSdk().isPubGetRequired(projectRootPath)) {
      /// Make certain the project is in a state that we can run it.
      print(blue("Running 'pub get' to ensure package is ready to publish"));
      DartSdk().runPubGet(projectRootPath, progress: Progress.devNull());
    }
  }

  bool gitChecks(String projectRootPath) {
    final git = Git(projectRootPath);
    final usingGit = git.usingGit;
    if (usingGit) {
      print('Found git project.');
      // we do a premptive git pull as we won't be able to do a push
      // at the end if we are behind head.
      if (git.hasRemote) {
        git.pull();
      } else {
        print(orange('Skipping git pull as no remote has been defined.'));
      }

      // print('Checking files are committed.');
      // git.checkAllFilesCommited();
    }

    return usingGit;
  }

  void prepareReleaseNotes(
      String projectRootPath, sm.Version newVersion, sm.Version? currentVersion,
      {required bool usingGit,
      required bool autoAnswer,
      required bool dryrun}) {
    /// the change log is backed up as part of the dry run
    /// and restored afterwoods.
    if (!doReleaseNotesExist(newVersion)) {
      print('Generating release notes.');
      generateReleaseNotes(newVersion, currentVersion,
          autoAnswer: autoAnswer, dryrun: dryrun);
      if (!dryrun && usingGit) {
        // final git = Git(projectRootPath);
        // print('Committing release notes and versioned files');
        // git.commitVersion("Released $newVersion");

        // if (git.hasRemote) {
        //   git.push();
        // }
      }
    }
    //}
  }

  /// checks the change log to see if the release notes for [version]
  /// have already been generated.
  bool doReleaseNotesExist(sm.Version version) {
    if (!exists(changeLogPath)) {
      touch(changeLogPath, create: true);
    }
    final note = '# $version';

    return read(changeLogPath).toList().join('\n').contains(note);
  }

  /// Ensure that all code is correctly formatted.
  /// and that it passes all tests.
  void prepareCode(String projectRootPath, int lineLength,
      {required bool format, required bool usingGit}) {
    // ensure that all code is correctly formatted.
    if (format) {
      _formatCode(projectRootPath, usingGit: usingGit, lineLength: lineLength);
    }

    final progress = start('dart analyze',
        workingDirectory: projectRootPath,
        nothrow: true,
        progress: Progress.print());
    if (progress.exitCode != 0) {
      printerr(
          red('dart analyze failed. Please fix the errors and try again.'));
      io.exit(1);
    }
  }

  sm.Version determineAndUpdateVersion(
    VersionMethod versionMethod,
    sm.Version? passedVersion,
    PubSpecDetails pubspecDetails, {
    required bool dryrun,
  }) {
    var newVersion = passedVersion ?? pubspecDetails.pubspec.version.semVersion;

    if (versionMethod == VersionMethod.set) {
      // we were passed the new version so just updated everything.
      updateVersionFromDetails(newVersion, pubspecDetails);
    } else {
      // Ask the user for the new version
      newVersion = askForVersion(pubspecDetails.pubspec.version.semVersion);
      updateVersionFromDetails(newVersion, pubspecDetails);
    }
    return newVersion;
  }

  void _formatCode(String projectRootPath,
      {required bool usingGit, required int lineLength}) {
    // ensure that all code is correctly formatted.
    print('Formatting code...');

    _formatCodeInDirectory(
        join(projectRootPath, 'bin'), usingGit, lineLength, projectRootPath);
    _formatCodeInDirectory(
        join(projectRootPath, 'lib'), usingGit, lineLength, projectRootPath);
    _formatCodeInDirectory(
        join(projectRootPath, 'test'), usingGit, lineLength, projectRootPath);
  }

  void _formatCodeInDirectory(
      String srcPath, bool usingGit, int lineLength, String workingDirectory) {
    final output = <String>[];

    if (exists(srcPath) && !isEmpty(srcPath)) {
      'dart format --summary none --line-length=$lineLength $srcPath'
          .forEach(output.add, stderr: print);

      if (usingGit) {
        for (final line in output) {
          if (line.startsWith('Formatted')) {
            final filePath = line.substring('Formatted '.length);
            'git add ${join(srcPath, filePath)}'
                .start(workingDirectory: workingDirectory);
          }
        }
      }
    }
  }

  bool publish(String pubspecPath,
      {required bool autoAnswer, required bool dryrun}) {
    final projectRoot = dirname(pubspecPath);

    final version = sm.Version.parse(io.Platform.version.split(' ')[0]);
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

  String get changeLogPath {
    if (exists(changeLogPathUpper)) {
      return changeLogPathUpper;
    } else if (exists(changeLogPathLower)) {
      return changeLogPathLower;
    }
    return changeLogPathUpper;
  }

  void generateReleaseNotes(sm.Version? newVersion, sm.Version? currentVersion,
      {required bool autoAnswer, required bool dryrun}) {
    // see https://blogs.sap.com/2018/06/22/generating-release-notes-from-git-commit-messages-using-basic-shell-commands-gitgrep/
    // for better ideas.

    if (!exists(changeLogPath)) {
      touch(changeLogPath, create: true);
    }

    /// we use a .md as then user can preview the mark down.
    final tmpReleaseNotes = join(pathToPackageRoot, 'release.notes.tmp.md')
      ..write('# $newVersion');
    final git = Git(pathToPackageRoot);
    final usingGit = git.usingGit;

    /// add commit messages to release notes.
    if (usingGit) {
      final lastTag = git.getLatestTag();

      // just the messages from each commit
      final messages = git.getCommitMessages(lastTag);

      for (final message in messages) {
        tmpReleaseNotes.append('- $message');
      }
      tmpReleaseNotes.append('');
    }

    /// append the changelog to the new release notes
    read(changeLogPath).toList().forEach(tmpReleaseNotes.append);

    // give the user a chance to clean up the change log.
    if (!autoAnswer &&
        !dryrun &&
        confirm('Would you like to edit the $changeLogPath notes')) {
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
  /// Also prints the version of the package we found.
  ///
  /// If [autoAnswer] is false we don't ask the user to confirm the package.
  PubSpecDetails checkPackage({required bool autoAnswer}) {
    final pubspecPath = findPubSpec(startingDir: pathToPackageRoot);
    if (pubspecPath == null) {
      print('Unable to find pubspec.yaml, run ${DartScript.self.exeName} '
          'from the main '
          "package's root directory.");
      io.exit(1);
    }

    final pubspec = PubSpec.loadFromPath(pubspecPath);

    pubspec.version.setSemVersion(pubspec.version.semVersion == sm.Version.none
        ? sm.Version.parse('0.0.1')
        : pubspec.version.semVersion);

    print('');
    print(green('Found ${pubspec.name.value} version ${pubspec.version}'));

    print('');

    return PubSpecDetails(pubspec, pubspecPath);
  }

  void commitRelease(
    sm.Version newVersion,
    String workingDirectory, {
    required bool usingGit,
    required bool autoAnswer,
    required bool dryrun,
  }) {
    if (usingGit && !dryrun) {
      final git = Git(workingDirectory);
      print('Commiting all modified files.');
      git
        ..commitAll('Released $newVersion.')
        ..pushReleaseTag(newVersion, autoAnswer: autoAnswer);
    }
  }

  /// Runs the release process.
  /// If we are running a dry run we back up key files that we have
  /// to change for the pub.dev publish dry run to work but
  /// which we don't actually want to changes as we are doing a dry run.
  /// At the end of the dry run we restore these key files.
  Future<void> doRun(
      {required bool dryrun, required void Function() runRelease}) async {
    if (dryrun) {
      await withFileProtectionAsync([
        join(pathToPackageRoot, 'pubspec.yaml'),
        changeLogPath,
        versionLibraryPath(pathToPackageRoot),
      ], () async {
        runRelease();
      });
    } else {
      runRelease();
    }
  }

  bool doRunTests(String projectRootPath,
      {required String? tags, required String? excludeTags}) {
    if (which('critical_test').notfound) {
      print(blue('Installing dart package critical_test'));
      'dart pub global activate critical_test'
          .start(progress: Progress.printStdErr());
    }
    if (which('critical_test').notfound) {
      printerr(
          red('Please install the dart package critical_test and try again. '
              '"dart pub global activate critical_test"'));
      io.exit(1);
    }
    // critical_test generates a file to track failed tests
    // add it to .gitignore so it doesn't look like an uncommitted
    // file.
    Git(projectRootPath).addGitIgnore('.failed_tracker');

    var success = true;

    if (!exists(join(projectRootPath, 'test'))) {
      print(orange('No tests found in ${relative(projectRootPath)} skipping'));
    } else {
      final progress = startFromArgs(
          exeName('critical_test'),
          [
            if (Settings().isVerbose) '-v',
            if (tags != null) '--tags=$tags',
            if (excludeTags != null) '--exclude-tags=$excludeTags',
          ],
          terminal: true,
          workingDirectory: projectRootPath,
          nothrow: true);

      /// exitCode 5 means no test ran.
      success = progress.exitCode == 0 || progress.exitCode == 5;
      if (success) {
        print(green('All unit tests passed.'));
      }
    }
    return success;
  }
}

bool whichEx(String exeName) =>
    which(exeName).found ||
    (io.Platform.isWindows &&
        (which('$exeName.exe').found || which('$exeName.exe').found));

String exeName(String exeName) => which(exeName).path!;

class PubSpecDetails {
  PubSpec pubspec;

  String path;

  PubSpecDetails(this.pubspec, this.path);

  /// Removes all of the dependency_overrides for each of the packages
  /// listed in the pubrelease_multi.yaml file.
  void removeOverrides() {
    pubspec
      ..dependencyOverrides.removeAll()
      ..saveTo(path);

    /// pause for a moment incase an IDE is monitoring the pubspec.yaml
    /// changes. If we move too soon the .dart_tools directory may not exist.
    sleep(2);
  }
}

class UnitTestFailedException extends PubReleaseException {
  UnitTestFailedException(super.message);
}
