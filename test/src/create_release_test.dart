@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:path/path.dart' hide equals;
import 'package:pub_release/src/create_release.dart';
import 'package:pub_release/src/simple_github.dart';
import 'package:settings_yaml/settings_yaml.dart';
import 'package:test/test.dart';

/// To run these tests we need test/settings.yaml
/// to have valid github credentials.
void main() {
  test('create release ...', () async {
    final settingsPath = truepath(join('test', 'settings.yaml'));
    final settings = SettingsYaml.load(pathToSettings: settingsPath);
    expect(settings.validString('username'), equals(true));
    expect(settings.validString('apiToken'), equals(true));
    expect(settings.validString('owner'), equals(true));

    createRelease(
        username: settings['username'] as String,
        apiToken: settings['apiToken'] as String,
        owner: settings['owner'] as String,
        repository: 'pub_release');
    // a();
  });

  test('delete tag', () async {
    final settingsPath = truepath(join('test', 'settings.yaml'));
    final settings = SettingsYaml.load(pathToSettings: settingsPath);
    expect(settings.validString('username'), equals(true));
    expect(settings.validString('apiToken'), equals(true));
    expect(settings.validString('owner'), equals(true));

    SimpleGitHub(
        username: settings['username'] as String,
        apiToken: settings['apiToken'] as String,
        owner: settings['owner'] as String,
        repository: 'dcli')
      ..auth()
      ..deleteTag('latest.${Platform.operatingSystem}');

    //     Stream<Tag> tags = _repoService.listTags(_repositorySlug);
    // var tag = tags.firstWhere((tag) => tag.name == 'latest');
    // _repoService.deltag.
  });
}

// void a() {
//   final settingsPath = truepath(join('test', 'settings.yaml'));
//   final settings = SettingsYaml.load(pathToSettings: settingsPath);

//   expect(settings.validString('username'), equals(true));
//   expect(settings.validString('apiToken'), equals(true));
//   expect(settings.validString('owner'), equals(true));

//   final sgh = SimpleGitHub(
//       username: settings['username'] as String,
//       apiToken: settings['apiToken'] as String,
//       owner: settings['owner'] as String,
//       repository: 'pub_release')
//     ..auth();

//   const tagName = '0.0.3-test';

//   /// update latest tag to point to this new tag.
//   final old = sgh.getReleaseByTagName(tagName: tagName);

//   if (old != null) {
//     print('replacing release $tagName');
//     sgh.deleteRelease(old);
//   } else {
//     print('release not found');
//   }

//   final exe = '$HOME/.dcli/bin/dcli_install';
//   print('Creating release: $tagName');
//   var release = sgh.release(tagName: tagName);

// // 'application/vnd.microsoft.portable-executable'
//   var mimeType = lookupMimeType('$exe.exe')!;
//   print('Sending Asset  $exe mimeType: $mimeType');
//   sgh.attachAssetFromFile(
//     release: release,
//     assetPath: exe,
//     assetName: 'dcli_install',
//     // assetLabel: 'DCli installer',
//     mimeType: mimeType,
//   );
//   print('send complete');

//   /// update latest tag to point to this new tag.
//   final latest =
//       sgh.getReleaseByTagName(tagName: 'latest.${Platform.operatingSystem}');
//   if (latest != null) {
//     sgh.deleteRelease(latest);
//   }

//   release = sgh.release(tagName: 'latest.${Platform.operatingSystem}');

// // 'application/vnd.microsoft.portable-executable'
//   mimeType = lookupMimeType('$exe.exe')!;
//   print('Sending Asset mimeType: $mimeType');
//   sgh.attachAssetFromFile(
//     release: release,
//     assetPath: exe,
//     assetName: 'dcli_install',
//     // assetLabel: 'DCli installer',
//     mimeType: mimeType,
//   );
//   print('send complete');
// }
