import 'package:dcli/dcli.dart';
import 'package:path/path.dart' hide equals;
import 'package:pubspec_manager/pubspec_manager.dart';
import 'package:test/test.dart';

void main() {
  test('release', () async {
    const primaryName = 'test1';
    await withTempDirAsync((projectDir)async {
      final pathToPubspec = join(projectDir, 'pubspec.yaml');

      /// Primary pubspec.yaml
      const pubspecString = '''
name: $primaryName
version: 1.0.0
description: A test
environment: 
  sdk: 1.0.0

dependencies:
  donttouchme: 1.2.0
 
executables:
  critical_test:
  ct: critical_test
''';
      final pubspec = PubSpec.loadFromString(pubspecString);

      // ignore: cascade_invocations
      pubspec.saveTo(pathToPubspec);

      /// pause for a moment incase an IDE is monitoring the pubspec.yaml
      /// changes. If we move too soon the .dart_tools directory may not exist.
      sleep(2);

      final newPubspec = PubSpec.loadFromPath(pathToPubspec);
      expect(newPubspec.executables.length, equals(2));
      final criticalTest = newPubspec.executables.list[0];
      expect(criticalTest.name, equals('critical_test'));
      expect(criticalTest.scriptPath, equals('bin/critical_test.dart'));

      final ct = newPubspec.executables.list[1];
      expect(ct.name, equals('ct'));
      expect(ct.scriptPath, equals('bin/critical_test.dart'));
    });
  });
}
