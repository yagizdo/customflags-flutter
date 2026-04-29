import 'package:customflags/customflags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Identity', () {
    test('[Identity] stores the provided identifier', () {
      const identity = Identity(identifier: 'user_42');

      expect(identity.identifier, 'user_42');
    });

    test('[Identity] instances with identical identifier are equal', () {
      const a = Identity(identifier: 'user_42');
      const b = Identity(identifier: 'user_42');

      expect(a, equals(b));
    });

    test('[Identity] instances with different identifier are not equal', () {
      const a = Identity(identifier: 'user_42');
      const b = Identity(identifier: 'user_43');

      expect(a, isNot(equals(b)));
    });

    test('[Identity] hashCode matches when identifier is equal', () {
      const a = Identity(identifier: 'jane@example.com');
      const b = Identity(identifier: 'jane@example.com');

      expect(a.hashCode, b.hashCode);
    });

    test('[Identity] does not validate identifier — empty string is constructible', () {
      // Validation lives in CustomFlagClient.setIdentity (which throws
      // ConfigurationException on empty/whitespace input). Identity itself
      // is a pure value type, so any String must be acceptable here.
      const identity = Identity(identifier: '');

      expect(identity.identifier, '');
    });
  });
}
