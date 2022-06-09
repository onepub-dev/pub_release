#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */



import 'package:dcli/dcli.dart';

/// This hook does a pub global activate so we are running the lateset version
/// pub_release whenever we push it to pub.dev.

void main(List<String> args) {
  final parser = ArgParser()..addFlag('dry-run');

  final parsed = parser.parse(args);

  final dryrun = parsed['dry-run'] as bool;

  print('activating latest version of pub_release');

  if (!dryrun) {
    'dart pub global activate pub_release'.run;
  } else {
    print('Skipping pub global activate due to --dry-run');
  }
}
