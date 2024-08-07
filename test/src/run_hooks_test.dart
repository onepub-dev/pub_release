@Timeout(Duration(minutes: 5))
library;

import 'package:dcli/dcli.dart';
import 'package:dcli/posix.dart';
import 'package:path/path.dart';
import 'package:pub_release/pub_release.dart';
import 'package:pub_release/src/run_hooks.dart';
import 'package:test/test.dart';

void main() {
  test('hooks ...', () async {
    await withTempDirAsync((packageRoot) async {
      final pathToHooks = join(packageRoot, 'tool', 'pre_release_hook');
      createDir(pathToHooks, recursive: true);

      createDart(pathToHooks);

      createSh(pathToHooks);

      createBat(pathToHooks);

      runPreReleaseHooks(packageRoot, version: Version(1, 1, 1), dryrun: true);
    });
  });
}

String createDart(String pathToHooks) {
  final pathToScript = join(pathToHooks, 'test.dart');
  const body = '''
void main()      
{
  print('hello');
}
''';

  pathToScript.write(body);

  // make script executable
  chmod(pathToScript, permission: '500');

  return pathToScript;
}

String createSh(String pathToHooks) {
  final pathToScript = join(pathToHooks, 'test.sh');
  const body = '''
echo 'hello' 
''';

  pathToScript.write(body);

  // make script executable
  chmod(pathToScript, permission: '500');

  return pathToScript;
}

String createBat(String pathToHooks) {
  final pathToScript = join(pathToHooks, 'test.bat');
  const body = '''
echo 'hello' 
''';

  pathToScript.write(body);

  return pathToScript;
}
