/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_semver/pub_semver.dart';

void runPreReleaseHooks(String pathToPackageRoot,
        {required Version? version, required bool dryrun}) =>
    runHooks(
        pathToPackageRoot, preReleaseRoot(pathToPackageRoot), 'pre release',
        version: version, dryrun: dryrun);

void runPostReleaseHooks(String pathToPackageRoot,
        {required Version? version, required bool dryrun}) =>
    runHooks(
        pathToPackageRoot, postReleaseRoot(pathToPackageRoot), 'post release',
        version: version, dryrun: dryrun);

/// looks for any scripts in the packages tool/pre_release_hook directory
/// and runs them all in alpha numeric order
void runHooks(String pathToPackageRoot, String pathToHooks, String type,
    {required bool dryrun, Version? version}) {
  var ran = false;
  if (exists(pathToHooks)) {
    for (final hook in getHooks(pathToHooks)) {
      if (_isIgnoredFile(hook)) {
        continue;
      }
      if (isExecutable(hook)) {
        print(blue('Running $type: ${basename(hook)}'));

        runHook(hook, pathToPackageRoot,
            args: [if (dryrun) '--dry-run', version.toString()]);

        ran = true;
      } else {
        print(orange('Skipping hook: $hook as it is not marked as executable'));
      }
    }
  }
  if (!ran) {
    print(orange('No $type hooks found in $pathToHooks'));
  }
}

void runHook(String pathToHook, String pathToPackageRoot,
    {required List<String> args}) {
  if (extension(pathToHook) == '.dart') {
    /// incase dcli isn't installed.
    DartSdk()
        .run(args: [pathToHook, ...args], workingDirectory: pathToPackageRoot);
  } else {
    '$pathToHook ${args.join(' ')}'.start(workingDirectory: pathToPackageRoot);
  }
}

const _ignoredExtensions = ['.yaml', '.ini', '.config', '.ignore'];
bool _isIgnoredFile(String pathToHook) {
  final _extension = extension(pathToHook);

  if (_ignoredExtensions.contains(_extension)) {
    return true;
  }

  if (Platform.isWindows && _extension == '.sh') {
    print(orange('Ignoring .sh script: $pathToHook'));
    return true;
  }

  if (!Platform.isWindows && _extension == '.bat' ||
      _extension == '.exe' ||
      _extension == '.ps1') {
    print(orange('Ignoring $_extension executable: $pathToHook'));
    return true;
  }

  return false;
}

/// Get the list of hooks from the root and return then
/// sorted alpha-numerically
List<String> getHooks(String hookRootPath) {
  var hooks = <String>[];

  if (exists(hookRootPath)) {
    hooks = find('*', workingDirectory: hookRootPath).toList();

    // ignore: cascade_invocations
    hooks.sort((lhs, rhs) => lhs.compareTo(rhs));
  }

  return hooks;
}

/// returns the path to the pre_release_hook directory
/// for the given package.
String preReleaseRoot(String pathToPackageRoot) =>
    join(pathToPackageRoot, 'tool', 'pre_release_hook');

/// returnst he path to the post_release_hook directory
/// for the given package.
String postReleaseRoot(String pathToPackageRoot) =>
    join(pathToPackageRoot, 'tool', 'post_release_hook');
