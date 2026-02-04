/// Demonstrates the full climate control lifecycle using the Tesla Fleet API.
///
/// This example shows how to:
/// - Read current climate state (temps, HVAC status)
/// - Start climate pre-conditioning
/// - Set driver and passenger temperatures independently
/// - Stop climate control
///
/// Required scopes: vehicle_device_data, vehicle_cmds
///
/// Usage:
///   dart run example/climate_control.dart
import 'dart:io';
import 'package:tesla_fleet_api/tesla_fleet_api.dart';

void main() async {
  print('=== Climate Control Demo ===\n');

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
    ],
    state: 'climate-${DateTime.now().millisecondsSinceEpoch}',
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
    final vehicles = await client.vehicles.list();
    if (vehicles.isEmpty) {
      print('No vehicles found');
      return;
    }

    final vehicle = vehicles.first;
    final vehicleId = vehicle.id.toString();
    print('\nVehicle: ${vehicle.displayName} (${vehicle.vin})');

    // Wake up if needed
    if (vehicle.state == 'asleep' || vehicle.state == 'offline') {
      print('Waking up vehicle...');
      await client.vehicles.wakeUp(vehicleId);
      await Future.delayed(Duration(seconds: 10));
    }

    // Read current climate state
    final data = await client.vehicles.getVehicleData(vehicleId);
    if (data.climateState != null) {
      final cs = data.climateState!;
      print('\n--- Current Climate State ---');
      print('Climate on: ${cs.isClimateOn}');
      print('Inside temperature: ${cs.insideTemp}C');
      print('Outside temperature: ${cs.outsideTemp}C');
      print('Driver temp setting: ${cs.driverTempSetting}C');
      print('Passenger temp setting: ${cs.passengerTempSetting}C');
      print('Fan status: ${cs.fanStatus}');
      print('Seat heater left: ${cs.seatHeaterLeft}');
      print('Seat heater right: ${cs.seatHeaterRight}');
      print('Defrost mode: ${cs.defrostMode}');
    }

    // Climate control menu
    print('\nChoose an action:');
    print('1. Start climate pre-conditioning');
    print('2. Set temperature');
    print('3. Stop climate control');
    print('4. Full cycle: start -> set temp -> wait -> stop');
    stdout.write('Enter choice (1-4): ');

    final choice = stdin.readLineSync();
    switch (choice) {
      case '1':
        print('\nStarting climate control...');
        final result = await client.vehicles.startClimate(vehicleId);
        print('Start climate result: ${result.result}');
        break;

      case '2':
        stdout.write('\nEnter driver temperature (C, e.g. 21.5): ');
        final driverInput = stdin.readLineSync();
        stdout.write('Enter passenger temperature (C, e.g. 21.5): ');
        final passengerInput = stdin.readLineSync();

        final driverTemp = double.tryParse(driverInput ?? '') ?? 21.0;
        final passengerTemp = double.tryParse(passengerInput ?? '') ?? 21.0;

        print('Setting temperature: driver=${driverTemp}C, '
            'passenger=${passengerTemp}C...');
        final result = await client.vehicles
            .setTemperature(vehicleId, driverTemp, passengerTemp);
        print('Set temperature result: ${result.result}');
        break;

      case '3':
        print('\nStopping climate control...');
        final result = await client.vehicles.stopClimate(vehicleId);
        print('Stop climate result: ${result.result}');
        break;

      case '4':
        await runFullClimateCycle(client, vehicleId);
        break;

      default:
        print('Invalid choice');
    }

    // Show updated state
    print('\n--- Updated Climate State ---');
    final updated = await client.vehicles.getVehicleData(vehicleId);
    if (updated.climateState != null) {
      print('Climate on: ${updated.climateState!.isClimateOn}');
      print('Driver temp setting: ${updated.climateState!.driverTempSetting}C');
      print(
          'Passenger temp setting: ${updated.climateState!.passengerTempSetting}C');
    }
  } on TeslaVehicleException catch (e) {
    print('Vehicle error: ${e.message} (vehicle: ${e.vehicleId})');
  } on TeslaApiException catch (e) {
    print('API error: ${e.message} (status: ${e.statusCode})');
  } finally {
    client.dispose();
  }
}

/// Runs a complete climate control cycle: start -> set temp -> wait -> stop.
Future<void> runFullClimateCycle(
    TeslaFleetClient client, String vehicleId) async {
  print('\n--- Full Climate Cycle ---');

  // Step 1: Start climate
  print('Step 1: Starting climate control...');
  final startResult = await client.vehicles.startClimate(vehicleId);
  print('  Result: ${startResult.result}');
  await Future.delayed(Duration(seconds: 2));

  // Step 2: Set temperature to 22C for both driver and passenger
  print('Step 2: Setting temperature to 22C...');
  final tempResult =
      await client.vehicles.setTemperature(vehicleId, 22.0, 22.0);
  print('  Result: ${tempResult.result}');

  // Step 3: Show current state while running
  print('Step 3: Climate is now running. Checking state...');
  await Future.delayed(Duration(seconds: 3));
  final data = await client.vehicles.getVehicleData(vehicleId);
  if (data.climateState != null) {
    print('  Climate on: ${data.climateState!.isClimateOn}');
    print('  Inside temp: ${data.climateState!.insideTemp}C');
  }

  // Step 4: Stop climate
  print('Step 4: Stopping climate control...');
  final stopResult = await client.vehicles.stopClimate(vehicleId);
  print('  Result: ${stopResult.result}');

  print('Climate cycle complete.');
}
