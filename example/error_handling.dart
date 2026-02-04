/// Demonstrates error handling and retry patterns for the Tesla Fleet API.
///
/// This example shows how to:
/// - Handle each exception type (auth, API, rate limit, vehicle)
/// - Implement exponential backoff for rate limiting
/// - Retry operations that fail due to vehicle sleep
/// - Gracefully handle network and server errors
///
/// Required scopes: vehicle_device_data
///
/// Usage:
///   dart run example/error_handling.dart
import 'dart:io';
import 'package:tesla_fleet_api/tesla_fleet_api.dart';

void main() async {
  print('=== Error Handling Demo ===\n');

  final auth = TeslaAuth(
    clientId: 'YOUR_CLIENT_ID_HERE',
    clientSecret: 'YOUR_CLIENT_SECRET_HERE',
    privateKey: '',
    redirectUri: 'YOUR_REDIRECT_URI_HERE',
  );

  final authUrl = auth.generateAuthorizationUrl(
    scopes: [
      'openid',
      'offline_access',
      'vehicle_device_data',
      'vehicle_cmds',
      'vehicle_charging_cmds',
    ],
    state: 'errors-${DateTime.now().millisecondsSinceEpoch}',
  );

  print('Visit this URL to authorize:');
  print(authUrl);
  stdout.write('\nEnter authorization code: ');

  final code = stdin.readLineSync();
  if (code == null || code.trim().isEmpty) {
    print('No code provided');
    return;
  }

  try {
    await auth.exchangeAuthorizationCode(code.trim());
  } catch (e) {
    print('Authorization failed: $e');
    return;
  }

  final client = TeslaFleetClient(auth: auth);

  try {
    print('\n--- Demo 1: Basic exception handling ---');
    await demoBasicExceptionHandling(client);

    print('\n--- Demo 2: Retry with exponential backoff ---');
    await demoRetryWithBackoff(client);

    print('\n--- Demo 3: Wake-and-retry pattern ---');
    await demoWakeAndRetry(client);

    print('\n--- Demo 4: Multi-step operation with rollback ---');
    await demoMultiStepWithRollback(client);
  } finally {
    client.dispose();
  }
}

/// Demonstrates catching each specific exception type.
Future<void> demoBasicExceptionHandling(TeslaFleetClient client) async {
  print('Attempting to list vehicles with full exception handling...\n');

  try {
    final vehicles = await client.vehicles.list();
    print('Found ${vehicles.length} vehicle(s)');

    if (vehicles.isNotEmpty) {
      final vehicleId = vehicles.first.id.toString();
      final data = await client.vehicles.getVehicleData(vehicleId);
      print('Vehicle: ${data.vin}');
      print('Battery: ${data.chargeState?.batteryLevel}%');
    }
  } on TeslaAuthException catch (e) {
    // Authentication issues: invalid credentials, expired token
    print('[AUTH ERROR] ${e.message}');
    print('Action: Re-authenticate or check credentials.');
    print('  - Verify client_id and client_secret');
    print('  - Try refreshing the token');
    print('  - Re-run the authorization flow');
  } on TeslaRateLimitException catch (e) {
    // HTTP 429: Too many requests
    print('[RATE LIMIT] ${e.message}');
    print('Action: Wait ${e.retryAfter.inSeconds} seconds before retrying.');
  } on TeslaVehicleException catch (e) {
    // Vehicle-specific errors
    print('[VEHICLE ERROR] ${e.message}');
    print('Vehicle ID: ${e.vehicleId}');
    print('Action: Check vehicle state (asleep/offline) and try waking it.');
  } on TeslaApiException catch (e) {
    // General API errors (4xx/5xx)
    print('[API ERROR] ${e.message}');
    if (e.statusCode != null) {
      print('Status code: ${e.statusCode}');
      switch (e.statusCode!) {
        case 401:
          print('Action: Token expired. Re-authenticate.');
          break;
        case 403:
          print('Action: Check OAuth scopes. You may need additional permissions.');
          break;
        case 404:
          print('Action: Resource not found. Verify the vehicle/resource ID.');
          break;
        case 412:
          print('Action: Vehicle unavailable. Try waking it up first.');
          break;
        case >= 500:
          print('Action: Server error. Retry after a short delay.');
          break;
      }
    }
  } on TeslaException catch (e) {
    // Catch-all for any Tesla exception
    print('[TESLA ERROR] ${e.message}');
  } catch (e) {
    // Unexpected errors (network, parsing, etc.)
    print('[UNEXPECTED ERROR] $e');
    print('Action: Check network connectivity and try again.');
  }
}

/// Demonstrates retry with exponential backoff for rate-limited requests.
Future<void> demoRetryWithBackoff(TeslaFleetClient client) async {
  print('Fetching vehicles with automatic retry on rate limit...\n');

  final vehicles = await retryWithBackoff(
    () => client.vehicles.list(),
    maxAttempts: 4,
  );

  if (vehicles != null) {
    print('Retrieved ${vehicles.length} vehicle(s)');
  } else {
    print('Failed after maximum retries');
  }
}

