#! /usr/bin/env dcli

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_semver/pub_semver.dart';

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
  ReleaseRunner(this.pathToPackageRoot);

  String pathToPackageRoot;

  bool pubRelease({
    required PubSpecDetails pubSpecDetails,
    required VersionMethod versionMethod,
    required int lineLength,
    required bool dryrun,
    required bool runTests,
    required bool autoAnswer,
    required String? tags,
    required String? excludeTags,
    required bool useGit,
    Version? setVersion,
  }) {
    var success = false;
    doRun(
        dryrun: dryrun,
        runRelease: () {
          final projectRootPath = dirname(pubSpecDetails.path);

          runPubGet(projectRootPath);

          if (runTests) {
            if (!doRunTests(projectRootPath,
                tags: tags, excludeTags: excludeTags)) {
              throw UnitTestFailedException(
                  'Some unit tests failed. Release has been halted.');
            }
          }

          final usingGit = useGit && gitChecks(projectRootPath);

          final newVersion = determineAndUpdateVersion(
              versionMethod, setVersion, pubSpecDetails,
              dryrun: dryrun);

          runPreReleaseHooks(projectRootPath,
              version: newVersion, dryrun: dryrun);
          prepareReleaseNotes(
              projectRootPath, newVersion, pubSpecDetails.pubspec.version,
              usingGit: usingGit, autoAnswer: autoAnswer, dryrun: dryrun);
          prepareCode(projectRootPath, lineLength, usingGit: usingGit);

          commitRelease(newVersion, projectRootPath,
              usingGit: usingGit, autoAnswer: autoAnswer, dryrun: dryrun);

          // protect the pubspec.yaml as need to remove the
          // overrides
          withFileProtection([pubSpecDetails.path], () {
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
  /// It will almost certainly change as we are doing a multi-package
  /// release as the dependencies we are releasing will have their version
  /// no.s changed.
  void runPubGet(String projectRootPath) {
    // final lockPath = join(projectRootPath, 'pubspec.lock');
    // final original = calculateHash(lockPath);

    if (DartSdk().isPubGetRequired(projectRootPath)) {
      /// Make certain the project is in a state that we can run it.
      print(blue('Running pub get to ensure package is ready to test'));
      DartSdk().runPubGet(projectRootPath, progress: Progress.devNull());

      // if (original != calculateHash(lockPath)) {
      //   final git = Git(projectRootPath);
      //   git.add(lockPath);
      //   git.commit('pubspec.lock updated');
      // }
    }
  }

  bool gitChecks(String projectRootPath) {
    final git = Git(projectRootPath);
    final usingGit = git.usingGit;
    if (usingGit) {
      print('Found Git project.');
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
      String projectRootPath, Version newVersion, Version? currentVersion,
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
  bool doReleaseNotesExist(Version version) {
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
    var newVersion = pubspecDetails.pubspec.version!;

    if (versionMethod == VersionMethod.set) {
      // we were passed the new version so just updated everything.
      newVersion = passedVersion!;
      updateVersionFromDetails(newVersion, pubspecDetails);
    } else {
      // Ask the user for the new version
      newVersion = askForVersion(pubspecDetails.pubspec.version!);
      updateVersionFromDetails(newVersion, pubspecDetails);
    }
    return newVersion;
  }

  void formatCode(String projectRootPath,
      {required bool usingGit, required int lineLength}) {
    // ensure that all code is correctly formatted.
    print('Formatting code...');

    _formatCode(
        join(projectRootPath, 'bin'), usingGit, lineLength, projectRootPath);
    _formatCode(
        join(projectRootPath, 'lib'), usingGit, lineLength, projectRootPath);
    _formatCode(
        join(projectRootPath, 'test'), usingGit, lineLength, projectRootPath);
  }

  void _formatCode(
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

  /// git books writes out changelog.md as lower case. We also have the issue
  /// that on Windows file names are case insensitive.
  /// As such we look for both versions given the upper case version precedence.
  late final changeLogPathUpper = join(pathToPackageRoot, 'CHANGELOG.md');
  late final changeLogPathLower = join(pathToPackageRoot, 'changelog.md');

  String get changeLogPath {
    if (exists(changeLogPathUpper)) {
      return changeLogPathUpper;
    } else if (exists(changeLogPathLower)) {
      return changeLogPathLower;
    }
    return changeLogPathUpper;
  }

  void generateReleaseNotes(Version? newVersion, Version? currentVersion,
      {required bool autoAnswer, required bool dryrun}) {
    // see https://blogs.sap.com/2018/06/22/generating-release-notes-from-git-commit-messages-using-basic-shell-commands-gitgrep/
    // for better ideas.

    if (!exists(changeLogPath)) {
      touch(changeLogPath, create: true);
    }

    /// we use a .md as then user can preview the mark down.
    final tmpReleaseNotes = join(pathToPackageRoot, 'release.notes.tmp.md');
    // ignore: cascade_invocations
    tmpReleaseNotes.write('# ${newVersion.toString()}');
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
  /// Als prints the version of the package we found.
  ///
  /// If [autoAnswer] is false we don't ask the user to confirm the package.
  PubSpecDetails checkPackage({required bool autoAnswer}) {
    final pubspecPath = findPubSpec(startingDir: pathToPackageRoot);
    if (pubspecPath == null) {
      print('Unable to find pubspec.yaml, run ${DartScript.self.exeName} '
          'from the main '
          "package's root directory.");
      exit(1);
    }

    final pubspec = PubSpec.fromFile(pubspecPath);

    pubspec.version = pubspec.version ?? Version.parse('0.0.1');

    print('');
    print(green('Found ${pubspec.name} version ${pubspec.version}'));

    print('');
    if (!autoAnswer) {
      if (!confirm('Is this the correct package?')) {
        exit(1);
      }
      print('');
    }

    return PubSpecDetails(pubspec, pubspecPath);
  }

  void commitRelease(
    Version newVersion,
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
  void doRun({required bool dryrun, required void Function() runRelease}) {
    if (dryrun) {
      withFileProtection([
        join(pathToPackageRoot, 'pubspec.yaml'),
        changeLogPath,
        versionLibraryPath(pathToPackageRoot),
      ], () {
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
      PubCache().globalActivate('critical_test');
    }
    if (which('critical_test').notfound) {
      printerr(
          red('Please install the dart package critical_test and try again. '
              '"dart pub global activate critical_test"'));
      exit(1);
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
    (Platform.isWindows &&
        (which('$exeName.exe').found || which('$exeName.exe').found));

String exeName(String exeName) => which(exeName).path!;

class PubSpecDetails {
  PubSpecDetails(this.pubspec, this.path);
  PubSpec pubspec;
  String path;

  /// Removes all of the dependency_overrides for each of the packages
  /// listed in the pubrelease_multi.yaml file.
  void removeOverrides() {
    pubspec
      ..dependencyOverrides = <String, Dependency>{}
      ..saveToFile(path);

    /// pause for a moment incase an IDE is monitoring the pubspec.yaml
    /// changes. If we move too soon the .dart_tools directory may not exist.
    sleep(2);
  }
}

class UnitTestFailedException extends PubReleaseException {
  UnitTestFailedException(String message) : super(message);
}
