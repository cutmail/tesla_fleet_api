import '../tesla_fleet_client.dart';
import '../models/partner_models.dart';
import '../models/common_models.dart';
import '../exceptions/tesla_exceptions.dart';

class PartnerEndpoints {
  final TeslaFleetClient _client;

  PartnerEndpoints(this._client);

  Future<PartnerAccount> getPartnerAccount() async {
    final response = await _client.get('/api/1/partner_accounts');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return PartnerAccount.fromJson(apiResponse.response!);
    }
    
    throw TeslaApiException(
      apiResponse.error ?? 'Failed to fetch partner account',
    );
  }

  Future<CommandResponse> registerPartner(String domain) async {
    final response = await _client.post(
      '/api/1/partner_accounts',
      body: {'domain': domain},
    );
    
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaApiException(
      apiResponse.error ?? 'Failed to register partner',
    );
  }

  Future<User> getMe() async {
    final response = await _client.get('/api/1/users/me');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return User.fromJson(apiResponse.response!);
    }
    
    throw TeslaApiException(
      apiResponse.error ?? 'Failed to fetch user info',
    );
  }
}