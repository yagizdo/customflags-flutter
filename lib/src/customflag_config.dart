import 'package:equatable/equatable.dart';

import 'core/exceptions.dart';

final class CustomFlagConfig extends Equatable {
  static const defaultConnectTimeout = Duration(seconds: 10);
  static const defaultReceiveTimeout = Duration(seconds: 20);

  final String apiKey;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  CustomFlagConfig({
    required this.apiKey,
    this.connectTimeout = defaultConnectTimeout,
    this.receiveTimeout = defaultReceiveTimeout,
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
  }

  @override
  List<Object?> get props => [apiKey, connectTimeout, receiveTimeout];
}
