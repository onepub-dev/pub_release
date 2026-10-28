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

/// @Throwing(ArgumentError)
/// @Throwing(DuplicateKeyException)
/// @Throwing(InvalidArgumentException)
/// @Throwing(NotFoundException)
/// @Throwing(PubReleaseException)
/// @Throwing(PubSpecException)
/// @Throwing(ReadException)
/// @Throwing(VersionException)
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
    throw PubReleaseException('Unable to find pubspec.yaml.');
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
/// @Throwing(ArgumentError)
/// @Throwing(InvalidArgumentException)
/// @Throwing(ReadException)
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
/// @Throwing(ArgumentError)
/// @Throwing(InvalidArgumentException)
/// @Throwing(ReadException)
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

/// @Throwing(ArgumentError)
/// @Throwing(InvalidArgumentException)
/// @Throwing(ReadException)
Future<void> addExecutablesAsAssets(
    SimpleGitHub ghr, PubSpec pubspec, ghub.Release release) async {
  for (final executable in resolveExecutableAssets(pubspec)) {
    await addExecutableAsset(ghr, release, executable.scriptPath,
        assetName: executable.assetName);
  }
}

/// Resolves all advertised executables before compilation or upload begins.
/// Names and script mappings must be portable filename stems. Sources must be
/// regular files whose canonical paths remain inside the package, including
/// when bin or a source is linked. In-memory pubspecs use the current
/// directory.
List<({String scriptPath, String assetName})> resolveExecutableAssets(
    PubSpec pubspec,
    {String? packageRoot}) {
  final root = io.Directory(packageRoot ?? dirname(pubspec.loadedFrom))
      .resolveSymbolicLinksSync();
  final bin = join(root, 'bin');
  final resolved = <({String scriptPath, String assetName})>[];

  for (final executable in pubspec.executables.list) {
    _validateExecutableFilename(executable.name);
    _validateExecutableFilename(executable.script);
    if (io.FileSystemEntity.typeSync(bin) !=
        io.FileSystemEntityType.directory) {
      throw ArgumentError('Executable bin directory must be a directory.');
    }
    final script = join(bin, '${executable.script}.dart');
    if (io.FileSystemEntity.typeSync(script) != io.FileSystemEntityType.file) {
      throw ArgumentError('Executable source must be a regular file: $script');
    }
    final realBin = io.Directory(bin).resolveSymbolicLinksSync();
    final realScript = io.File(script).resolveSymbolicLinksSync();
    if (!isWithin(root, realBin) || !isWithin(root, realScript)) {
      throw ArgumentError('Executable source and bin must remain in package.');
    }
    resolved.add((scriptPath: realScript, assetName: executable.name));
  }
  return resolved;
}

void _validateExecutableFilename(String name) {
  // Check both separator styles on every host, including Windows drive and
  // alternate-stream syntax. Trailing dots/spaces normalize away on Windows.
  if (name.isEmpty ||
      name == '.' ||
      name == '..' ||
      name.endsWith('.') ||
      name.endsWith(' ') ||
      RegExp(r'[\\/:*?"<>|\x00-\x1f]').hasMatch(name) ||
      RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)',
              caseSensitive: false)
          .hasMatch(name)) {
    throw ArgumentError.value(name, 'executable', 'Expected a simple filename');
  }
}

/// @Throwing(ArgumentError)
/// @Throwing(InvalidArgumentException)
/// @Throwing(ReadException)
Future<void> addExecutableAsset(
    SimpleGitHub ghr, ghub.Release release, String script,
    {String? assetName}) async {
  final name = assetName ?? basenameWithoutExtension(script);
  _validateExecutableFilename(name);
  final staging = io.Directory.systemTemp.createTempSync('pub_release_asset_');
  try {
    final assetPath =
        join(staging.path, io.Platform.isWindows ? '$name.exe' : name);
    final mimeType = lookupMimeType('$name.exe');

    DartSdk().runDartCompiler(DartScript.fromFile(script),
        pathToExe: assetPath, progress: Progress(print, stderr: print));

    await addAsset(ghr, release, assetPath: assetPath, mimeType: mimeType);
  } finally {
    staging.deleteSync(recursive: true);
  }
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
