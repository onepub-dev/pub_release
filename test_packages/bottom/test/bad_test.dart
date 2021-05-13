import 'package:test/test.dart';

void main() {
  test('bad test', () {
    fail('this test failed intentionally');
  }, tags: ['bad']);
}
