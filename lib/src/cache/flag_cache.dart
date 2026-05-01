import 'dart:async';

import '../core/models/flag_model.dart';
import 'flag_storage.dart';

/// In-memory flag cache backed by disk storage and a broadcast stream.
///
/// Holds the latest flag map in memory for synchronous reads via
/// [getFlag] and [getAllFlags]. Mutations ([load], [update], [clear])
/// update the in-memory map and notify listeners through [stream].
/// Disk persistence is delegated to [FlagStorage].
class FlagCache {
  final FlagStorage _storage;
  Map<String, Flag> _flags = {};
  final StreamController<Map<String, Flag>> _controller =
      StreamController<Map<String, Flag>>.broadcast();

  /// Creates a cache that delegates disk I/O to [storage].
  FlagCache({required FlagStorage storage}) : _storage = storage;

  /// Broadcast stream that emits an unmodifiable snapshot of the flag
  /// map after every [load] (when disk data exists) and [update].
  ///
  /// Multiple listeners are supported — each receives the same
  /// emission. Events emitted before any listener subscribes are
  /// silently dropped (standard broadcast-stream behaviour).
  Stream<Map<String, Flag>> get stream => _controller.stream;

  /// Returns the cached [Flag] for [key], or a sentinel
  /// `Flag(key: key, value: null)` when the key is not in the cache.
  ///
  /// This is a synchronous read from the in-memory map — it never
  /// touches disk or network.
  Flag getFlag(String key) =>
      _flags[key] ?? Flag(key: key, value: null);

  /// Returns an unmodifiable view of every cached flag.
  ///
  /// Empty before [load] or [update] has been called.
  Map<String, Flag> getAllFlags() => Map.unmodifiable(_flags);

  /// Populates the in-memory cache from disk for [identifier].
  ///
  /// Emits on [stream] when the disk contained data; does nothing
  /// (and does not emit) when there is no stored entry.
  Future<void> load(String identifier) async {
    final stored = await _storage.read(identifier);
    _flags = Map.of(stored);
    if (_flags.isNotEmpty) {
      _controller.add(Map.unmodifiable(_flags));
    }
  }

  /// Replaces the in-memory cache with [flags], persists them to disk
  /// under [identifier], and emits the new snapshot on [stream].
  Future<void> update(String identifier, List<Flag> flags) async {
    _flags = {for (final f in flags) f.key: f};
    await _storage.write(identifier, _flags);
    _controller.add(Map.unmodifiable(_flags));
  }

  /// Erases the in-memory cache and the disk entry for [identifier],
  /// then emits an empty snapshot on [stream] so listeners rebuild
  /// with fallback values.
  Future<void> clearAll(String identifier) async {
    _flags = {};
    await _storage.clear(identifier);
    _controller.add(Map.unmodifiable(_flags));
  }

  /// Resets the in-memory cache to empty.
  ///
  /// Does **not** touch disk. Used internally by identity-switch
  /// logic where the old identity's disk entry is still valid
  /// (each identity has its own storage key).
  void clear() {
    _flags = {};
  }

  /// Closes the [stream]. After this call, no further events are
  /// emitted and new listeners receive a done event immediately.
  void dispose() {
    _controller.close();
  }
}
