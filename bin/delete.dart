#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */



import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:pub_release/src/simple_github.dart';
import 'package:settings_yaml/settings_yaml.dart';

/// Deletes the latest github tag for 'latest.<os>'.
void main(List<String> args) {
  final settings = SettingsYaml.load(pathToSettings: 'settings.yaml');

  if (settings['username'] == null) {
    print(red('username not set in settings.yaml'));
    exit(1);
  }

  if (settings['apiToken'] == null) {
    print(red('apiToken not set in settings.yaml'));
    exit(1);
  }

  if (settings['owner'] == null) {
    print(red('owner not set in settings.yaml'));
    exit(1);
  }

  final sgh = SimpleGitHub(
      username: settings['username'] as String,
      apiToken: settings['apiToken'] as String,
      owner: settings['owner'] as String,
      repository: 'pub_release')
    ..auth();

  final tagName = 'latest.${Platform.operatingSystem}';

  /// If there is an existing tag we overwrite it.
  final old = sgh.getReleaseByTagName(tagName: tagName);
  if (old != null) {
    // ignore: avoid_print
    print('replacing release $tagName');
  }
  sgh
    ..listReferences()
    ..deleteTag(tagName)
    ..listReferences()
    ..dispose();
}
