import 'dart:async';

import '../core/models/flag_model.dart';
import 'flag_storage.dart';

class FlagCache {
  final FlagStorage _storage;
  Map<String, Flag> _flags = {};
  final StreamController<Map<String, Flag>> _controller =
      StreamController<Map<String, Flag>>.broadcast();

  FlagCache({required FlagStorage storage}) : _storage = storage;

  Stream<Map<String, Flag>> get stream => _controller.stream;

  Flag getFlag(String key) =>
      _flags[key] ?? Flag(key: key, value: null);

  Map<String, Flag> getAllFlags() => Map.unmodifiable(_flags);

  Future<void> load(String identifier) async {
    final stored = await _storage.read(identifier);
    _flags = Map.of(stored);
    if (_flags.isNotEmpty) {
      _controller.add(Map.unmodifiable(_flags));
    }
  }

  Future<void> update(String identifier, List<Flag> flags) async {
    _flags = {for (final f in flags) f.key: f};
    await _storage.write(identifier, _flags);
    _controller.add(Map.unmodifiable(_flags));
  }

  void clear() {
    _flags = {};
  }

  void dispose() {
    _controller.close();
  }
}
