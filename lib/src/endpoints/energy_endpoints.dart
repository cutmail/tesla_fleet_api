import '../tesla_fleet_client.dart';
import '../models/energy_models.dart';
import '../models/common_models.dart';
import '../exceptions/tesla_exceptions.dart';

class EnergyEndpoints {
  final TeslaFleetClient _client;

  EnergyEndpoints(this._client);

  Future<List<EnergyProduct>> list() async {
    final response = await _client.get('/api/1/products');
    final apiResponse = ApiResponse<List<dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return apiResponse.response!
          .where((product) => product['resource_type'] != 'vehicle')
          .map((product) => EnergyProduct.fromJson(product))
          .toList();
    }
    
    // Return empty list if no energy products are registered
    return [];
  }

  Future<EnergyLiveStatus> getLiveStatus(int energySiteId) async {
    final response = await _client.get('/api/1/energy_sites/$energySiteId/live_status');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return EnergyLiveStatus.fromJson(apiResponse.response!);
    }
    
    throw TeslaApiException(
      apiResponse.error ?? 'Failed to fetch energy live status',
    );
  }

  Future<EnergyHistory> getHistory(
    int energySiteId, {
    String period = 'day',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{
      'kind': 'energy',
      'period': period,
    };
    
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
    }
    
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
    }
    
    final response = await _client.get(
      '/api/1/energy_sites/$energySiteId/history',
      queryParams: queryParams,
    );
    
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return EnergyHistory.fromJson(apiResponse.response!);
    }
    
    throw TeslaApiException(
      apiResponse.error ?? 'Failed to fetch energy history',
    );
  }

  Future<CommandResponse> setBackupReservePercent(int energySiteId, int percent) async {
    final response = await _client.post(
      '/api/1/energy_sites/$energySiteId/backup',
      body: {'backup_reserve_percent': percent},
    );
    
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaApiException(
      apiResponse.error ?? 'Failed to set backup reserve percent',
    );
  }

  Future<CommandResponse> setOperationMode(int energySiteId, String mode) async {
    final response = await _client.post(
      '/api/1/energy_sites/$energySiteId/operation',
      body: {'default_real_mode': mode},
    );
    
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaApiException(
      apiResponse.error ?? 'Failed to set operation mode',
    );
  }

  Future<CommandResponse> enableStormMode(int energySiteId, bool enabled) async {
    final response = await _client.post(
      '/api/1/energy_sites/$energySiteId/storm_mode',
      body: {'enabled': enabled},
    );
    
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaApiException(
      apiResponse.error ?? 'Failed to ${enabled ? 'enable' : 'disable'} storm mode',
    );
  }
}