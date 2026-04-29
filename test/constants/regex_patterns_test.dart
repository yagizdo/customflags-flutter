import 'package:customflags/src/constants/regex_patterns.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kLogInjectionControlCharsPattern', () {
    test('[kLogInjectionControlCharsPattern] matches carriage return (\\r)', () {
      expect(kLogInjectionControlCharsPattern.hasMatch('a\rb'), isTrue);
    });

    test('[kLogInjectionControlCharsPattern] matches line feed (\\n)', () {
      expect(kLogInjectionControlCharsPattern.hasMatch('a\nb'), isTrue);
    });

    test('[kLogInjectionControlCharsPattern] matches NUL (\\x00) at the start of the range', () {
      expect(kLogInjectionControlCharsPattern.hasMatch('a\x00b'), isTrue);
    });

    test('[kLogInjectionControlCharsPattern] matches \\x1f at the end of the range', () {
      expect(kLogInjectionControlCharsPattern.hasMatch('a\x1fb'), isTrue);
    });

    test('[kLogInjectionControlCharsPattern] matches escape (\\x1b), used in ANSI sequences', () {
      // CWE-117 attackers embed ANSI escape sequences to repaint terminals;
      // \x1b sits in the middle of the control range, so this is a
      // realistic attack-vector regression check.
      expect(kLogInjectionControlCharsPattern.hasMatch('a\x1bb'), isTrue);
    });

    test('[kLogInjectionControlCharsPattern] does not match space (\\x20) just past the range', () {
      // \x20 is the first printable ASCII character. The regex uses the
      // half-open range \x00–\x1f, so space must NOT match — otherwise
      // every body containing a space would be sanitized.
      expect(kLogInjectionControlCharsPattern.hasMatch('a b'), isFalse);
    });

    test('[kLogInjectionControlCharsPattern] does not match plain ASCII letters or digits', () {
      expect(kLogInjectionControlCharsPattern.hasMatch('Hello123'), isFalse);
    });

    test('[kLogInjectionControlCharsPattern] does not match unicode characters above the control range', () {
      // 'é' is U+00E9, well outside \x00–\x1f. The sanitizer must leave
      // non-ASCII content alone so legitimate body text stays readable.
      expect(kLogInjectionControlCharsPattern.hasMatch('café'), isFalse);
    });

    test('[kLogInjectionControlCharsPattern] replaceAll strips every control char from a mixed string', () {
      // Mirrors the actual usage in CustomFlagApiException: every match is
      // replaced with a space so log lines stay single-line and readable.
      final sanitized = 'line1\nline2\rline3\x00end'
          .replaceAll(kLogInjectionControlCharsPattern, ' ');

      expect(sanitized, 'line1 line2 line3 end');
    });
  });
}
