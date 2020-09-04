#! /usr/bin/env dcli

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_release/pub_release.dart';

void main(List<String> args) {
  var parser = ArgParser();
  parser.addFlag('incVersion',
      abbr: 'i',
      defaultsTo: true,
      help: 'Prompts the user to increment the version no.');

  parser.addOption('setVersion',
      abbr: 's',
      help:
          'Allows you to set the version no. from the cli. --setVersion=1.0.0');

  parser.addOption('line',
      abbr: 'l',
      help:
          'Specifies');

  parser.addCommand('help');
  var results = parser.parse(args);

  // only one commmand so it must be help
  if (results.command != null) {
    showUsage(parser);
    exit(0);
  }

  var incVersion = results['incVersion'] as bool;
  var version = results['setVersion'] as String;

  if (results.wasParsed('incVersion') && results.wasParsed('setVersion')) {
    printerr(red('You may only pass one of "setVersion" or "incVersion"'));
    showUsage(parser);
    exit(0);
  }

  var setVersion = results.wasParsed('setVersion');

  Release()
      .pub_release(incVersion, setVersion: setVersion, passedVersion: version);
}

void showUsage(ArgParser parser) {
  print('''Releases a dart project:
      * Increments the version no. in pubspec.yaml
      * Regenerates src/util/version.g.dart with the new version no.
      * Creates a git tag with the version no. in the form 'v<version-no>'
      * Updates the CHANGELOG.md with a new version no. and the set of
      * git commit messages.
      * Commits the above changes
      * Pushes the final results to git
      * Runs docker unit tests checking that they have passed (?how)
      * Publishes the package using 'pub publish'

      Usage:
      ${parser.usage}
      ''');
}
