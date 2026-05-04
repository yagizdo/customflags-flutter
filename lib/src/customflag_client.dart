import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import 'api_client.dart';
import 'cache/flag_cache.dart';
import 'cache/flag_storage.dart';
import 'core/exceptions.dart';
import 'core/models/flag_model.dart';
import 'core/models/identity.dart';
import 'customflag_config.dart';

/// Entry point for the CustomFlags SDK.
///
/// Construct one instance per app from a [CustomFlagConfig], identify the
/// current user or device with [setIdentity], then call [fetchAllFlags] to
/// retrieve the flags assigned to that identity. Read individual values
/// through the typed getters on [Flag] — [Flag.getBool], [Flag.getString],
/// [Flag.getInt], [Flag.getDouble], or [Flag.getJson].
///
/// ```dart
/// final client = CustomFlagClient(
///   config: CustomFlagConfig(apiKey: 'your_api_key'),
/// );
/// client.setIdentity(Identity(identifier: 'user_42'));
///
/// final flags = await client.fetchAllFlags();
/// final isDark = flags
///     .firstWhere((f) => f.key == 'dark_mode')
///     .getBool();
/// ```
class CustomFlagClient {
  /// The [CustomFlagConfig] this client was constructed with.
  ///
  /// Exposed for inspection — for example, to read
  /// [CustomFlagConfig.connectTimeout] in diagnostics. Note that
  /// [CustomFlagConfig.toString] redacts [CustomFlagConfig.apiKey];
  /// to access the raw key, read the field directly.
  /// Immutable once the client is built; the underlying HTTP client is
  /// configured eagerly in the constructor.
  final CustomFlagConfig config;

  late final ApiClient _api;
  final FlagCache _cache;
  Identity? _identity;

  /// Cancellation handles for every in-flight fetch.
  ///
  /// Tracked so [setIdentity] can cancel every request issued against
  /// the previous identity before swapping in the new one — otherwise
  /// a slow response for user A could land after the app has switched
  /// to user B. The set is needed (rather than a single token) because
  /// the per-widget consumption pattern routinely issues several
  /// concurrent [getFlag] calls for the same identity; with a single
  /// slot, only the most-recent token would survive in the field and
  /// the others would leak past [setIdentity]. Tokens are added on
  /// fetch start and removed on completion (success or failure), so
  /// the set stays bounded by the count of concurrently in-flight
  /// requests. Cancelling an already-completed token is a no-op in Dio.
  final Set<CancelToken> _pendingTokens = {};

  /// Creates a client that talks to the CustomFlags backend using [config].
  ///
  /// Builds the internal HTTP client eagerly. [config] validates itself,
  /// so an invalid one (empty API key, non-positive timeout) throws
  /// [ConfigurationException] from the [CustomFlagConfig] constructor
  /// before this constructor returns.
  CustomFlagClient({
    required this.config,
    @visibleForTesting ApiClient? apiClient,
    @visibleForTesting FlagCache? cache,
  }) : _cache = cache ?? FlagCache(storage: FlagStorage()) {
    _api = apiClient ?? ApiClient(config: config);
  }

  /// Broadcast stream that emits the full flag map after every
  /// [init] (when disk data exists or the network fetch succeeds),
  /// [refresh], or [clearCache] call that updates the cache.
  ///
  /// Note: [setIdentity] clears the in-memory cache but does **not**
  /// emit on this stream — listeners keep the previous emission until
  /// the next [init], [refresh], or [clearCache] lands. Trigger an
  /// explicit [refresh] after switching identity if the UI must rebuild
  /// immediately.
  ///
  /// Use with `StreamBuilder` to rebuild widgets when flags change:
  ///
  /// ```dart
  /// StreamBuilder<Map<String, Flag>>(
  ///   stream: client.flagStream,
  ///   builder: (context, _) {
  ///     final flag = client.getFlag('dark_mode');
  ///     return Text(flag.getBool(fallback: false).toString());
  ///   },
  /// );
  /// ```
  Stream<Map<String, Flag>> get flagStream => _cache.stream;

  /// Sets the [Identity] used for subsequent flag fetches.
  ///
  /// Must be called before [fetchAllFlags]; otherwise that call throws
  /// [ConfigurationException]. Calling this again replaces the previous
  /// identity — the next [fetchAllFlags] uses the new
  /// [identifier][Identity.identifier].
  ///
  /// Throws [ConfigurationException] if [Identity.identifier] is empty —
  /// an empty identifier would be silently dropped from the request URL
  /// and result in an unscoped fetch.
  ///
  /// ```dart
  /// client.setIdentity(Identity(identifier: 'user_42'));
  /// // ...later, after the user logs out and a new user logs in:
  /// client.setIdentity(Identity(identifier: 'user_99'));
  /// ```
  void setIdentity(Identity identity) {
    if (identity.identifier.isEmpty) {
      throw ConfigurationException(
        message: 'Identity.identifier must not be empty',
      );
    }
    _identity = identity;
    for (final token in _pendingTokens) {
      token.cancel('identity changed');
    }
    _pendingTokens.clear();
    _cache.clear();
  }

