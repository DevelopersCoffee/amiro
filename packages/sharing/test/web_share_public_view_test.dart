import 'package:sharing/sharing.dart';
import 'package:test/test.dart';

void main() {
  test('filterWebSharePublicContact drops unknown keys', () {
    final filtered = filterWebSharePublicContact({
      'bio': 'Hello',
      'email': 'a@b.co',
      'internal': 'secret',
    });
    expect(filtered.keys, containsAll(['bio', 'email']));
    expect(filtered.containsKey('internal'), isFalse);
  });
}