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
  /// [CustomFlagConfig.apiKey] or [CustomFlagConfig.connectTimeout] in
  /// logs or diagnostics. Immutable once the client is built; the
  /// underlying HTTP client is configured eagerly in the constructor.
  final CustomFlagConfig config;

  late final ApiClient _api;
  Identity? _identity;

  /// Creates a client that talks to the CustomFlags backend using [config].
  ///
  /// Builds the internal HTTP client eagerly. [config] validates itself,
  /// so an invalid one (empty API key, non-positive timeout) throws
  /// [ConfigurationException] from the [CustomFlagConfig] constructor
  /// before this constructor returns.
  CustomFlagClient({required this.config}) {
    _api = ApiClient(config: config);
  }

  /// Sets the [Identity] used for subsequent flag fetches.
  ///
  /// Must be called before [fetchAllFlags]; otherwise that call throws
  /// [ConfigurationException]. Calling this again replaces the previous
  /// identity — the next [fetchAllFlags] uses the new [identifier][Identity.identifier].
  ///
  /// ```dart
  /// client.setIdentity(Identity(identifier: 'user_42'));
  /// // ...later, after the user logs out and a new user logs in:
  /// client.setIdentity(Identity(identifier: 'user_99'));
  /// ```
  void setIdentity(Identity identity) {
    _identity = identity;
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
  /// connection, timeout), HTTP errors (4xx, 5xx), or malformed
  /// responses where the backend did not return a JSON object.
  Future<List<Flag>> fetchAllFlags() async {
    final identity = _checkIdentity();
    return await _api.fetchAllFlags(identity: identity);
  }

  /// Fetches the single [Flag] identified by [featureKey] for the current
  /// [Identity] from the CustomFlags backend.
  ///
  /// Read the value from the returned flag with the typed getter that
  /// matches its stored type — [Flag.getBool], [Flag.getString],
  /// [Flag.getInt], [Flag.getDouble], or [Flag.getJson]:
  ///
  /// ```dart
  /// final flag = await client.getFlag('dark_mode');
  /// final isDark = flag.getBool();
  /// ```
  ///
  /// Throws [ArgumentError] if [featureKey] is empty. Throws
  /// [ConfigurationException] if [setIdentity] has not been called yet.
  /// Throws [CustomFlagApiException] on network failures (no connection,
  /// timeout), HTTP errors (4xx, 5xx), or malformed responses where the
  /// backend did not return a JSON object.
  Future<Flag> getFlag(String featureKey) async {
    final identity = _checkIdentity();
    if (featureKey.isEmpty) {
      throw ArgumentError.value(featureKey, 'featureKey', 'must not be empty');
    }
    return await _api.fetchFlag(identity: identity, featureKey: featureKey);
  }

  Identity _checkIdentity() {
    final identity = _identity;
    if (identity == null) throw ConfigurationException(message: 'setIdentity must be called before fetching flags');
    return identity;
  }
}
