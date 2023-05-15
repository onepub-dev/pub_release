#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';
import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:pub_release/pub_release.dart';
import 'package:settings_yaml/settings_yaml.dart';

/// Creates a release tag on github.
///
/// The tag name uses the version no. in the project pubspec.yaml.
///
/// To automate this process you can use github_workflow_release in
/// a github workflow.
void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Logs additional details to the cli',
    )
    ..addOption('username',
        abbr: 'u', help: 'The github username used to auth.')
    ..addOption('apiToken',
        abbr: 't',
        help: 'The github personal api token used to auth with username.')
    ..addOption('owner',
        abbr: 'o',
        help:
            'The owner of of the github repository i.e. bsutton from bsutton/pub_release.')
    ..addOption('repository',
        abbr: 'r',
        help:
            'The github repository i.e. pub_release from bsutton/pub_release.');

  final parsed = parser.parse(args);

  final settings =
      SettingsYaml.load(pathToSettings: join(pwd, 'settings.yaml'));
  final username = required('username', parsed, settings, parser);
  final apiToken = required('apiToken', parsed, settings, parser);
  final owner = required('owner', parsed, settings, parser);
  final repository = required('repository', parsed, settings, parser);

  createRelease(
    username: username,
    apiToken: apiToken,
    owner: owner,
    repository: repository,
  );
}

String required(
    String name, ArgResults parsed, SettingsYaml settings, ArgParser parser) {
  var value = settings[name] as String?;

  if (parsed.wasParsed(name)) {
    value = parsed[name] as String?;
    settings[name] = value;
  }

  if (value == null) {
    printerr(red('The argument $name is required.'));
    showUsage(parser);
  }

  return value!;
}

void showUsage(ArgParser parser) {
  print('Creates a github release tag and attached each executable listed'
      ' in the pubspec.yaml as an asset to the release.');
  print('Usage: github_release.dart ');

  print(parser.usage);
  exit(1);
}
