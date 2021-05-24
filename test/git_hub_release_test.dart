import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:mime/mime.dart';
import 'package:pub_release/src/simple_github.dart';
import 'package:settings_yaml/settings_yaml.dart';

void main() {
  final settingsPath = truepath(join('test', 'settings.yaml'));
  print('loading settings from $settingsPath');

  final settings = SettingsYaml.load(pathToSettings: settingsPath);

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

  final ghr = SimpleGitHub(
      username: settings['username'] as String,
      apiToken: settings['apiToken'] as String,
      owner: settings['owner'] as String,
      repository: 'dcli');

  ghr.auth();

  const tagName = '0.0.3-test';

  /// update latest tag to point to this new tag.
  final old = ghr.getReleaseByTagName(tagName: tagName);

  if (old != null) {
    print('replacing release $tagName');
    ghr.deleteRelease(old);
  } else {
    print('release not found');
  }

  final exe = '$HOME/.dcli/bin/dcli_install';
  print('Creating release: $tagName');
  var release = ghr.release(tagName: tagName);

// 'application/vnd.microsoft.portable-executable'
  print('Sending Asset  $exe');
  ghr.attachAssetFromFile(
    release: release,
    assetPath: exe,
    assetName: 'dcli_install',
    // assetLabel: 'DCli installer',
    mimeType: lookupMimeType('$exe.exe')!,
  );
  print('send complete');

  /// update latest tag to point to this new tag.
  final latest =
      ghr.getReleaseByTagName(tagName: 'latest.${Platform.operatingSystem}');
  if (latest != null) {
    ghr.deleteRelease(latest);
  }

  release = ghr.release(tagName: 'latest.${Platform.operatingSystem}');

// 'application/vnd.microsoft.portable-executable'
  print('Sending Asset');
  ghr.attachAssetFromFile(
    release: release,
    assetPath: exe,
    assetName: 'dcli_install',
    // assetLabel: 'DCli installer',
    mimeType: lookupMimeType('$exe.exe')!,
  );
  print('send complete');
}
