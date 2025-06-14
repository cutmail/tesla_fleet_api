import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth/tesla_auth.dart';
import 'exceptions/tesla_exceptions.dart';
import 'endpoints/vehicle_endpoints.dart';
import 'endpoints/energy_endpoints.dart';
import 'endpoints/charging_endpoints.dart';
import 'endpoints/partner_endpoints.dart';

class TeslaFleetClient {
  final TeslaAuth _auth;
  final String baseUrl;
  final http.Client _httpClient;
  
  late final VehicleEndpoints vehicles;
  late final EnergyEndpoints energy;
  late final ChargingEndpoints charging;
  late final PartnerEndpoints partner;
  
  TeslaFleetClient({
    required TeslaAuth auth,
    this.baseUrl = 'https://fleet-api.prd.na.vn.cloud.tesla.com',
    http.Client? httpClient,
  }) : _auth = auth, _httpClient = httpClient ?? http.Client() {
    vehicles = VehicleEndpoints(this);
    energy = EnergyEndpoints(this);
    charging = ChargingEndpoints(this);
    partner = PartnerEndpoints(this);
  }
  
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    return _makeRequest('GET', endpoint, queryParams: queryParams);
  }
  
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    return _makeRequest('POST', endpoint, body: body, queryParams: queryParams);
  }
  
  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    return _makeRequest('PUT', endpoint, body: body, queryParams: queryParams);
  }
  
  Future<Map<String, dynamic>> delete(String endpoint, {Map<String, String>? queryParams}) async {
    return _makeRequest('DELETE', endpoint, queryParams: queryParams);
  }
  
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      final token = await _auth.getAccessToken();
      
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      // print('🌐 HTTP Request: $method $uri');
      
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent': 'tesla_fleet_api/1.0.0',
      };
      
      // print('📋 Headers: ${headers.keys.join(', ')}');
      // print('🔑 Token length: ${token.length} chars');
      
      late http.Response response;
      
      switch (method) {
        case 'GET':
          response = await _httpClient.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _httpClient.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await _httpClient.put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await _httpClient.delete(uri, headers: headers);
          break;
        default:
          throw TeslaApiException('Unsupported HTTP method: $method');
      }
      
      if (response.statusCode >= 400) {
        print('❌ HTTP ${response.statusCode}: $method $uri');
        print('📝 Response: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
      }
      // print('📊 HTTP Response: ${response.statusCode}');
      // print('📋 Response Headers: ${response.headers}');
      // print('📝 Response Body (first 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ HTTP Request Exception: $e');
      print('❌ Exception type: ${e.runtimeType}');
      if (e is TeslaException) rethrow;
      throw TeslaApiException('Request failed: $e');
    }
  }
  
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 429) {
      final retryAfter = Duration(
        seconds: int.tryParse(response.headers['retry-after'] ?? '60') ?? 60,
      );
      throw TeslaRateLimitException(
        'Rate limit exceeded',
        retryAfter,
        response.statusCode,
      );
    }
    
    if (response.statusCode >= 400) {
      String errorMessage = 'HTTP ${response.statusCode}';
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['error']?['message'] ?? errorMessage;
      } catch (_) {}
      
      throw TeslaApiException(errorMessage, response.statusCode);
    }
    
    if (response.body.isEmpty) {
      return {};
    }
    
    try {
      return json.decode(response.body);
    } catch (e) {
      throw TeslaApiException('Invalid JSON response: $e');
    }
  }
  
  void dispose() {
    _httpClient.close();
  }
}