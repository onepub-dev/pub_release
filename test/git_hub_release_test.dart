// import 'dart:io';

// import 'package:dcli/dcli.dart';
// import 'package:mime/mime.dart';
// import 'package:pub_release/src/git_hub_release.dart';

void main() {
//   var ghr = GitHubRelease(
//       username: 'bsutton',
//       apiToken: 'XXXXX',
//       owner: 'bsutton',
//       repository: 'dcli');

//   ghr.auth();

//   var tagName = '0.0.3-${Platform.operatingSystem}';

//   /// update latest tag to point to this new tag.
//   var old = ghr.getByTagName(tagName: tagName);
//   if (old != null) {
//     print('replacing release $tagName');
//     ghr.deleteRelease(old);
//   }

//   // 'dcli compile -o $HOME/git/dcli/bin/dcli_install.dart'.run;
//   var exe = '$HOME/git/dcli/bin/dcli_install';
//   print('Creating release: $tagName');
//   var release = ghr.release(tagName: tagName);

// // 'application/vnd.microsoft.portable-executable'
//   print('Sending Asset  $exe');
//   ghr.attachAssetFromFile(
//     release: release,
//     assetPath: exe,
//     assetName: 'dcli_install',
//     // assetLabel: 'DCli installer',
//     mimeType: lookupMimeType('$exe.exe'),
//   );
//   print('send complete');

//   /// update latest tag to point to this new tag.
//   var latest = ghr.getByTagName(tagName: 'latest-${Platform.operatingSystem}');
//   if (latest != null) {
//     ghr.deleteRelease(latest);
//   }

//   release = ghr.release(tagName: 'latest-${Platform.operatingSystem}');

// // 'application/vnd.microsoft.portable-executable'
//   print('Sending Asset');
//   ghr.attachAssetFromFile(
//     release: release,
//     assetPath: exe,
//     assetName: 'dcli_install',
//     // assetLabel: 'DCli installer',
//     mimeType: lookupMimeType('$exe.exe'),
//   );
//   print('send complete');
}
