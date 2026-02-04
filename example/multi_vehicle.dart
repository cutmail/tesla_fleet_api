/// Demonstrates working with multiple vehicles using the Tesla Fleet API.
///
/// This example shows how to:
/// - List all vehicles and display a summary
/// - Fetch data for each vehicle in sequence
/// - Compare battery levels and ranges across a fleet
/// - Wake up all vehicles
/// - Send a command to a specific vehicle selected by the user
///
/// Required scopes: vehicle_device_data, vehicle_cmds
///
/// Usage:
///   dart run example/multi_vehicle.dart
import 'dart:io';
import 'package:tesla_fleet_api/tesla_fleet_api.dart';

void main() async {
  print('=== Multi-Vehicle Management Demo ===\n');

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
    state: 'multi-${DateTime.now().millisecondsSinceEpoch}',
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
    // List all vehicles
    final vehicles = await client.vehicles.list();

    if (vehicles.isEmpty) {
      print('No vehicles found in your account.');
      return;
    }

    print('\n--- Fleet Overview ---');
    print('Total vehicles: ${vehicles.length}\n');

    // Display fleet summary
    for (var i = 0; i < vehicles.length; i++) {
      final v = vehicles[i];
      print('${i + 1}. ${v.displayName ?? "Unnamed"}');
      print('   VIN: ${v.vin}');
      print('   ID: ${v.id}');
      print('   State: ${v.state}');
      print('');
    }

    // Menu
    while (true) {
      print('--- Fleet Menu ---');
      print('1. Fetch data for all online vehicles');
      print('2. Compare battery status across fleet');
      print('3. Wake up all sleeping vehicles');
      print('4. Select a vehicle for commands');
      print('5. Fleet location overview');
      print('6. Exit');
      stdout.write('Enter choice (1-6): ');

      final choice = stdin.readLineSync();
      switch (choice) {
        case '1':
          await fetchAllVehicleData(client, vehicles);
          break;

        case '2':
          await compareBatteryStatus(client, vehicles);
          break;

        case '3':
          await wakeUpAll(client, vehicles);
          break;

        case '4':
          await selectAndControl(client, vehicles);
          break;

        case '5':
          await fleetLocationOverview(client, vehicles);
          break;

        case '6':
          print('Exiting.');
          return;

        default:
          print('Invalid choice\n');
      }
    }
  } on TeslaApiException catch (e) {
    print('API error: ${e.message} (status: ${e.statusCode})');
  } on TeslaAuthException catch (e) {
    print('Auth error: ${e.message}');
  } finally {
    client.dispose();
  }
}

/// Fetches and displays data for each online vehicle.
Future<void> fetchAllVehicleData(
    TeslaFleetClient client, List<Vehicle> vehicles) async {
  print('\n--- All Vehicle Data ---\n');

  for (final vehicle in vehicles) {
    final id = vehicle.id.toString();
    print('${vehicle.displayName ?? "Unnamed"} (${vehicle.vin}):');

    if (vehicle.state != 'online') {
      print('  Skipped - vehicle is ${vehicle.state}\n');
      continue;
    }

    try {
      final data = await client.vehicles.getVehicleData(id);

      if (data.chargeState != null) {
        print('  Battery: ${data.chargeState!.batteryLevel}% '
            '(${data.chargeState!.batteryRange} mi)');
        print('  Charging: ${data.chargeState!.chargingState}');
      }

      if (data.climateState != null) {
        print('  Inside temp: ${data.climateState!.insideTemp}C');
        print('  Climate on: ${data.climateState!.isClimateOn}');
      }

      if (data.vehicleState != null) {
        print('  Locked: ${data.vehicleState!.locked}');
        print('  Odometer: ${data.vehicleState!.odometer} mi');
      }
    } on TeslaVehicleException catch (e) {
      print('  Error: ${e.message}');
    } on TeslaApiException catch (e) {
      print('  Error: ${e.message}');
    }
    print('');
  }
}

/// Compares battery status across all online vehicles.
Future<void> compareBatteryStatus(
    TeslaFleetClient client, List<Vehicle> vehicles) async {
  print('\n--- Battery Comparison ---\n');

  final batteryData = <String, Map<String, dynamic>>{};

  for (final vehicle in vehicles) {
    final name = vehicle.displayName ?? vehicle.vin ?? 'Unknown';

    if (vehicle.state != 'online') {
      print('$name: ${vehicle.state} (skipped)');
      continue;
    }

    try {
      final data =
          await client.vehicles.getVehicleData(vehicle.id.toString());
      if (data.chargeState != null) {
        batteryData[name] = {
          'level': data.chargeState!.batteryLevel,
          'range': data.chargeState!.batteryRange,
          'charging': data.chargeState!.chargingState,
          'limit': data.chargeState!.chargeLimitSoc,
        };
      }
    } catch (e) {
      print('$name: Could not retrieve data');
    }
  }

  if (batteryData.isEmpty) {
    print('No battery data available. Are any vehicles online?');
    return;
  }

  // Display comparison
  print('Vehicle'.padRight(25) +
      'Battery'.padRight(10) +
      'Range'.padRight(12) +
      'Limit'.padRight(8) +
      'Status');
  print('-' * 70);

  for (final entry in batteryData.entries) {
    final d = entry.value;
    final level = d['level']?.toString() ?? 'N/A';
    final range = d['range']?.toString() ?? 'N/A';
    final limit = d['limit']?.toString() ?? 'N/A';
    final charging = d['charging']?.toString() ?? 'N/A';

    print(entry.key.padRight(25) +
        '$level%'.padRight(10) +
        '${range}mi'.padRight(12) +
        '$limit%'.padRight(8) +
        charging);
  }

  // Find lowest battery
  String? lowestName;
  int? lowestLevel;
  for (final entry in batteryData.entries) {
    final level = entry.value['level'] as int?;
    if (level != null && (lowestLevel == null || level < lowestLevel)) {
      lowestLevel = level;
      lowestName = entry.key;
    }
  }

  if (lowestName != null) {
    print('\nLowest battery: $lowestName at $lowestLevel%');
    if (lowestLevel != null && lowestLevel < 20) {
      print('Warning: $lowestName has low battery. Consider charging soon.');
    }
  }
}

