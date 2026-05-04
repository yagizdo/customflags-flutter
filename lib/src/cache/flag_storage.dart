import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/flag_model.dart';

/// Disk-backed flag storage using [SharedPreferences].
///
/// Each identity gets its own storage key (`customflags_cache_<identifier>`).
/// Flags are JSON-encoded via [Flag.toJson] / [Flag.fromJson].
class FlagStorage {
  static const String _prefix = 'customflags_cache_';

  /// Reads the stored flags for [identifier] from disk.
  ///
  /// Returns an empty map when no entry exists for [identifier].
  Future<Map<String, Flag>> read(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$identifier');
    if (raw == null) return {};

    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        Flag.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  /// Persists [flags] to disk under the key for [identifier].
  ///
  /// Overwrites any previously stored entry for the same identity.
  Future<void> write(String identifier, Map<String, Flag> flags) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(
      flags.map((key, flag) => MapEntry(key, flag.toJson())),
    );
    await prefs.setString('$_prefix$identifier', encoded);
  }

  /// Removes the stored flags for [identifier] from disk.
  ///
  /// No-op when no entry exists. Does not affect other identities.
  Future<void> clear(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$identifier');
  }
}
