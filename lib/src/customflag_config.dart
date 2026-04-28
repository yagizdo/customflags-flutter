import 'package:equatable/equatable.dart';

import 'core/exceptions.dart';

/// Configuration for the CustomFlags SDK.
///
/// Holds the credentials and network timeouts the SDK uses when
/// talking to the CustomFlags backend. Create one instance at app
/// startup and pass it to the SDK initializer:
///
/// ```dart
/// final config = CustomFlagConfig(
///   apiKey: 'your_api_key',
/// );
/// ```
///
/// Throws [ConfigurationException] on invalid input — an empty
/// [apiKey], or a zero/negative [connectTimeout] or [receiveTimeout].
final class CustomFlagConfig extends Equatable {
  static const defaultConnectTimeout = Duration(seconds: 10);
  static const defaultReceiveTimeout = Duration(seconds: 20);
  static const defaultSendTimeout = Duration(seconds: 20);

  /// Credential identifying your project with the CustomFlags backend.
  /// Get your API key from the CustomFlags dashboard; must not be empty or a
  /// [ConfigurationException] is thrown at construction.
  final String apiKey;

  /// Maximum time to wait while opening a connection to the backend.
  ///
  /// Defaults to [defaultConnectTimeout]. Must be greater than
  /// [Duration.zero].
  final Duration connectTimeout;

  /// Maximum time to wait for a response after the connection is
  /// established.
  ///
  /// Defaults to [defaultReceiveTimeout]. Must be greater than
  /// [Duration.zero].
  final Duration receiveTimeout;

  /// Timeout for sending requests.
  ///
  /// Defaults to [defaultSendTimeout]. Must be greater than [Duration.zero].
  /// Ignored on web platforms.
  final Duration sendTimeout;

  CustomFlagConfig({
    required this.apiKey,
    this.connectTimeout = defaultConnectTimeout,
    this.receiveTimeout = defaultReceiveTimeout,
    this.sendTimeout = defaultSendTimeout,
  }) {
    if (apiKey.isEmpty) {
      throw ConfigurationException(
        message: 'API Key must not be empty. Please get your API key from https://customflags.app',
      );
    }
    if (connectTimeout <= Duration.zero) {
      throw ConfigurationException(
        message: 'Connect timeout must be greater than 0, got: $connectTimeout',
      );
    }

    if (receiveTimeout <= Duration.zero) {
      throw ConfigurationException(
        message: 'Receive timeout must be greater than 0, got: $receiveTimeout',
      );
    }

    if (sendTimeout <= Duration.zero) {
      throw ConfigurationException(
        message: 'Send timeout must be greater than 0, got: $sendTimeout',
      );
    }
  }

  @override
  String toString() =>
      'CustomFlagConfig(apiKey: ${apiKey.isEmpty ? "<empty>" : "<redacted>"}, '
      'connectTimeout: $connectTimeout, '
      'receiveTimeout: $receiveTimeout, '
      'sendTimeout: $sendTimeout)';

  @override
  List<Object?> get props => [apiKey, connectTimeout, receiveTimeout, sendTimeout];
}
