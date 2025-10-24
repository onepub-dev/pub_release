/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io' as io;

import 'package:dcli/dcli.dart';
// the github package is badly organised.
// ignore: implementation_imports
import 'package:github/src/common/model/repos_releases.dart' as ghub;
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:pubspec_manager/pubspec_manager.dart';

import '../pub_release.dart';

Future<void> createRelease(
    {required String username,
    required String apiToken,
    required String owner,
    required String repository}) async {
  final sgh = SimpleGitHub(
      username: username,
      apiToken: apiToken,
      owner: owner,
      repository: repository)
    ..auth();

  final pubspecPath = findPubSpec(startingDir: pwd);

  if (pubspecPath == null) {
    print('Unable to find pubspec.yaml, run ${DartScript.self.exeName} '
        'from the main '
        "package's root directory.");
    io.exit(1);
  }

  final pubspec = PubSpec.loadFromPath(pubspecPath);
  final version = pubspec.version.toString();
  final tagName = version;

  print('Creating release for $tagName');
  await _createRelease(sgh: sgh, pubspec: pubspec, tagName: tagName);

  await updateLatestTag(sgh: sgh, pubspec: pubspec);

  sgh.dispose();
}

/// update `latest.<platform>` tag to point to this new tag.
Future<void> updateLatestTag(
    {required SimpleGitHub sgh, required PubSpec pubspec}) async {
  final latestTagName = 'latest.${io.Platform.operatingSystem}';
  print('Updating $latestTagName tag to point to "${pubspec.version}"');

  /// Delete the existing 'latest' tag and release.
  final latestRelease = await sgh.getReleaseByTagName(tagName: latestTagName);
  if (latestRelease != null) {
    print("Deleting pre-existing '$latestTagName' tag and release");
    await sgh.deleteRelease(latestRelease);
    await sgh.deleteTag(latestTagName);
  }

  /// create new latest tag and release.
  await _createRelease(sgh: sgh, pubspec: pubspec, tagName: latestTagName);
}

/// Creates a release for the given tagname.
/// After creating the tag we upload each exe listed in pubspec.yaml
/// as an asset attached to the release.
Future<void> _createRelease({
  required SimpleGitHub sgh,
  required PubSpec pubspec,
  String? tagName,
}) async {
  print('Proceeding with tagName $tagName');

  /// If there is an existing tag we overwrite it.
  final old = await sgh.getReleaseByTagName(tagName: tagName);
  print('Deleting release $tagName');
  if (old != null) {
    await sgh.deleteRelease(old);
  }

  print('Creating release');

  final release = await sgh.release(tagName: tagName);

  /// removed this feature until  issue fixed:
  /// https://github.com/dart-lang/sdk/issues/44578
  print('Attaching assets to release: $tagName');
  await addExecutablesAsAssets(sgh, pubspec, release);
}

Future<void> addExecutablesAsAssets(
    SimpleGitHub ghr, PubSpec pubspec, ghub.Release release) async {
  final executables = pubspec.executables;

  for (final executable in executables.list) {
    final script = join(pwd, 'bin', '${executable.name}.dart');
    await addExecutableAsset(ghr, release, script);
  }
}

Future<void> addExecutableAsset(
    SimpleGitHub ghr, ghub.Release release, String script) async {
  String? mimeType;
  var assetPath = join(dirname(script), basenameWithoutExtension(script));
  if (io.Platform.isWindows) {
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

  await addAsset(ghr, release, assetPath: assetPath, mimeType: mimeType);
}

/// Uploads the file at [assetPath] to git hub against the given release.
/// If [mimeType] is not supplied then the extension of the [assetPath] is
/// used to determine the [mimeType].
///
Future<void> addAsset(SimpleGitHub ghr, ghub.Release release,
    {required String assetPath, String? mimeType}) async {
  mimeType ??= lookupMimeType(assetPath);

  print('Sending Asset  $assetPath mimeType: $mimeType');
  await ghr.attachAssetFromFile(
    release: release,
    assetPath: assetPath,
    assetName: basename(assetPath),
    mimeType: mimeType!,
  );
}