/// Generic retry function with exponential backoff.
///
/// Retries on [TeslaRateLimitException] and server errors (5xx).
/// Uses exponential backoff: 2s, 4s, 8s, 16s.
Future<T?> retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxAttempts = 4,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } on TeslaRateLimitException catch (e) {
      if (attempt == maxAttempts) {
        print('Rate limit: max retries exceeded.');
        return null;
      }
      final wait = e.retryAfter;
      print('Rate limited (attempt $attempt/$maxAttempts). '
          'Waiting ${wait.inSeconds}s...');
      await Future.delayed(wait);
    } on TeslaApiException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 500) {
        if (attempt == maxAttempts) {
          print('Server error: max retries exceeded.');
          return null;
        }
        final wait = Duration(seconds: 1 << attempt); // 2, 4, 8, 16
        print('Server error (attempt $attempt/$maxAttempts). '
            'Waiting ${wait.inSeconds}s...');
        await Future.delayed(wait);
      } else {
        rethrow; // Client errors should not be retried
      }
    }
  }
  return null;
}

/// Demonstrates waking a vehicle and retrying the operation.
Future<void> demoWakeAndRetry(TeslaFleetClient client) async {
  print('Fetching vehicle data with auto-wake...\n');

  final vehicles = await client.vehicles.list();
  if (vehicles.isEmpty) {
    print('No vehicles found.');
    return;
  }

  final vehicle = vehicles.first;
  final vehicleId = vehicle.id.toString();
  print('Vehicle: ${vehicle.displayName} (state: ${vehicle.state})');

  final data = await getVehicleDataWithWakeUp(client, vehicleId);
  if (data != null) {
    print('Battery: ${data.chargeState?.batteryLevel}%');
    print('Range: ${data.chargeState?.batteryRange} mi');
    print('Locked: ${data.vehicleState?.locked}');
  } else {
    print('Could not retrieve vehicle data after wake attempts.');
  }
}

/// Fetches vehicle data, automatically waking the vehicle if needed.
///
/// Retries up to [maxWakeAttempts] times with polling intervals.
Future<VehicleData?> getVehicleDataWithWakeUp(
  TeslaFleetClient client,
  String vehicleId, {
  int maxWakeAttempts = 5,
  Duration pollInterval = const Duration(seconds: 5),
}) async {
  for (var attempt = 1; attempt <= maxWakeAttempts; attempt++) {
    try {
      return await client.vehicles.getVehicleData(vehicleId);
    } on TeslaVehicleException catch (e) {
      print('Vehicle error (attempt $attempt): ${e.message}');
    } on TeslaApiException catch (e) {
      if (e.statusCode == 408 || e.statusCode == 412) {
        // Vehicle is likely asleep
        print('Vehicle unavailable (attempt $attempt/$maxWakeAttempts). '
            'Sending wake-up...');
        try {
          await client.vehicles.wakeUp(vehicleId);
        } catch (_) {
          // Wake-up command may fail if already waking
        }
        if (attempt < maxWakeAttempts) {
          print('Waiting ${pollInterval.inSeconds}s...');
          await Future.delayed(pollInterval);
        }
      } else {
        rethrow;
      }
    }
  }
  return null;
}

/// Demonstrates a multi-step operation with error recovery.
///
/// Scenario: Open charge port, set charge limit, start charging.
/// If any step fails, attempt to undo previous steps.
Future<void> demoMultiStepWithRollback(TeslaFleetClient client) async {
  print('Running multi-step charging setup with rollback...\n');

  final vehicles = await client.vehicles.list();
  if (vehicles.isEmpty) {
    print('No vehicles found.');
    return;
  }

  final vehicle = vehicles.first;
  final vehicleId = vehicle.id.toString();

  if (vehicle.state != 'online') {
    print('Vehicle is not online. Skipping multi-step demo.');
    return;
  }

  var chargePortOpened = false;
  var chargeLimitSet = false;

  try {
    // Step 1: Open charge port
    print('Step 1: Opening charge port...');
    final openResult = await client.vehicles.openChargePort(vehicleId);
    chargePortOpened = openResult.result;
    print('  Result: ${openResult.result}');

    // Step 2: Set charge limit
    print('Step 2: Setting charge limit to 80%...');
    final limitResult = await client.vehicles.setChargeLimit(vehicleId, 80);
    chargeLimitSet = limitResult.result;
    print('  Result: ${limitResult.result}');

    // Step 3: Start charging
    print('Step 3: Starting charging...');
    final chargeResult = await client.vehicles.startCharging(vehicleId);
    print('  Result: ${chargeResult.result}');
    if (chargeResult.reason != null) {
      print('  Reason: ${chargeResult.reason}');
    }

    print('\nCharging setup completed successfully.');
  } on TeslaVehicleException catch (e) {
    print('\nVehicle error during setup: ${e.message}');
    await _rollback(client, vehicleId, chargePortOpened, chargeLimitSet);
  } on TeslaApiException catch (e) {
    print('\nAPI error during setup: ${e.message}');
    await _rollback(client, vehicleId, chargePortOpened, chargeLimitSet);
  }
}

/// Attempts to undo previous steps in case of failure.
Future<void> _rollback(
  TeslaFleetClient client,
  String vehicleId,
  bool chargePortOpened,
  bool chargeLimitSet,
) async {
  print('Attempting rollback...');

  if (chargeLimitSet) {
    try {
      print('  Resetting charge limit to 90% (default)...');
      await client.vehicles.setChargeLimit(vehicleId, 90);
    } catch (e) {
      print('  Could not reset charge limit: $e');
    }
  }

  if (chargePortOpened) {
    try {
      print('  Closing charge port...');
      await client.vehicles.closeChargePort(vehicleId);
    } catch (e) {
      print('  Could not close charge port: $e');
    }
  }

  print('Rollback complete.');
}
