#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';
import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:pub_release/pub_release.dart';

/// This app is intended to be used as part of a github workflow to create
/// a release with
/// attached assets for a Dart project.
///
/// Each executable listed in the Dart packages pubspec.yaml is compiled and
/// the resulting
/// binary attached as an asset.
///
/// To create a release from your local system use 'git_hub_release'.
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
///       run: github_workflow_release --username bsutton --apiToken "$APITOKEN"
///          --owner bsutton --repository dcli
/// ```
///
void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag(
      'debug',
      abbr: 'd',
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

  if (parsed.wasParsed('debug')) {
    Settings().setVerbose(enabled: true);
  }

  /// get the version from the pubspec and determine the tagname.
  final username = fetch(parser, parsed, 'username');
  final apiToken = fetch(parser, parsed, 'apiToken');
  final owner = fetch(parser, parsed, 'owner');
  final repository = fetch(parser, parsed, 'repository');

  print('creating release');

  createRelease(
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

  return parsed[name] as String;
}

void showUsage(ArgParser parser) {
  print('Usage: github_workflow_release --username <username> '
      '--apiToken <apitoken> --owner <owner> --repository <repository>');
  print(parser.usage);
  exit(1);
}
