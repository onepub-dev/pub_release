#! /usr/bin/env dcli

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_release/pub_release.dart';
import 'package:pub_release/src/multi_release.dart';

void main(List<String> args) {
  final parser = ArgParser();
  parser.addFlag('askVersion',
      abbr: 'k',
      defaultsTo: true,
      negatable: false,
      help: 'Prompts the user for the new version no.');

  parser.addOption('setVersion',
      abbr: 's',
      help:
          'Allows you to set the version no. from the cli. --setVersion=1.0.0');

  parser.addFlag('autoAnswer',
      abbr: 'a', help: 'Supresses any questions from being asked.');

  parser.addFlag('dry-run',
      abbr: 'd',
      negatable: false,
      help: 'Validate but do not publish the package.');

  parser.addFlag('test',
      abbr: 't', defaultsTo: true, help: 'Runs the package(s) unit tests.');

  // parser.addFlag('runfailed',
  //     abbr: 'f', help: 'Reruns unit tests that failed on a prior run.');

  parser.addOption('line',
      abbr: 'l',
      defaultsTo: "80",
      help: 'Specifies the line length to use when formatting.');

  parser.addFlag(
    'verbose',
    abbr: 'v',
    negatable: false,
    help: 'Outputs detailed logging.',
  );

  parser.addOption('tags',
      abbr: 'g',
      help:
          'Select unit tests to run via their tags. The syntax must confirm to the --tags option in the test package.');

  parser.addFlag('git',
      abbr: 'i',
      defaultsTo: true,
      help:
          'Controls whether git operations are performed as part of the release.');

  parser.addOption('exclude-tags',
      abbr: 'x',
      help:
          'Select unit tests to exclude via their tags. The syntax must confirm to the --exclude-tags option in the test package.');

  parser.addCommand('help');
  parser.addCommand('multi');

  late final ArgResults results;
  try {
    results = parser.parse(args);
  } catch (e) {
    print(red('$e'));
    results = parser.parse(['help']);
  }

  final dryrun = results['dry-run'] as bool;
  final useGit = results['git'] as bool;
  final runTests = results['test'] as bool;
  final autoAnswer = results['autoAnswer'] as bool;
  final verbose = results['verbose'] as bool;

  Settings().setVerbose(enabled: verbose);

  var multi = false;
  // was a command passed
  if (results.command != null) {
    switch (results.command!.name) {
      case 'help':
        showUsage(parser);
        exit(1);
      case 'multi':
        multi = true;
        break;
    }
  }

  print('${DartScript.self.exeName} $packageVersion');

  final lineLength = getLineLength(results, parser);

  if (results.wasParsed('askVersion') && results.wasParsed('setVersion')) {
    printerr(red('You may only pass one of "setVersion" or "askVersion"'));
    showUsage(parser);
    exit(1);
  }

  /// determine how the version will be set.
  VersionMethod versionMethod = VersionMethod.ask;
  Version? parsedVersion;
  if (results.wasParsed('setVersion')) {
    versionMethod = VersionMethod.set;
    final version = results['setVersion'] as String;
    try {
      parsedVersion = Version.parse(version);
    } on FormatException catch (_) {
      printerr(red(
          'The version no. "$version" passed to setVersion is not a valid version.'));
      exit(1);
    }
  }

  if (autoAnswer && versionMethod != VersionMethod.set) {
    printerr(red(
        'When using --autoAnswer you must also pass --setVersion=<version>'));
    exit(1);
  }

  String? tags;
  if (results.wasParsed('tags')) {
    tags = results['tags'] as String;
  }

  String? excludeTags;
  if (results.wasParsed('exclude-tags')) {
    excludeTags = results['exclude-tags'] as String;
  }

  // if (runTests && !autoAnswer) {
  //   checkForVsCode();
  // }

  try {
    if (multi) {
      multiRelease(DartProject.fromPath(pwd).pathToProjectRoot, versionMethod,
          parsedVersion,
          lineLength: lineLength,
          dryrun: dryrun,
          runTests: runTests,
          autoAnswer: autoAnswer,
          tags: tags,
          excludeTags: excludeTags,
          useGit: useGit);
    } else {
      final runner = ReleaseRunner(pwd);
      final pubspecDetails = runner.checkPackage(autoAnswer: autoAnswer);

      runner.pubRelease(
          pubSpecDetails: pubspecDetails,
          versionMethod: versionMethod,
          setVersion: parsedVersion,
          lineLength: lineLength,
          dryrun: dryrun,
          runTests: runTests,
          autoAnswer: autoAnswer,
          tags: tags,
          excludeTags: excludeTags,
          useGit: useGit);
    }
  } on UnitTestFailedException catch (e) {
    print('');
    print(e.message);
    exit(1);
  }
  print('');
  if (dryrun) {
    print(blue('Dry run suceeded. You packages are ready to release'));
  } else {
    print(blue('Your packages have been published.'));
  }
}

/// Checks if visual code is running and warn the user to shut it down
/// as it will create failures when we alter pubspec.yaml.
///
/// Essentialy vs-code sees the file change and then deletes .dart_tools
/// to recreate it.
///
/// If this happens whilst we are running a unit test then we will see an error similar
/// to:
/// Unable to open file .dart_tool/pub/bin/test/test.dart ... snapshot for writing snapshot changes
///
void checkForVsCode() {
  if (ProcessHelper()
      .getProcesses()
      .where((proc) => proc.name == 'code')
      .isNotEmpty) {
    print(red(
        'Visual Studio Code (vscode) has been detected. If it has the current package open then please close it before proceeding.'));
    print(
        "Vscode monitors the project's pubspec.yaml which the release process is about to update.");
    print(
        'When Vscode detects the change it will recreate the .dart_tools directory which can interfere with unit tests.');
    ask('Press enter to continue');
  }
}

int getLineLength(ArgResults results, ArgParser parser) {
  var lineLength = 80;

  if (results.wasParsed('line')) {
    final lineArg = results['line'] as String;
    final _lineLength = int.tryParse(lineArg);
    if (_lineLength == null) {
      print(red('--line argument must be an integer, found $lineArg'));
      showUsage(parser);
      exit(1);
    }
    lineLength = _lineLength;
  }
  return lineLength;
}

void showUsage(ArgParser parser) {
  print('''
Releases a dart project:
      * Increments the version no. in pubspec.yaml
      * Regenerates src/util/version.g.dart with the new version no.
      * Creates a git tag with the version no. in the form 'v<version-no>'
      * Updates the CHANGELOG.md with a new version no. and the set of
      * git commit messages.
      * Commits the above changes
      * Pushes the final results to git
      * Runs docker unit tests checking that they have passed (?how)
      * Publishes the package using 'dart pub publish'
  
  If the 'multi' command is passed than a simultaneous release of related packages is performed.

Usage:

pub_release [multi|help] [--dry-run] [--[no]-test] [--line=nn] [--askVersion|--setVersion] [--tags="tag,.."]

${parser.usage}
      ''');
}
