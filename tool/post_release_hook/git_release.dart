#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:args/args.dart';
import 'package:dcli/dcli.dart' hide Settings;
import 'package:pub_release/pub_release.dart';

void main(List<String> args) {
  final parser = ArgParser()..addFlag('dry-run');

  final parsed = parser.parse(args);

  final dryrun = parsed['dry-run'] as bool;

  final settings = Settings.load();

  if (!dryrun) {
    'github_release '
            '-u ${settings.username} '
            '--apiToken ${settings.apiToken} '
            '--owner ${settings.owner} '
            '--repository ${settings.repository}'
        .start(workingDirectory: DartProject.self.pathToProjectRoot);
  } else {
    print('Skipping github_release due to --dry-run');
  }
}
