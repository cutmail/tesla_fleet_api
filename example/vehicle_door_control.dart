/// Demonstrates vehicle door lock/unlock control using the Tesla Fleet API.
///
/// This example shows how to:
/// - Check vehicle state and wake it up if needed
/// - Lock and unlock vehicle doors
/// - Read door/window state from vehicle data
///
/// Required scopes: vehicle_device_data, vehicle_cmds
///
/// Usage:
///   dart run example/vehicle_door_control.dart
import 'dart:io';
import 'package:tesla_fleet_api/tesla_fleet_api.dart';

void main() async {
  print('=== Vehicle Door Control Demo ===\n');

  // Replace with your actual credentials
  final auth = TeslaAuth(
    clientId: 'YOUR_CLIENT_ID_HERE',
    clientSecret: 'YOUR_CLIENT_SECRET_HERE',
    privateKey: '',
    redirectUri: 'YOUR_REDIRECT_URI_HERE',
  );

  // Generate authorization URL with required scopes
  final authUrl = auth.generateAuthorizationUrl(
    scopes: [
      'openid',
      'offline_access',
      'vehicle_device_data',
      'vehicle_cmds',
    ],
    state: 'door-control-${DateTime.now().millisecondsSinceEpoch}',
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
    // List vehicles and pick the first one
    final vehicles = await client.vehicles.list();
    if (vehicles.isEmpty) {
      print('No vehicles found');
      return;
    }

    final vehicle = vehicles.first;
    final vehicleId = vehicle.id.toString();
    print('\nVehicle: ${vehicle.displayName} (${vehicle.vin})');
    print('State: ${vehicle.state}');

    // Wake up vehicle if needed
    if (vehicle.state == 'asleep' || vehicle.state == 'offline') {
      print('\nWaking up vehicle...');
      await client.vehicles.wakeUp(vehicleId);
      print('Waiting for vehicle to come online...');
      await Future.delayed(Duration(seconds: 10));
    }

    // Read current door/window state
    print('\n--- Current Door & Window State ---');
    final data = await client.vehicles.getVehicleData(vehicleId);
    if (data.vehicleState != null) {
      final vs = data.vehicleState!;
      print('Locked: ${vs.locked}');
      print('Driver front door: ${vs.df == 0 ? "closed" : "open"}');
      print('Passenger front door: ${vs.pf == 0 ? "closed" : "open"}');
      print('Driver rear door: ${vs.dr == 0 ? "closed" : "open"}');
      print('Passenger rear door: ${vs.pr == 0 ? "closed" : "open"}');
      print('Front trunk: ${vs.ft == 0 ? "closed" : "open"}');
      print('Rear trunk: ${vs.rt == 0 ? "closed" : "open"}');
    }

    // Door control menu
    print('\nChoose an action:');
    print('1. Lock doors');
    print('2. Unlock doors');
    stdout.write('Enter choice (1 or 2): ');

    final choice = stdin.readLineSync();
    switch (choice) {
      case '1':
        print('\nLocking doors...');
        final result = await client.vehicles.lockDoors(vehicleId);
        print('Lock result: ${result.result}');
        if (result.reason != null) {
          print('Reason: ${result.reason}');
        }
        break;

      case '2':
        stdout.write(
            '\nUnlocking doors is a sensitive action. Type "UNLOCK" to confirm: ');
        final confirm = stdin.readLineSync();
        if (confirm != 'UNLOCK') {
          print('Unlock cancelled');
          break;
        }
        print('Unlocking doors...');
        final result = await client.vehicles.unlockDoors(vehicleId);
        print('Unlock result: ${result.result}');
        if (result.reason != null) {
          print('Reason: ${result.reason}');
        }
        break;

      default:
        print('Invalid choice');
    }

    // Verify updated state
    print('\n--- Updated Door State ---');
    final updated = await client.vehicles.getVehicleData(vehicleId);
    if (updated.vehicleState != null) {
      print('Locked: ${updated.vehicleState!.locked}');
    }
  } on TeslaVehicleException catch (e) {
    print('Vehicle error: ${e.message} (vehicle: ${e.vehicleId})');
  } on TeslaApiException catch (e) {
    print('API error: ${e.message} (status: ${e.statusCode})');
  } on TeslaAuthException catch (e) {
    print('Auth error: ${e.message}');
  } finally {
    client.dispose();
  }
}
