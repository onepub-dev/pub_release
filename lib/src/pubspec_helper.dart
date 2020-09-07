import 'dart:io';

import 'package:dcli/dcli.dart';

/// Search for and returns the projects pubspec.yaml.
///
/// By default  start in the current working directory (CWD) and search
/// up the tree path until we find a pubspec.
///
/// If you pass a [startingDir] we start the search from
/// [startingDir] rather than the CWD
///
PubSpecFile getPubSpec({String startingDir}) {
  var pubspecPath = findPubSpec(startingDir: startingDir);
  var pubspec = PubSpecFile.fromFile(pubspecPath);
  return pubspec;
}

/// Returns the path to the pubspec.yaml.
/// [startingDir] is the directory we start searching from.
/// We climb the path searching for the pubspec.yaml
String findPubSpec({String startingDir}) {
  startingDir ??= pwd;
  var pubspecName = 'pubspec.yaml';
  var cwd = startingDir;
  var found = true;

  var pubspecPath = join(cwd, pubspecName);
  // climb the path searching for the pubspec
  while (!exists(pubspecPath)) {
    cwd = dirname(cwd);
    // Have we found the root?
    if (cwd == rootPath) {
      found = false;
      break;
    }
    pubspecPath = join(cwd, pubspecName);
  }

  if (!found) {
    print('Unable to find pubspec.yaml, run release from the '
        "package's root directory.");
    exit(-1);
  }
  return truepath(pubspecPath);
}
