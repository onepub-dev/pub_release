import 'dart:io';

import 'package:dcli/dcli.dart';
// ignore: implementation_imports
import 'package:github/src/common/model/repos_releases.dart' as ghub;
import 'package:mime/mime.dart';
import 'package:pub_release/pub_release.dart';

import '../pub_release.dart';

void createRelease(
    {String username, String apiToken, String owner, String repository}) {
  final sgh = SimpleGitHub(
      username: username,
      apiToken: apiToken,
      owner: owner,
      repository: repository);

  sgh.auth();

  final pubspecPath = findPubSpec(startingDir: pwd);

  if (pubspecPath == null) {
    print('Unable to find pubspec.yaml, run release from the '
        "package's root directory.");
    exit(-1);
  }

  final pubspec = PubSpec.fromFile(pubspecPath);
  final version = pubspec.version.toString();
  final String tagName = version;

  print('Creating release for $tagName');
  _createRelease(sgh: sgh, pubspec: pubspec, tagName: tagName);

  updateLatestTag(sgh: sgh, pubspec: pubspec, tagName: tagName);

  sgh.dispose();
}

/// update 'latest' tag to point to this new tag.
void updateLatestTag({SimpleGitHub sgh, PubSpec pubspec, String tagName}) {
  const latestTagName = 'latest';
  print('Updating $latestTagName tag to point to "${pubspec.version}"');

  /// Delete the existing 'latest' tag and release.
  final latestRelease = waitForEx(sgh.getByTagName(tagName: latestTagName));
  if (latestRelease != null) {
    sgh.deleteRelease(latestRelease);
    sgh.deleteTag(latestTagName);
  }

  /// create new latest tag and release.
  _createRelease(sgh: sgh, pubspec: pubspec, tagName: latestTagName);
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
  final old = waitForEx(sgh.getByTagName(tagName: tagName));
  if (old != null) {
    print('Replacing release $tagName');
    sgh.deleteRelease(old);
  }

  print('Creating release');

  print('Attaching assets to release: $tagName');

  //final release = 
  
  waitForEx(sgh.release(tagName: tagName));

  /// removed this feature until  issue fixed:
  /// https://github.com/dart-lang/sdk/issues/44578
  /// addExecutablesAsAssets(sgh, pubspec, release);
}

void addExecutablesAsAssets(
    SimpleGitHub ghr, PubSpec pubspec, ghub.Release release) {
  final executables = pubspec.executables;

  for (final executable in executables) {
    final script = join(pwd, 'bin', '${executable.name}.dart');
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
    assetPath = join(dirname(script), basenameWithoutExtension(script));

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
  mimeType ??= lookupMimeType(assetPath);

  print('Sending Asset  $assetPath');
  ghr.attachAssetFromFile(
    release: release,
    assetPath: assetPath,
    assetName: basename(assetPath),
    mimeType: mimeType,
  );
}
