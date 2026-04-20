import 'package:customflags/customflags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Flag', () {
    test('[Flag] stores key and value when constructed', () {
      const flag = Flag(key: 'dark_mode', value: true);

      expect(flag.key, 'dark_mode');
      expect(flag.value, true);
    });

    test('[Flag] instances with identical key and value are equal', () {
      const a = Flag(key: 'dark_mode', value: true);
      const b = Flag(key: 'dark_mode', value: true);

      expect(a, equals(b));
    });

    test('[Flag] instances with different keys are not equal', () {
      const a = Flag(key: 'dark_mode', value: true);
      const b = Flag(key: 'notifications', value: true);

      expect(a, isNot(equals(b)));
    });

    test('[Flag] instances with different values are not equal', () {
      const a = Flag(key: 'dark_mode', value: true);
      const b = Flag(key: 'dark_mode', value: false);

      expect(a, isNot(equals(b)));
    });

    test('[Flag] instances with structurally equal Map values are equal (deep equality)', () {
      // Map.from forces distinct runtime instances so const canonicalization
      // can't make this test pass via identity. Equatable's deep equality on
      // Map props is what must hold.
      final mapA = Map<String, dynamic>.from({'color': 'blue', 'size': 10});
      final mapB = Map<String, dynamic>.from({'color': 'blue', 'size': 10});
      expect(identical(mapA, mapB), isFalse);

      final flagA = Flag(key: 'ui_config', value: mapA);
      final flagB = Flag(key: 'ui_config', value: mapB);

      expect(flagA, equals(flagB));
    });

    test('[Flag] instances with differing Map contents are not equal', () {
      final flagA = Flag(
        key: 'ui_config',
        value: Map<String, dynamic>.from({'color': 'blue'}),
      );
      final flagB = Flag(
        key: 'ui_config',
        value: Map<String, dynamic>.from({'color': 'red'}),
      );

      expect(flagA, isNot(equals(flagB)));
    });
  });

  group('Flag.getBool', () {
    test('[Flag.getBool] returns true when value is true', () {
      const flag = Flag(key: 'dark_mode', value: true);
      expect(flag.getBool(), true);
    });

    test('[Flag.getBool] returns false when value is false', () {
      const flag = Flag(key: 'dark_mode', value: false);
      expect(flag.getBool(), false);
    });

    test('[Flag.getBool] throws TypeMismatchException when value is a String', () {
      const flag = Flag(key: 'dark_mode', value: 'true');
      expect(flag.getBool, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getBool] throws TypeMismatchException when value is an int', () {
      const flag = Flag(key: 'dark_mode', value: 1);
      expect(flag.getBool, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getBool] exception reports flag key, expected and actual types', () {
      const flag = Flag(key: 'dark_mode', value: 'yes');

      expect(
        flag.getBool,
        throwsA(
          isA<TypeMismatchException>()
              .having((e) => e.flagKey, 'flagKey', 'dark_mode')
              .having((e) => e.expectedType, 'expectedType', bool)
              .having((e) => e.actualType, 'actualType', String),
        ),
      );
    });

    test('[Flag.getBool] throws NullFlagValueException when value is null', () {
      const flag = Flag(key: 'dark_mode', value: null);
      expect(flag.getBool, throwsA(isA<NullFlagValueException>()));
    });

    test('[Flag.getBool] null exception reports flag key', () {
      const flag = Flag(key: 'dark_mode', value: null);
      expect(
        flag.getBool,
        throwsA(
          isA<NullFlagValueException>()
              .having((e) => e.flagKey, 'flagKey', 'dark_mode'),
        ),
      );
    });
  });

  group('Flag.getString', () {
    test('[Flag.getString] returns value when value is a String', () {
      const flag = Flag(key: 'theme_color', value: 'blue');
      expect(flag.getString(), 'blue');
    });

    test('[Flag.getString] throws TypeMismatchException when value is a bool', () {
      const flag = Flag(key: 'theme_color', value: true);
      expect(flag.getString, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getString] throws TypeMismatchException when value is an int', () {
      const flag = Flag(key: 'theme_color', value: 42);
      expect(flag.getString, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getString] throws NullFlagValueException when value is null', () {
      const flag = Flag(key: 'theme_color', value: null);
      expect(flag.getString, throwsA(isA<NullFlagValueException>()));
    });
  });

  group('Flag.getInt', () {
    test('[Flag.getInt] returns value when value is an int', () {
      const flag = Flag(key: 'max_retries', value: 3);
      expect(flag.getInt(), 3);
    });

    test('[Flag.getInt] throws TypeMismatchException when value is a double (no silent truncation)', () {
      const flag = Flag(key: 'max_retries', value: 3.7);
      expect(flag.getInt, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getInt] throws TypeMismatchException when value is a String', () {
      const flag = Flag(key: 'max_retries', value: '3');
      expect(flag.getInt, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getInt] throws NullFlagValueException when value is null', () {
      const flag = Flag(key: 'max_retries', value: null);
      expect(flag.getInt, throwsA(isA<NullFlagValueException>()));
    });
  });

  group('Flag.getDouble', () {
    test('[Flag.getDouble] returns value when value is a double', () {
      const flag = Flag(key: 'font_scale', value: 1.25);
      expect(flag.getDouble(), 1.25);
    });

    test('[Flag.getDouble] widens int to double when value is an int', () {
      // JSON deserializes whole numbers as int — num check + .toDouble()
      // covers both numeric types without forcing callers to know the
      // wire-level representation.
      const flag = Flag(key: 'font_scale', value: 1);
      expect(flag.getDouble(), 1.0);
    });

    test('[Flag.getDouble] throws TypeMismatchException when value is a String', () {
      const flag = Flag(key: 'font_scale', value: '1.25');
      expect(flag.getDouble, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getDouble] throws TypeMismatchException when value is a bool', () {
      const flag = Flag(key: 'font_scale', value: true);
      expect(flag.getDouble, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getDouble] throws TypeMismatchException when value is NaN', () {
      // NaN is num, so a naive `is num` check would let it through. Rejecting
      // it here prevents silent propagation — e.g. NaN > 1.0 evaluates false
      // and surfaces far from the source as a render/layout bug.
      const flag = Flag(key: 'font_scale', value: double.nan);
      expect(flag.getDouble, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getDouble] throws TypeMismatchException when value is positive infinity', () {
      const flag = Flag(key: 'font_scale', value: double.infinity);
      expect(flag.getDouble, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getDouble] throws TypeMismatchException when value is negative infinity', () {
      const flag = Flag(key: 'font_scale', value: double.negativeInfinity);
      expect(flag.getDouble, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getDouble] throws NullFlagValueException when value is null', () {
      const flag = Flag(key: 'font_scale', value: null);
      expect(flag.getDouble, throwsA(isA<NullFlagValueException>()));
    });
  });

  group('Flag.getJson', () {
    test('[Flag.getJson] returns value when value is a Map<String, dynamic>', () {
      const flag = Flag(
        key: 'ui_config',
        value: <String, dynamic>{'color': 'blue', 'size': 10},
      );

      expect(flag.getJson(), <String, dynamic>{'color': 'blue', 'size': 10});
    });

    test('[Flag.getJson] throws TypeMismatchException when value is a String', () {
      const flag = Flag(key: 'ui_config', value: '{}');
      expect(flag.getJson, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getJson] throws TypeMismatchException when value is a List', () {
      const flag = Flag(key: 'ui_config', value: [1, 2, 3]);
      expect(flag.getJson, throwsA(isA<TypeMismatchException>()));
    });

    test('[Flag.getJson] throws NullFlagValueException when value is null', () {
      const flag = Flag(key: 'ui_config', value: null);
      expect(flag.getJson, throwsA(isA<NullFlagValueException>()));
    });
  });
}
