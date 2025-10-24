#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli/dcli.dart' hide Settings;
import 'package:pub_release/pub_release.dart';

/// Deletes the latest github tag for `latest.<os>`.
void main(List<String> args) async {
  final settings = Settings.load();

  if (settings.username == null) {
    print(red('username not set in settings.yaml'));
    exit(1);
  }

  if (settings.apiToken == null) {
    print(red('apiToken not set in settings.yaml'));
    exit(1);
  }

  if (settings.owner == null) {
    print(red('owner not set in settings.yaml'));
    exit(1);
  }

  final sgh = SimpleGitHub(
      username: settings.username!,
      apiToken: settings.apiToken!,
      owner: settings.owner!,
      repository: 'pub_release')
    ..auth();

  final tagName = 'latest.${Platform.operatingSystem}';

  /// If there is an existing tag we overwrite it.
  final old = await sgh.getReleaseByTagName(tagName: tagName);
  if (old != null) {
    // cli script.
    // ignore: avoid_print
    print('replacing release $tagName');
  }
  await sgh.listReferences();
  await sgh.deleteTag(tagName);
  await sgh.listReferences();
  sgh.dispose();
}
