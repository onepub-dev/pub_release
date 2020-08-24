#! /usr/bin/env dcli

import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:github/src/common/model/repos_releases.dart' as ghub;
import 'package:mime/mime.dart';
import 'package:pub_release/pub_release.dart';

/// Pushes a release to github attaching each of the executables listed in the pubspec.yaml as assets.abstract
void main(List<String> args) {
  var parser = ArgParser();
  parser.addFlag(
    'debug',
    abbr: 'd',
    negatable: false,
    defaultsTo: false,
    help: 'Logs additional details to the cli',
  );

  parser.addOption('version', abbr: 'v', help: 'The version no to apply.');
  parser.addOption('username', abbr: 'u', help: 'The github username used to auth.');
  parser.addOption('apiToken', abbr: 't', help: 'The github personal api token used to auth with username.');
  parser.addOption('owner',
      abbr: 'o', help: 'The owner of of the github repository i.e. bsutton from bsutton/pub_release.');
  parser.addOption('repository', abbr: 'r', help: 'The github repository i.e. pub_release from bsutton/pub_release.');

  parser.addOption('suffix',
      abbr: 's', help: ''''A suffix appended to the version no. that which is then used to generate the tagName. 
This is often use to append a platform designator. e.g linux''');

  var parsed = parser.parse(args);

  if (parsed.wasParsed('debug')) {
    Settings().setVerbose(enabled: true);
  }

  var username = required(parser, parsed, 'username');
  var apiToken = required(parser, parsed, 'apiToken');
  var owner = required(parser, parsed, 'owner');
  var repository = required(parser, parsed, 'repository');
  var suffix = parsed['suffix'] as String;

  /// get the version from the pubspec and determine the tagname.
  var pubspecPath = Release().findPubSpec(pwd);

  var pubspec = PubSpecFile.fromFile(pubspecPath);
  var version = pubspec.version.toString();
  var tagName;
  if (suffix != null) {
    tagName = '$version-$suffix';
  } else {
    tagName = version;
  }

  print('Proceeding with tagName $tagName');
  var ghr = GitHubRelease(username: username, apiToken: apiToken, owner: owner, repository: repository);

  ghr.auth();

  /// If there is an existing tag we overwrite it.
  var old = ghr.getByTagName(tagName: tagName);
  if (old != null) {
    print('replacing release $tagName');
    ghr.deleteRelease(old);
  }

  print('Creating release: $tagName');
  var release = ghr.release(tagName: tagName);

  addExecutablesAsAssets(ghr, pubspec, release);

  /// update latest tag to point to this new tag.
  var latest = ghr.getByTagName(tagName: 'latest-${Platform.operatingSystem}');
  if (latest != null) {
    ghr.deleteRelease(latest);
  }
  release = ghr.release(tagName: 'latest-${Platform.operatingSystem}');
  addExecutablesAsAssets(ghr, pubspec, release);
}

void addExecutablesAsAssets(GitHubRelease ghr, PubSpecFile pubspec, ghub.Release release) {
  var executables = pubspec.executables;

  for (var executable in executables) {
    var script = '$pwd/${executable.script}';

    String assetPath;
    String mimeType;
    if (Platform.isWindows) {
      assetPath = '${join(dirname(script), basenameWithoutExtension(script))}.exe';
      mimeType = lookupMimeType('$assetPath');
    } else {
      assetPath = '${join(dirname(script), basenameWithoutExtension(script))}';

      /// fake the .exe extension for the mime lookup.
      mimeType = lookupMimeType('$assetPath.exe');
    }

    'dart2native -o $assetPath $script'.run;

    print('Sending Asset  $assetPath');
    ghr.attachAssetFromFile(
      release: release,
      assetPath: assetPath,
      assetName: basename(assetPath),
      mimeType: mimeType,
    );
  }
}

String required(ArgParser parser, ArgResults parsed, String name) {
  if (!parsed.wasParsed(name)) {
    printerr(red('The argument $name is required.'));
    showUsage(parser);
  }

  return parsed[name];
}

void showUsage(ArgParser parser) {
  print(
      'Usage: git_release.dart --username <username> --apiToken <apitoken> --owner <owner> --repository <repository>');
  print(parser.usage);
  exit(1);
}
