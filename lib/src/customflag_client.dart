import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import 'api_client.dart';
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
  Identity? _identity;

  /// Cancellation handle for the most-recent fetch.
  ///
  /// Tracked so [setIdentity] can cancel an in-flight request against
  /// the previous identity before swapping in the new one — otherwise
  /// a slow response for user A could land after the app has switched
  /// to user B. Cancelling an already-completed token is a no-op in
  /// Dio, so this field is not cleared when a fetch finishes.
  CancelToken? _pendingRequestToken;

  /// Creates a client that talks to the CustomFlags backend using [config].
  ///
  /// Builds the internal HTTP client eagerly. [config] validates itself,
  /// so an invalid one (empty API key, non-positive timeout) throws
  /// [ConfigurationException] from the [CustomFlagConfig] constructor
  /// before this constructor returns.
  CustomFlagClient({
    required this.config,
    @visibleForTesting ApiClient? apiClient,
  }) {
    _api = apiClient ?? ApiClient(config: config);
  }

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
    _pendingRequestToken?.cancel('identity changed');
    _pendingRequestToken = null;
  }

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
    _pendingRequestToken = token;
    return _api.fetchAllFlags(identity: identity, cancelToken: token);
  }

  /// Fetches the [Flag] identified by [featureKey] for the current
  /// [Identity] from the CustomFlags backend.
  ///
  /// When the backend response omits [featureKey] (the wire convention is
  /// "absent = off" — only `true` or set values are returned), this method
  /// returns a synthetic `Flag(key: featureKey, value: null)` rather than
  /// throwing. Combined with the optional `fallback` parameter on each
  /// typed getter on [Flag], this lets callers read flag values in a
  /// single chained call:
  ///
  /// ```dart
  /// final isDark = (await client.getFlag('dark_mode')).getBool(fallback: false);
  /// ```
  ///
  /// The strict no-fallback variant is still available — calling
  /// [Flag.getBool] (or any other typed getter) without a `fallback`
  /// argument throws [TypeMismatchException] on null or wrong-type values,
  /// preserving misconfiguration signals.
  ///
  /// Throws [ArgumentError] if [featureKey] is empty. Throws
  /// [ConfigurationException] if [setIdentity] has not been called yet.
  /// Throws [CustomFlagApiException] on network failures (no connection,
  /// timeout) or HTTP errors (4xx, 5xx). Throws
  /// [MalformedResponseException] when the backend response shape is
  /// invalid (missing `flags` key, `flags` is not a JSON object, or — for
  /// a single-flag query — the response contains more than one flag).
  Future<Flag> getFlag(String featureKey) async {
    final identity = _checkIdentity();
    if (featureKey.isEmpty) {
      throw ArgumentError.value(featureKey, 'featureKey', 'must not be empty');
    }
    final token = CancelToken();
    _pendingRequestToken = token;
    return _api.fetchFlag(
      identity: identity,
      featureKey: featureKey,
      cancelToken: token,
    );
  }

  Identity _checkIdentity() {
    final identity = _identity;
    if (identity == null) throw ConfigurationException(message: 'setIdentity must be called before fetching flags');
    return identity;
  }
}
