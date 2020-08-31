#! /usr/bin/env dcli

import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:pub_release/pub_release.dart';
import 'package:settings_yaml/settings_yaml.dart';

/// Creates a release tag on github.
/// Normally this process happens automatically using a GitHub Action workflow.

void main(List<String> args) {
  var parser = ArgParser();
  parser.addFlag(
    'verbose',
    abbr: 'v',
    negatable: false,
    defaultsTo: false,
    help: 'Logs additional details to the cli',
  );

  var settings =
      SettingsYaml.load(filePath: join(pwd, 'github_credentials.yaml'));
  var username = settings['username'] as String;
  var apiToken = settings['apiToken'] as String;
  var owner = settings['owner'] as String;
  var repository = settings['repository'] as String;

  var pubspec = PubSpecFile.fromFile(join(pwd, 'pubspec.yaml'));
  var version = pubspec.version;
  var tagName = version.toString();

  var ghr = GitHubRelease(
      username: username,
      apiToken: apiToken,
      owner: owner,
      repository: repository);
  ghr.auth();

  var release = ghr.getByTagName(tagName: tagName);
  if (release != null) {
    print('Deleting old tag: $tagName');
    ghr.deleteRelease(release);
  }
  print('Creating tag $owner/$repository:$tagName');
  ghr.release(tagName: tagName);

  var parsed = parser.parse(args);

  if (parsed.wasParsed('verbose')) {
    Settings().setVerbose(enabled: true);
  }
}

void showUsage(ArgParser parser) {
  print('Usage: create_tag.dart ');
  print(parser.usage);
  exit(1);
}