  /// Initialises the cache: loads flags from disk, then attempts a
  /// network fetch to overlay fresh data.
  ///
  /// Must be called after [setIdentity]. If the network call fails,
  /// the disk cache (if any) remains active — the app starts with
  /// stale-but-usable data rather than crashing. The exception is
  /// still thrown so the caller knows the network fetch failed.
  ///
  /// Throws [ConfigurationException] if [setIdentity] has not been
  /// called yet.
  Future<void> init() async {
    final identity = _checkIdentity();
    await _cache.load(identity.identifier);
    final flags = await _fetchFromNetwork(identity);
    await _cache.update(identity.identifier, flags);
  }

  /// Fetches the latest flags from the network and updates the cache.
  ///
  /// On success the in-memory cache, disk cache, and [flagStream] are
  /// all updated. On failure the existing cache is preserved and the
  /// exception is rethrown so the caller can react (e.g. show a
  /// connectivity warning).
  ///
  /// Throws [ConfigurationException] if [setIdentity] has not been
  /// called yet.
  Future<void> refresh() async {
    final identity = _checkIdentity();
    final flags = await _fetchFromNetwork(identity);
    await _cache.update(identity.identifier, flags);
  }

  /// Returns the cached [Flag] for [key] synchronously.
  ///
  /// Returns `Flag(key: key, value: null)` when the key is not in
  /// the cache (e.g. before [init], or after [setIdentity] clears it).
  /// Combine with the typed getters and a fallback for safe reads:
  ///
  /// ```dart
  /// final isDark = client.getFlag('dark_mode').getBool(fallback: false);
  /// ```
  Flag getFlag(String key) => _cache.getFlag(key);

  /// Returns an unmodifiable map of every cached flag.
  ///
  /// Empty before [init] has been called.
  Map<String, Flag> getAllFlags() => _cache.getAllFlags();

  /// Fetches every flag assigned to the current [Identity] from the
  /// CustomFlags backend.
  ///
  /// Read values from the returned list with the typed getters on [Flag]:
  ///
  /// ```dart
  /// final flags = await client.fetchAllFlags();
  /// final flag = flags.firstWhere((f) => f.key == 'dark_mode');
  /// final isDark = flag.getBool();
  /// ```
  ///
  /// Throws [ConfigurationException] if [setIdentity] has not been called
  /// yet. Throws [CustomFlagApiException] on network failures (no
  /// connection, timeout) or HTTP errors (4xx, 5xx). Throws
  /// [MalformedResponseException] when the backend response shape is
  /// invalid (missing `flags` key, `flags` is not a JSON object, etc.).
  Future<List<Flag>> fetchAllFlags() async {
    final identity = _checkIdentity();
    final token = CancelToken();
    _pendingTokens.add(token);
    try {
      return await _api.fetchAllFlags(identity: identity, cancelToken: token);
    } finally {
      _pendingTokens.remove(token);
    }
  }

  Future<List<Flag>> _fetchFromNetwork(Identity identity) async {
    final token = CancelToken();
    _pendingTokens.add(token);
    try {
      return await _api.fetchAllFlags(identity: identity, cancelToken: token);
    } finally {
      _pendingTokens.remove(token);
    }
  }

  Identity _checkIdentity() {
    final identity = _identity;
    if (identity == null) {
      throw ConfigurationException(
        message: 'setIdentity must be called before fetching flags',
      );
    }
    return identity;
  }

  /// Clears both the in-memory and disk flag cache for the current
  /// identity, then emits an empty snapshot on [flagStream] so every
  /// listener (e.g. a `StreamBuilder` on [flagStream]) rebuilds with
  /// fallback values.
  ///
  /// Typical use cases:
  ///
  /// * **Logout** — wipe cached flags so the next user starts fresh.
  /// * **Testing** — reset to a clean slate between test runs.
  /// * **Debugging** — force the app to re-fetch from the backend on
  ///   the next [init] or [refresh] call.
  ///
  /// ```dart
  /// // On logout, clear cached data before dropping the client:
  /// await client.clearCache();
  /// client.dispose();
  /// ```
  ///
  /// Throws [ConfigurationException] if [setIdentity] has not been
  /// called yet — without an identity there is no disk key to clear.
  Future<void> clearCache() async {
    final identity = _checkIdentity();
    for (final token in _pendingTokens) {
      token.cancel('cache cleared');
    }
    _pendingTokens.clear();
    await _cache.clearAll(identity.identifier);
  }

  /// Releases resources held by the client.
  ///
  /// Closes the underlying [flagStream]. After this call the client
  /// must not be used.
  void dispose() {
    _api.close();
    _cache.dispose();
  }
}
