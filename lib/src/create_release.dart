import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:github/src/common/model/repos_releases.dart' as ghub;
import 'package:mime/mime.dart';
import 'package:pub_release/pub_release.dart';

import '../pub_release.dart';

void createRelease(
    {String suffix,
    String username,
    String apiToken,
    String owner,
    String repository}) {
  var ghr = SimpleGitHub(
      username: username,
      apiToken: apiToken,
      owner: owner,
      repository: repository);

  ghr.auth();

  var pubspecPath = findPubSpec(startingDir: pwd);

  var pubspec = PubSpec.fromFile(pubspecPath);
  var version = pubspec.version.toString();
  String tagName;
  if (suffix != null) {
    tagName = '$version-$suffix';
  } else {
    tagName = version;
  }

  print('Creating release for $tagName');
  _createRelease(ghr: ghr, pubspec: pubspec, tagName: tagName);

  tagName = 'latest-${Platform.operatingSystem}';
  print('Creating release for "$tagName"');
  _createRelease(ghr: ghr, pubspec: pubspec, tagName: tagName);
}

/// Creates a release for the given tagname.
/// After creating the tag we upload each exe listed in pubspec.yaml
/// as an asset attached to the release.
void _createRelease({
  SimpleGitHub ghr,
  PubSpec pubspec,
  String tagName,
}) {
  print('Proceeding with tagName $tagName');

  /// If there is an existing tag we overwrite it.
  var old = waitForEx(ghr.getByTagName(tagName: tagName));
  if (old != null) {
    print('replacing release $tagName');
    ghr.deleteRelease(old);
  }

  print('Creating release: $tagName');

  /// update latest tag to point to this new tag.
  var latest = waitForEx(ghr.getByTagName(tagName: tagName));
  if (latest != null) {
    ghr.deleteRelease(latest);
    ghr.deleteTag(tagName);
  }
  // var release =
  var release = waitForEx(ghr.release(tagName: tagName));
  addExecutablesAsAssets(ghr, pubspec, release);
}

void addExecutablesAsAssets(
    SimpleGitHub ghr, PubSpec pubspec, ghub.Release release) {
  var executables = pubspec.executables;

  for (var executable in executables) {
    var script = join(pwd, 'bin', '${executable.name}.dart');
    addAsset(ghr, release, script);
  }
}

void addAsset(SimpleGitHub ghr, ghub.Release release, String script) {
  String assetPath;
  String mimeType;
  if (Platform.isWindows) {
    assetPath =
        '${join(dirname(script), basenameWithoutExtension(script))}.exe';
    mimeType = lookupMimeType('$assetPath');
  } else {
    assetPath = '${join(dirname(script), basenameWithoutExtension(script))}';

    /// fake the .exe extension for the mime lookup.
    mimeType = lookupMimeType('$assetPath.exe');
  }

  /// use dcli to compile.
  Script.fromFile(script).compile(overwrite: true);

  print('Sending Asset  $assetPath');
  ghr.attachAssetFromFile(
    release: release,
    assetPath: assetPath,
    assetName: basename(assetPath),
    mimeType: mimeType,
  );
}
