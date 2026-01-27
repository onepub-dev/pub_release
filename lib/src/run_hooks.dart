/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

import 'multi_settings.dart';

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
  final String executable;
  final List<String> runArgs;
  if (extension(pathToHook) == '.dart') {
    executable = which('dart').path ?? 'dart';
    runArgs = [pathToHook, ...args];
  } else {
    executable = pathToHook;
    runArgs = args;
  }

  final output = <String>[];
  final progress = startFromArgs(executable, runArgs,
      workingDirectory: pathToPackageRoot,
      terminal: true,
      nothrow: true,
      progress: Progress(output.add));
  if (progress.exitCode != 0) {
    final details = output.where((line) => line.trim().isNotEmpty).join('\n');
    final message = details.isEmpty
        ? '''
Hook "${basename(pathToHook)}" failed (exit code ${progress.exitCode}).'''
        : '''
Hook "${basename(pathToHook)}" failed (exit code ${progress.exitCode}).\n$details''';
    throw PubReleaseException(message);
  }
}

const _ignoredExtensions = ['.yaml', '.ini', '.config', '.ignore'];
bool _isIgnoredFile(String pathToHook) {
  final extension0 = extension(pathToHook);

  if (_ignoredExtensions.contains(extension0)) {
    return true;
  }

  if (Platform.isWindows && extension0 == '.sh') {
    print(orange('Ignoring .sh script: $pathToHook'));
    return true;
  }

  if (!Platform.isWindows && extension0 == '.bat' ||
      extension0 == '.exe' ||
      extension0 == '.ps1') {
    print(orange('Ignoring $extension0 executable: $pathToHook'));
    return true;
  }

  return false;
}

/// Get the list of hooks from the root and return then
/// sorted alpha-numerically
List<String> getHooks(String hookRootPath) {
  var hooks = <String>[];

  if (exists(hookRootPath)) {
    hooks = find('*', workingDirectory: hookRootPath).toList()
      ..sort((lhs, rhs) => lhs.compareTo(rhs));
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
