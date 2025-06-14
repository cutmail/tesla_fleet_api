import '../tesla_fleet_client.dart';
import '../models/charging_models.dart';
import '../models/common_models.dart';
import '../exceptions/tesla_exceptions.dart';

class ChargingEndpoints {
  final TeslaFleetClient _client;

  ChargingEndpoints(this._client);

  Future<List<ChargingSession>> getChargingHistory({
    String? vin,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, String>{};
    
    if (vin != null) queryParams['vin'] = vin;
    if (startTime != null) {
      queryParams['start_time'] = startTime.toIso8601String();
    }
    if (endTime != null) {
      queryParams['end_time'] = endTime.toIso8601String();
    }
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    
    final response = await _client.get(
      '/api/1/dx/charging/history',
      queryParams: queryParams,
    );
    
    final apiResponse = ApiResponse<List<dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return apiResponse.response!
          .map((session) => ChargingSession.fromJson(session))
          .toList();
    }
    
    throw TeslaApiException(
      apiResponse.error ?? 'Failed to fetch charging history',
    );
  }

  Future<ChargingSession> getChargingSession(String sessionId) async {
    final response = await _client.get('/api/1/dx/charging/history/details/$sessionId');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return ChargingSession.fromJson(apiResponse.response!);
    }
    
    throw TeslaApiException(
      apiResponse.error ?? 'Failed to fetch charging session details',
    );
  }

  Future<ChargingInvoice> getChargingInvoice(String sessionId) async {
    final response = await _client.get('/api/1/dx/charging/history/details/$sessionId/invoice');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return ChargingInvoice.fromJson(apiResponse.response!);
    }
    
    throw TeslaApiException(
      apiResponse.error ?? 'Failed to fetch charging invoice',
    );
  }
}