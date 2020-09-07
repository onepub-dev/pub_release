#! /usr/bin/env dcli

import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:pub_release/pub_release.dart';
import 'package:settings_yaml/settings_yaml.dart';

/// Creates a release tag on github.
///
/// The tag name uses the version no. in the project pubspec.yaml.
///
/// To automate this process you can use [github_workflow_release] in a github workflow.
void main(List<String> args) {
  var parser = ArgParser();
  parser.addFlag(
    'verbose',
    abbr: 'v',
    negatable: false,
    defaultsTo: false,
    help: 'Logs additional details to the cli',
  );

  parser.addOption('username',
      abbr: 'u', help: 'The github username used to auth.');
  parser.addOption('apiToken',
      abbr: 't',
      help: 'The github personal api token used to auth with username.');
  parser.addOption('owner',
      abbr: 'o',
      help:
          'The owner of of the github repository i.e. bsutton from bsutton/pub_release.');
  parser.addOption('repository',
      abbr: 'r',
      help: 'The github repository i.e. pub_release from bsutton/pub_release.');

  parser.addOption('suffix',
      abbr: 's',
      help:
          ''''A suffix appended to the version no.,  which is then used to generate the tagName. 
This is often use to append a platform designator. e.g 1.0.0-linux''',
      defaultsTo: 'linux');

  var parsed = parser.parse(args);

  var settings =
      SettingsYaml.load(pathToSettings: join(pwd, 'github_credentials.yaml'));
  var username = required('username', parsed, settings, parser);
  var apiToken = required('apiToken', parsed, settings, parser);
  var owner = required('owner', parsed, settings, parser);
  var repository = required('repository', parsed, settings, parser);
  var suffix = parsed['suffix'] as String;

  createRelease(
      username: username,
      apiToken: apiToken,
      owner: owner,
      repository: repository,
      suffix: suffix);
}

String required(
    String name, ArgResults parsed, SettingsYaml settings, ArgParser parser) {
  var value = settings[name] as String;

  if (parsed.wasParsed(name)) {
    value = parsed[name] as String;
    settings[name] = value;
  }

  if (value == null) {
    printerr(red('The argument $name is required.'));
    showUsage(parser);
  }

  return value;
}

void showUsage(ArgParser parser) {
  print(
      'Creates a github release tag and attached each executable listed in the pubspec.yaml as an asset to the release.');
  print('Usage: github_release.dart ');

  print(parser.usage);
  exit(1);
}
