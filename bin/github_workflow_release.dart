#! /usr/bin/env dcli

import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:pub_release/pub_release.dart';

/// This app is intended to be used as part of a github workflow to create a release with
/// attached assets for a Dart project.
///
/// Each executable listed in the Dart packages pubspec.yaml is compiled and the resulting
/// binary attached as an asset.
///
/// To create a release from your local system use 'github_tag'.
///
/// ```github workflow
///
///name: Create release
///on:
///  push:
///    tags:
///      - '*'
///jobs:
///  build:
///    runs-on: ubuntu-latest
///    container:
///      image:  google/dart:latest
///    steps:
///     - uses: actions/checkout@v2
///
///     - name: fix the dart paths
///       run: export PATH="${PATH}":/usr/lib/dart/bin:"${HOME}/.pub-cache/bin"
///
///     - name: install pub_release
///       run:  pub global activate pub_release
///
///     - name: pub get for project
///       run: pub get
///
///     - name: create release
///       env:
///         APITOKEN:  ${{ secrets.APITOKEN }}
///       run: github_workflow_release --username bsutton --apiToken "$APITOKEN" --owner bsutton --repository dcli --suffix linux
/// ```
///
void main(List<String> args) {
  var parser = ArgParser();
  parser.addFlag(
    'debug',
    abbr: 'd',
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
This is often use to append a platform designator. e.g 1.0.0-linux''');

  var parsed = parser.parse(args);

  if (parsed.wasParsed('debug')) {
    Settings().setVerbose(enabled: true);
  }

  /// get the version from the pubspec and determine the tagname.
  var username = fetch(parser, parsed, 'username');
  var apiToken = fetch(parser, parsed, 'apiToken');
  var owner = fetch(parser, parsed, 'owner');
  var repository = fetch(parser, parsed, 'repository');
  var suffix = parsed['suffix'] as String;

  createRelease(
      suffix: suffix,
      username: username,
      apiToken: apiToken,
      owner: owner,
      repository: repository);
}

String fetch(ArgParser parser, ArgResults parsed, String name) {
  if (!parsed.wasParsed(name)) {
    printerr(red('The argument $name is required.'));
    showUsage(parser);
  }

  return parsed[name];
}

void showUsage(ArgParser parser) {
  print(
      'Usage: github_workflow_release --username <username> --apiToken <apitoken> --owner <owner> --repository <repository>');
  print(parser.usage);
  exit(1);
}
