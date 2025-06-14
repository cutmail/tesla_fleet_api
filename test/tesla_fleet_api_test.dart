import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:tesla_fleet_api/tesla_fleet_api.dart';

import 'mocks/mock_http_client.dart';
import 'mocks/mock_tesla_auth.dart';

void main() {
  group('TeslaFleetClient', () {
    late MockHttpClient mockHttpClient;
    late MockTeslaAuth auth;
    late TeslaFleetClient client;

    setUp(() {
      mockHttpClient = MockHttpClient();
      auth = MockTeslaAuth();
      client = TeslaFleetClient(
        auth: auth,
        httpClient: mockHttpClient,
      );
    });

    tearDown(() {
      client.dispose();
    });

    group('Vehicle Operations', () {
      test('should list vehicles successfully', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('''
        {
          "response": [
            {
              "id": 12345,
              "vehicle_id": 67890,
              "vin": "TEST123456789",
              "display_name": "Test Vehicle",
              "state": "online"
            }
          ]
        }
        ''', 200));

        // Act
        final vehicles = await client.vehicles.list();

        // Assert
        expect(vehicles, hasLength(1));
        expect(vehicles.first.id, equals(12345));
        expect(vehicles.first.displayName, equals('Test Vehicle'));
        expect(vehicles.first.vin, equals('TEST123456789'));
        expect(mockHttpClient.lastRequest?.url.path, equals('/api/1/vehicles'));
      });

      test('should get vehicle data successfully', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('''
        {
          "response": {
            "id": 12345,
            "vin": "TEST123456789",
            "display_name": "Test Vehicle",
            "charge_state": {
              "battery_level": 75,
              "charging_state": "Disconnected"
            }
          }
        }
        ''', 200));

        // Act
        final vehicleData = await client.vehicles.getVehicleData('12345');

        // Assert
        expect(vehicleData.id, equals(12345));
        expect(vehicleData.chargeState?.batteryLevel, equals(75));
        expect(mockHttpClient.lastRequest?.url.path, equals('/api/1/vehicles/12345/vehicle_data'));
      });

      test('should execute vehicle commands successfully', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('''
        {
          "response": {
            "result": true,
            "reason": ""
          }
        }
        ''', 200));

        // Act
        final response = await client.vehicles.unlockDoors('12345');

        // Assert
        expect(response.result, equals(true));
        expect(mockHttpClient.lastRequest?.url.path, equals('/api/1/vehicles/12345/command/door_unlock'));
      });

      test('should handle vehicle command failures', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('''
        {
          "response": {
            "result": false,
            "reason": "vehicle_unavailable"
          }
        }
        ''', 200));

        // Act
        final response = await client.vehicles.lockDoors('12345');

        // Assert
        expect(response.result, equals(false));
        expect(response.reason, equals('vehicle_unavailable'));
      });

      test('should throw TeslaVehicleException on vehicle error', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('''
        {
          "error": "vehicle_not_found",
          "error_description": ["Vehicle not found"]
        }
        ''', 404));

        // Act & Assert
        expect(
          () => client.vehicles.getVehicleData('invalid-id'),
          throwsA(isA<TeslaApiException>()),
        );
      });
    });

    group('Energy Operations', () {
      test('should list energy products successfully', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('''
        {
          "response": [
            {
              "energy_site_id": 12345,
              "resource_type": "battery",
              "site_name": "Test Site"
            }
          ]
        }
        ''', 200));

        // Act
        final products = await client.energy.list();

        // Assert
        expect(products, hasLength(1));
        expect(products.first.energySiteId, equals(12345));
        expect(products.first.siteName, equals('Test Site'));
      });

      test('should get energy live status successfully', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('''
        {
          "response": {
            "solar_power": 5000,
            "battery_power": -2000,
            "grid_power": 3000,
            "percentage_charged": 85.5
          }
        }
        ''', 200));

        // Act
        final status = await client.energy.getLiveStatus(12345);

        // Assert
        expect(status.solarPower, equals(5000));
        expect(status.batteryPower, equals(-2000));
        expect(status.percentageCharged, equals(85.5));
      });
    });

    group('Charging Operations', () {
      test('should get charging history successfully', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('''
        {
          "response": [
            {
              "session_id": "session-123",
              "vin": "TEST123456789",
              "energy_used": 45.2,
              "charge_cost": 12.50
            }
          ]
        }
        ''', 200));

        // Act
        final sessions = await client.charging.getChargingHistory(vin: 'TEST123456789');

        // Assert
        expect(sessions, hasLength(1));
        expect(sessions.first.sessionId, equals('session-123'));
        expect(sessions.first.energyUsed, equals(45.2));
      });
    });

    group('Authentication', () {
      test('should handle authentication errors', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('''
        {
          "error": "invalid_token",
          "error_description": "The access token is invalid"
        }
        ''', 401));

        // Act & Assert
        expect(
          () => client.vehicles.list(),
          throwsA(isA<TeslaApiException>()),
        );
      });

      test('should handle rate limiting', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response(
          '{"error": "rate_limit_exceeded"}',
          429,
          headers: {'retry-after': '60'},
        ));

        // Act & Assert
        expect(
          () => client.vehicles.list(),
          throwsA(isA<TeslaRateLimitException>()),
        );
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Arrange
        mockHttpClient.setThrowError(Exception('Network error'));

        // Act & Assert
        expect(
          () => client.vehicles.list(),
          throwsA(isA<TeslaApiException>()),
        );
      });

      test('should handle invalid JSON responses', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('invalid json', 200));

        // Act & Assert
        expect(
          () => client.vehicles.list(),
          throwsA(isA<TeslaApiException>()),
        );
      });

      test('should handle empty responses', () async {
        // Arrange
        mockHttpClient.setResponse(http.Response('{}', 200));

        // Act & Assert - should throw exception for missing response field
        expect(
          () => client.vehicles.list(),
          throwsA(isA<TeslaApiException>()),
        );
      });
    });
  });

  group('TeslaAuth', () {
    test('should create TeslaAuth instance', () {
      final auth = TeslaAuth(
        clientId: 'test-client',
        clientSecret: 'test-secret',
        privateKey: 'test-key',
      );

      expect(auth.clientId, equals('test-client'));
      expect(auth.clientSecret, equals('test-secret'));
      expect(auth.privateKey, equals('test-key'));
    });
  });

  group('Exceptions', () {
    test('should create TeslaException with message', () {
      const exception = TeslaException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.statusCode, isNull);
    });

    test('should create TeslaException with status code', () {
      const exception = TeslaException('Test error', 404);
      expect(exception.message, equals('Test error'));
      expect(exception.statusCode, equals(404));
    });

    test('should create TeslaVehicleException with vehicle ID', () {
      const exception = TeslaVehicleException('Vehicle error', 'vehicle-123');
      expect(exception.message, equals('Vehicle error'));
      expect(exception.vehicleId, equals('vehicle-123'));
    });

    test('should create TeslaRateLimitException with retry duration', () {
      const retryAfter = Duration(seconds: 60);
      const exception = TeslaRateLimitException('Rate limited', retryAfter);
      expect(exception.message, equals('Rate limited'));
      expect(exception.retryAfter, equals(retryAfter));
    });
  });
}