import '../tesla_fleet_client.dart';
import '../models/vehicle_models.dart';
import '../models/common_models.dart';
import '../exceptions/tesla_exceptions.dart';

class VehicleEndpoints {
  final TeslaFleetClient _client;

  VehicleEndpoints(this._client);

  Future<List<Vehicle>> list() async {
    print('🚗 Fetching vehicles list...');
    
    final response = await _client.get('/api/1/vehicles');
    final apiResponse = ApiResponse<List<dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      print('✅ Found ${apiResponse.response!.length} vehicles');
      return apiResponse.response!
          .map((vehicle) => Vehicle.fromJson(vehicle))
          .toList();
    }
    
    throw TeslaApiException(apiResponse.error ?? 'Failed to fetch vehicles');
  }

  Future<VehicleData> getVehicleData(String vehicleId) async {
    final response = await _client.get('/api/1/vehicles/$vehicleId/vehicle_data');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return VehicleData.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to fetch vehicle data',
      vehicleId,
    );
  }

  Future<CommandResponse> wakeUp(String vehicleId) async {
    final response = await _client.post('/api/1/vehicles/$vehicleId/wake_up');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to wake up vehicle',
      vehicleId,
    );
  }

  Future<CommandResponse> unlockDoors(String vehicleId) async {
    final response = await _client.post('/api/1/vehicles/$vehicleId/command/door_unlock');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to unlock doors',
      vehicleId,
    );
  }

  Future<CommandResponse> lockDoors(String vehicleId) async {
    final response = await _client.post('/api/1/vehicles/$vehicleId/command/door_lock');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to lock doors',
      vehicleId,
    );
  }

  Future<CommandResponse> honkHorn(String vehicleId) async {
    final response = await _client.post('/api/1/vehicles/$vehicleId/command/honk_horn');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to honk horn',
      vehicleId,
    );
  }

  Future<CommandResponse> flashLights(String vehicleId) async {
    final response = await _client.post('/api/1/vehicles/$vehicleId/command/flash_lights');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to flash lights',
      vehicleId,
    );
  }

  Future<CommandResponse> startClimate(String vehicleId) async {
    final response = await _client.post('/api/1/vehicles/$vehicleId/command/auto_conditioning_start');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to start climate control',
      vehicleId,
    );
  }

  Future<CommandResponse> stopClimate(String vehicleId) async {
    final response = await _client.post('/api/1/vehicles/$vehicleId/command/auto_conditioning_stop');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to stop climate control',
      vehicleId,
    );
  }

  Future<CommandResponse> setTemperature(String vehicleId, double driverTemp, double passengerTemp) async {
    final response = await _client.post(
      '/api/1/vehicles/$vehicleId/command/set_temps',
      body: {
        'driver_temp': driverTemp,
        'passenger_temp': passengerTemp,
      },
    );
    
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to set temperature',
      vehicleId,
    );
  }

  Future<CommandResponse> startCharging(String vehicleId) async {
    final response = await _client.post('/api/1/vehicles/$vehicleId/command/charge_start');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to start charging',
      vehicleId,
    );
  }

  Future<CommandResponse> stopCharging(String vehicleId) async {
    final response = await _client.post('/api/1/vehicles/$vehicleId/command/charge_stop');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to stop charging',
      vehicleId,
    );
  }

  Future<CommandResponse> setChargeLimit(String vehicleId, int percent) async {
    final response = await _client.post(
      '/api/1/vehicles/$vehicleId/command/set_charge_limit',
      body: {'percent': percent},
    );
    
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to set charge limit',
      vehicleId,
    );
  }

  Future<CommandResponse> openChargePort(String vehicleId) async {
    final response = await _client.post('/api/1/vehicles/$vehicleId/command/charge_port_door_open');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to open charge port',
      vehicleId,
    );
  }

  Future<CommandResponse> closeChargePort(String vehicleId) async {
    final response = await _client.post('/api/1/vehicles/$vehicleId/command/charge_port_door_close');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(response);
    
    if (apiResponse.response != null) {
      return CommandResponse.fromJson(apiResponse.response!);
    }
    
    throw TeslaVehicleException(
      apiResponse.error ?? 'Failed to close charge port',
      vehicleId,
    );
  }
}