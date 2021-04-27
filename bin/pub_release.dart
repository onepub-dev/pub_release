#! /usr/bin/env dcli

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_release/pub_release.dart';

void main(List<String> args) {
  final parser = ArgParser();
  parser.addFlag('incVersion',
      abbr: 'i',
      defaultsTo: true,
      negatable: false,
      help: 'Prompts the user to increment the version no.');

  parser.addFlag('dry-run',
      abbr: 'n',
      negatable: false,
      help: 'Validate but do not publish the package.');

  parser.addOption('setVersion',
      abbr: 's',
      help:
          'Allows you to set the version no. from the cli. --setVersion=1.0.0');

  parser.addOption('line',
      abbr: 'l',
      defaultsTo: "80",
      help: 'Specifies the line length to use when formatting.');

  parser.addCommand('help');

  late final ArgResults results;
  try {
    results = parser.parse(args);
  } catch (e) {
    print(red('$e'));
    results = parser.parse(['help']);
  }

  // only one commmand so it must be help
  if (results.command != null) {
    showUsage(parser);
    exit(-1);
  }

  print('${Script.current.exeName} $packageVersion');

  final incVersion = results['incVersion'] as bool;
  final dryrun = results['dry-run'] as bool;
  final version = results['setVersion'] as String?;

  var lineLength = 80;

  if (results.wasParsed('line')) {
    final lineArg = results['line'] as String;
    final _lineLength = int.tryParse(lineArg);
    if (_lineLength == null) {
      print(red('--line argument must be an integer, found $lineArg'));
      showUsage(parser);
      exit(-1);
    }
    lineLength = _lineLength;
  }

  if (results.wasParsed('incVersion') && results.wasParsed('setVersion')) {
    printerr(red('You may only pass one of "setVersion" or "incVersion"'));
    showUsage(parser);
    exit(-1);
  }

  final setVersion = results.wasParsed('setVersion');

  Release().pubRelease(
      incVersion: incVersion,
      setVersion: setVersion,
      passedVersion: version,
      lineLength: lineLength,
      dryrun: dryrun);
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

      Usage:
      ${parser.usage}
      ''');
}
