import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_semver/pub_semver.dart';

/// Checks that all hooks are marked as executable
void checkHooksAreReadyToRun(String pathToPackageRoot) {
  for (final hook in getHooks(preReleaseRoot(pathToPackageRoot))) {
    if (_isIgnoredFile(hook)) continue;
    if (!isExecutable(hook)) {
      print(red('Ignored non-executable hook: ${truepath(hook)}'));
      print('Remove the hook or mark it as executable');
    }
  }

  for (final hook in getHooks(postReleaseRoot(pathToPackageRoot))) {
    if (_isIgnoredFile(hook)) continue;
    if (!isExecutable(hook)) {
      print(red('Ignored non-executable hook: ${truepath(hook)}'));
      print('Remove the hook or mark it as executable');
    }
  }
}

/// looks for any scripts in the packages tool/pre_release_hook directory
/// and runs them all in alpha numeric order
void runPreReleaseHooks(String pathToPackageRoot,
    {Version? version, required bool dryrun}) {
  checkHooksAreReadyToRun(pathToPackageRoot);

  final root = preReleaseRoot(pathToPackageRoot);

  var ran = false;
  if (exists(root)) {
    for (final hook in getHooks(root)) {
      if (_isIgnoredFile(hook)) continue;
      if (isExecutable(hook)) {
        print(blue('Running pre hook: ${basename(hook)}'));
        if (extension(hook) == '.dart') {
          DartSdk().run(
              args: [hook, if (dryrun) '--dry-run', version.toString()],
              workingDirectory: pathToPackageRoot);
        } else {
          '$hook ${dryrun ? '--dry-run' : ''} ${version.toString()}'
              .start(workingDirectory: pathToPackageRoot);
        }
        ran = true;
      } else {
        print(orange('Skipping hook: $hook as it is not marked as executable'));
      }
    }
  }
  if (!ran) {
    print(orange('No pre release hooks found in $root'));
  }
}

const _ignoredExtensions = ['.yaml', '.ini', '.config'];
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

/// looks for any scripts in the packages tool/post_release_hook directory
/// and runs them all in alpha numeric order
void runPostReleaseHooks(String pathToPackageRoot,
    {Version? version, required bool dryrun}) {
  final root = postReleaseRoot(pathToPackageRoot);

  var ran = false;
  if (exists(root)) {
    for (final hook in getHooks(root)) {
      if (_isIgnoredFile(hook)) continue;
      print(blue('Running post hook: ${basename(hook)}'));
      if (extension(hook) == '.dart') {
        DartSdk().run(
            args: [hook, if (dryrun) '--dry-run', version.toString()],
            workingDirectory: pathToPackageRoot);
      } else {
        '$hook ${dryrun ? '--dry-run' : ''} ${version.toString()}'
            .start(workingDirectory: pathToPackageRoot);
      }
      ran = true;
    }
  }
  if (!ran) {
    print(orange('No post release hooks found in $root'));
  }
}

/// Get the list of hooks from the root and return then
/// sorted alpha-numerically
List<String> getHooks(String hookRootPath) {
  var hooks = <String>[];

  if (exists(hookRootPath)) {
    hooks = find('*', workingDirectory: hookRootPath).toList();

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
