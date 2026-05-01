import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import 'api_client.dart';
import 'cache/flag_cache.dart';
import 'cache/flag_storage.dart';
import 'core/exceptions.dart';
import 'core/models/flag_model.dart';
import 'core/models/identity.dart';
import 'customflag_config.dart';

class CustomFlagClient {
  final CustomFlagConfig config;

  late final ApiClient _api;
  final FlagCache _cache;
  Identity? _identity;

  final Set<CancelToken> _pendingTokens = {};

  CustomFlagClient({
    required this.config,
    @visibleForTesting ApiClient? apiClient,
    @visibleForTesting FlagCache? cache,
  }) : _cache = cache ?? FlagCache(storage: FlagStorage()) {
    _api = apiClient ?? ApiClient(config: config);
  }

  Stream<Map<String, Flag>> get flagStream => _cache.stream;

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

  Future<void> init() async {
    final identity = _checkIdentity();
    await _cache.load(identity.identifier);
    try {
      final flags = await _fetchFromNetwork(identity);
      await _cache.update(identity.identifier, flags);
    } on Exception {
      // Network failure is not fatal during init — disk cache is already loaded.
    }
  }

  Future<void> refresh() async {
    final identity = _checkIdentity();
    try {
      final flags = await _fetchFromNetwork(identity);
      await _cache.update(identity.identifier, flags);
    } on Exception {
      // Keep current cache on failure.
    }
  }

  Flag getFlag(String key) => _cache.getFlag(key);

  Map<String, Flag> getAllFlags() => _cache.getAllFlags();

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

  void dispose() {
    _cache.dispose();
  }
}
