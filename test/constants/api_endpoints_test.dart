import 'package:customflags/src/constants/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kCustomFlagSingleFlagEndpoint', () {
    test('[kCustomFlagSingleFlagEndpoint] preserves plain ASCII feature keys unchanged', () {
      expect(kCustomFlagSingleFlagEndpoint('flag_42'), '/api/v1/flags/flag_42');
      expect(kCustomFlagSingleFlagEndpoint('darkMode'), '/api/v1/flags/darkMode');
    });

    test('[kCustomFlagSingleFlagEndpoint] encodes path-segment "/" to %2F', () {
      expect(kCustomFlagSingleFlagEndpoint('a/b'), '/api/v1/flags/a%2Fb');
    });

    test('[kCustomFlagSingleFlagEndpoint] encodes query "?" to %3F', () {
      expect(kCustomFlagSingleFlagEndpoint('a?b'), '/api/v1/flags/a%3Fb');
    });

    test('[kCustomFlagSingleFlagEndpoint] encodes fragment "#" to %23', () {
      expect(kCustomFlagSingleFlagEndpoint('a#b'), '/api/v1/flags/a%23b');
    });

    test('[kCustomFlagSingleFlagEndpoint] encodes spaces to %20', () {
      expect(kCustomFlagSingleFlagEndpoint('a b'), '/api/v1/flags/a%20b');
    });

    test('[kCustomFlagSingleFlagEndpoint] encodes unicode characters to percent-escaped UTF-8', () {
      // 'é' is U+00E9, UTF-8: 0xC3 0xA9 → %C3%A9
      expect(kCustomFlagSingleFlagEndpoint('café'), '/api/v1/flags/caf%C3%A9');
    });
  });
}
