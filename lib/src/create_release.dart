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
  var sgh = SimpleGitHub(
      username: username,
      apiToken: apiToken,
      owner: owner,
      repository: repository);

  sgh.auth();

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
  _createRelease(sgh: sgh, pubspec: pubspec, tagName: tagName);

  tagName = 'latest-${Platform.operatingSystem}';
  print('Creating release for "$tagName"');
  _createRelease(sgh: sgh, pubspec: pubspec, tagName: tagName);
}

/// Creates a release for the given tagname.
/// After creating the tag we upload each exe listed in pubspec.yaml
/// as an asset attached to the release.
void _createRelease({
  SimpleGitHub sgh,
  PubSpec pubspec,
  String tagName,
}) {
  print('Proceeding with tagName $tagName');

  /// If there is an existing tag we overwrite it.
  var old = waitForEx(sgh.getByTagName(tagName: tagName));
  if (old != null) {
    print('replacing release $tagName');
    sgh.deleteRelease(old);
  }

  print('Creating release: $tagName');

  /// update latest tag to point to this new tag.
  var latest = waitForEx(sgh.getByTagName(tagName: tagName));
  if (latest != null) {
    sgh.deleteRelease(latest);
    sgh.deleteTag(tagName);
  }
  // var release =
  var release = waitForEx(sgh.release(tagName: tagName));
  addExecutablesAsAssets(sgh, pubspec, release);
}

void addExecutablesAsAssets(
    SimpleGitHub ghr, PubSpec pubspec, ghub.Release release) {
  var executables = pubspec.executables;

  for (var executable in executables) {
    var script = join(pwd, 'bin', '${executable.name}.dart');
    addExecutableAsset(ghr, release, script);
  }
}

void addExecutableAsset(SimpleGitHub ghr, ghub.Release release, String script) {
  String assetPath;
  String mimeType;
  if (Platform.isWindows) {
    assetPath =
        '${join(dirname(script), basenameWithoutExtension(script))}.exe';
    mimeType = lookupMimeType('$assetPath.exe');
  } else {
    assetPath = '${join(dirname(script), basenameWithoutExtension(script))}';

    /// fake the .exe extension for the mime lookup.
    mimeType = lookupMimeType('$assetPath.exe');
  }

  /// use dcli to compile.
  Script.fromFile(script).compile(overwrite: true);

  addAsset(ghr, release, assetPath: assetPath, mimeType: mimeType);
}

/// Uploads the file at [assetPath] to git hub against the given release.
/// If [mimeType] is not supplied then the extension of the [assetPath] is
/// used to determine the [mimeType].
///
void addAsset(SimpleGitHub ghr, ghub.Release release,
    {String assetPath, String mimeType}) {
  String mimeType;
  mimeType ??= lookupMimeType('$assetPath');

  print('Sending Asset  $assetPath');
  ghr.attachAssetFromFile(
    release: release,
    assetPath: assetPath,
    assetName: basename(assetPath),
    mimeType: mimeType,
  );
}
