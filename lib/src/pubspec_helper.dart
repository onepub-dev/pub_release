import 'package:dcli/dcli.dart';

/// Returns the path to the pubspec.yaml.
/// [startingDir] is the directory we start searching from.
/// We climb the path searching for the pubspec.yaml
String? findPubSpec({String? startingDir}) {
  startingDir ??= pwd;
  const pubspecName = 'pubspec.yaml';
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

  if (found) {
    return truepath(pubspecPath);
  }
  return null;
}
