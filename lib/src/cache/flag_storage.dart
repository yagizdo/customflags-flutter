import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/flag_model.dart';

class FlagStorage {
  static const String _prefix = 'customflags_cache_';

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

  Future<void> write(String identifier, Map<String, Flag> flags) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(
      flags.map((key, flag) => MapEntry(key, flag.toJson())),
    );
    await prefs.setString('$_prefix$identifier', encoded);
  }

  Future<void> clear(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$identifier');
  }
}
