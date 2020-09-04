import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:dcli/src/script/entry_point.dart';
import 'package:github/src/common/model/repos_releases.dart' as ghub;
import 'package:mime/mime.dart';
import 'package:pub_release/pub_release.dart';

import '../pub_release.dart';

void createRelease({String suffix, String username, String apiToken, String owner, String repository}) {
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
  // var executables = pubspec.executables;

  // for (var executable in executables) {
  //   var script = '$pwd/${executable.scriptPath}';

  addAsset(ghr, release, 'bin/dcli.dart');
  addAsset(ghr, release, 'bin/dcli_complete.dart');
  addAsset(ghr, release, 'bin/dcli_install.dart');
  addAsset(ghr, release, 'bin/dshell_upgrade.dart');
}

void addAsset(GitHubRelease ghr, ghub.Release release, String script) {
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

  /// use dcli to compile.
  EntryPoint().process(['compile', script]);

  print('Sending Asset  $assetPath');
  ghr.attachAssetFromFile(
    release: release,
    assetPath: assetPath,
    assetName: basename(assetPath),
    mimeType: mimeType,
  );
}
