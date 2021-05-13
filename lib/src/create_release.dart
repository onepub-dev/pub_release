import 'dart:io';

import 'package:dcli/dcli.dart';
// ignore: implementation_imports
import 'package:github/src/common/model/repos_releases.dart' as ghub;
import 'package:mime/mime.dart';
import 'package:pub_release/pub_release.dart';

import '../pub_release.dart';
import 'simple_github.dart';

void createRelease(
    {required String username,
    required String apiToken,
    required String owner,
    required String repository}) {
  final sgh = SimpleGitHub(
      username: username,
      apiToken: apiToken,
      owner: owner,
      repository: repository);

  sgh.auth();

  final pubspecPath = findPubSpec(startingDir: pwd);

  if (pubspecPath == null) {
    print('Unable to find pubspec.yaml, run ${DartScript.current.exeName} from the '
        "package's root directory.");
    exit(-1);
  }

  final pubspec = PubSpec.fromFile(pubspecPath);
  final version = pubspec.version.toString();
  final String tagName = version;

  print('Creating release for $tagName');
  _createRelease(sgh: sgh, pubspec: pubspec, tagName: tagName);

  updateLatestTag(sgh: sgh, pubspec: pubspec);

  sgh.dispose();
}

/// update 'latest.<platform>' tag to point to this new tag.
void updateLatestTag({required SimpleGitHub sgh, required PubSpec pubspec}) {
  final latestTagName = 'latest.${Platform.operatingSystem}';
  print('Updating $latestTagName tag to point to "${pubspec.version}"');

  /// Delete the existing 'latest' tag and release.
  final latestRelease = sgh.getReleaseByTagName(tagName: latestTagName);
  if (latestRelease != null) {
    print("Deleting pre-existing '$latestTagName' tag and release");
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
  required SimpleGitHub sgh,
  required PubSpec pubspec,
  String? tagName,
}) {
  print('Proceeding with tagName $tagName');

  /// If there is an existing tag we overwrite it.
  final old = sgh.getReleaseByTagName(tagName: tagName);
  if (old != null) {
    print('Deleting release $tagName');
    sgh.deleteRelease(old);
  }

  print('Creating release');

  final release = sgh.release(tagName: tagName);

  /// removed this feature until  issue fixed:
  /// https://github.com/dart-lang/sdk/issues/44578
  print('Attaching assets to release: $tagName');
  addExecutablesAsAssets(sgh, pubspec, release);
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
  String? mimeType;
  String assetPath = join(dirname(script), basenameWithoutExtension(script));
  if (Platform.isWindows) {
    assetPath =
        '${join(dirname(script), basenameWithoutExtension(script))}.exe';
    mimeType = lookupMimeType(assetPath);
  } else {
    assetPath = join(dirname(script), basenameWithoutExtension(script));

    /// fake the .exe extension for the mime lookup.
    mimeType = lookupMimeType('$assetPath.exe');
  }

  /// use dcli to compile.
  DartScript.fromFile(script).compile(overwrite: true);

  addAsset(ghr, release, assetPath: assetPath, mimeType: mimeType);
}

/// Uploads the file at [assetPath] to git hub against the given release.
/// If [mimeType] is not supplied then the extension of the [assetPath] is
/// used to determine the [mimeType].
///
void addAsset(SimpleGitHub ghr, ghub.Release release,
    {required String assetPath, String? mimeType}) {
  mimeType ??= lookupMimeType(assetPath);

  print('Sending Asset  $assetPath mimeType: $mimeType');
  ghr.attachAssetFromFile(
    release: release,
    assetPath: assetPath,
    assetName: basename(assetPath),
    mimeType: mimeType!,
  );
}
