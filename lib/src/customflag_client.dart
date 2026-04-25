import 'api_client.dart';
import 'core/exceptions.dart';
import 'core/models/flag_model.dart';
import 'core/models/identity.dart';
import 'customflag_config.dart';

class CustomFlagClient {
  final CustomFlagConfig config;

  late final ApiClient _api;
  Identity? _identity;

  CustomFlagClient({required this.config}) {
    _api = ApiClient(config: config);
  }

  void setIdentity(Identity identity) {
    _identity = identity;
  }

  Future<List<Flag>> fetchAllFlags() async {
    final identity = _identity;
    if (identity == null) throw ConfigurationException(message: 'setIdentity must be called before fetching flags');
    return await _api.fetchAllFlags(identity: identity);
  }
}