/// Wakes up all sleeping vehicles.
Future<void> wakeUpAll(
    TeslaFleetClient client, List<Vehicle> vehicles) async {
  print('\n--- Waking Up All Vehicles ---\n');

  final sleepingVehicles = vehicles
      .where((v) => v.state == 'asleep' || v.state == 'offline')
      .toList();

  if (sleepingVehicles.isEmpty) {
    print('All vehicles are already online.');
    return;
  }

  print('Found ${sleepingVehicles.length} sleeping/offline vehicle(s).');
  stdout.write('Wake up all? (y/n): ');
  if (stdin.readLineSync()?.toLowerCase() != 'y') {
    print('Cancelled.');
    return;
  }

  for (final vehicle in sleepingVehicles) {
    final name = vehicle.displayName ?? vehicle.vin ?? 'Unknown';
    print('Waking up $name...');
    try {
      final result = await client.vehicles.wakeUp(vehicle.id.toString());
      print('  Result: ${result.result}');
    } catch (e) {
      print('  Failed: $e');
    }
  }

  print('\nWaiting 15 seconds for vehicles to come online...');
  await Future.delayed(Duration(seconds: 15));

  // Re-check status
  final updated = await client.vehicles.list();
  print('\nUpdated status:');
  for (final v in updated) {
    print('  ${v.displayName ?? v.vin}: ${v.state}');
  }
}

/// Lets the user select a vehicle and send a command.
Future<void> selectAndControl(
    TeslaFleetClient client, List<Vehicle> vehicles) async {
  print('\n--- Select Vehicle ---');
  for (var i = 0; i < vehicles.length; i++) {
    final v = vehicles[i];
    print('${i + 1}. ${v.displayName ?? "Unnamed"} (${v.state})');
  }

  stdout.write('Select vehicle (1-${vehicles.length}): ');
  final input = stdin.readLineSync();
  final index = (int.tryParse(input ?? '') ?? 1) - 1;

  if (index < 0 || index >= vehicles.length) {
    print('Invalid selection');
    return;
  }

  final vehicle = vehicles[index];
  final vehicleId = vehicle.id.toString();
  print('\nSelected: ${vehicle.displayName}');

  if (vehicle.state != 'online') {
    print('Vehicle is ${vehicle.state}. Waking up first...');
    await client.vehicles.wakeUp(vehicleId);
    await Future.delayed(Duration(seconds: 10));
  }

  print('\nCommands:');
  print('1. Flash lights');
  print('2. Honk horn');
  print('3. Lock doors');
  print('4. Unlock doors');
  print('5. Start climate');
  print('6. Stop climate');
  stdout.write('Enter choice (1-6): ');

  final choice = stdin.readLineSync();
  try {
    CommandResponse result;
    switch (choice) {
      case '1':
        result = await client.vehicles.flashLights(vehicleId);
        break;
      case '2':
        result = await client.vehicles.honkHorn(vehicleId);
        break;
      case '3':
        result = await client.vehicles.lockDoors(vehicleId);
        break;
      case '4':
        result = await client.vehicles.unlockDoors(vehicleId);
        break;
      case '5':
        result = await client.vehicles.startClimate(vehicleId);
        break;
      case '6':
        result = await client.vehicles.stopClimate(vehicleId);
        break;
      default:
        print('Invalid choice');
        return;
    }
    print('Result: ${result.result}');
    if (result.reason != null) {
      print('Reason: ${result.reason}');
    }
  } on TeslaVehicleException catch (e) {
    print('Vehicle error: ${e.message}');
  }
}

/// Displays the location of all online vehicles.
Future<void> fleetLocationOverview(
    TeslaFleetClient client, List<Vehicle> vehicles) async {
  print('\n--- Fleet Locations ---\n');

  for (final vehicle in vehicles) {
    final name = vehicle.displayName ?? vehicle.vin ?? 'Unknown';

    if (vehicle.state != 'online') {
      print('$name: ${vehicle.state} (location unavailable)');
      continue;
    }

    try {
      final data =
          await client.vehicles.getVehicleData(vehicle.id.toString());
      if (data.driveState != null) {
        final ds = data.driveState!;
        print('$name:');
        print('  Location: ${ds.latitude}, ${ds.longitude}');
        print('  Speed: ${ds.speed ?? 0} mph');
        print('  Heading: ${ds.heading}');
        print('  Gear: ${ds.shiftState ?? "Park"}');
      } else {
        print('$name: Drive state unavailable');
      }
    } catch (e) {
      print('$name: Could not retrieve location');
    }
    print('');
  }
}
