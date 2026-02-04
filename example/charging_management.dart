/// Demonstrates charging management using the Tesla Fleet API.
///
/// This example shows how to:
/// - Read current charge state (battery level, range, charging status)
/// - Open and close the charge port
/// - Start and stop charging
/// - Set charge limit
/// - Retrieve charging session details and invoices
///
/// Required scopes: vehicle_device_data, vehicle_cmds, vehicle_charging_cmds
///
/// Usage:
///   dart run example/charging_management.dart
import 'dart:convert';
import 'dart:io';
import 'package:tesla_fleet_api/tesla_fleet_api.dart';

void main() async {
  print('=== Charging Management Demo ===\n');

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
    state: 'charging-${DateTime.now().millisecondsSinceEpoch}',
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

    // Show current charge state
    final data = await client.vehicles.getVehicleData(vehicleId);
    if (data.chargeState != null) {
      final cs = data.chargeState!;
      print('\n--- Current Charge State ---');
      print('Battery level: ${cs.batteryLevel}%');
      print('Battery range: ${cs.batteryRange} miles');
      print('Charging state: ${cs.chargingState}');
      print('Charge limit: ${cs.chargeLimitSoc}%');
      print('Charge port open: ${cs.chargePortDoorOpen}');
      print('Charge port latch: ${cs.chargePortLatch}');
      print('Time to full charge: ${cs.timeToFullCharge} hours');
      print('Charge rate: ${cs.chargeRate} mph');
      print('Charger power: ${cs.chargerPower} kW');
      print('Charge energy added: ${cs.chargeEnergyAdded} kWh');
      print('Charge miles added (rated): ${cs.chargeMilesAddedRated}');
    }

    // Charging control menu
    print('\nChoose an action:');
    print('1. Open charge port');
    print('2. Close charge port');
    print('3. Start charging');
    print('4. Stop charging');
    print('5. Set charge limit');
    print('6. View charging history');
    print('7. View charging session details');
    print('8. Download charging invoice');
    stdout.write('Enter choice (1-8): ');

    final choice = stdin.readLineSync();
    switch (choice) {
      case '1':
        print('\nOpening charge port...');
        final result = await client.vehicles.openChargePort(vehicleId);
        print('Result: ${result.result}');
        break;

      case '2':
        print('\nClosing charge port...');
        final result = await client.vehicles.closeChargePort(vehicleId);
        print('Result: ${result.result}');
        break;

      case '3':
        print('\nStarting charging...');
        final result = await client.vehicles.startCharging(vehicleId);
        print('Result: ${result.result}');
        if (result.reason != null) {
          print('Reason: ${result.reason}');
        }
        break;

      case '4':
        print('\nStopping charging...');
        final result = await client.vehicles.stopCharging(vehicleId);
        print('Result: ${result.result}');
        break;

      case '5':
        stdout.write('\nEnter charge limit (50-100): ');
        final limitInput = stdin.readLineSync();
        final limit = int.tryParse(limitInput ?? '') ?? 80;
        final clampedLimit = limit.clamp(50, 100);
        print('Setting charge limit to $clampedLimit%...');
        final result =
            await client.vehicles.setChargeLimit(vehicleId, clampedLimit);
        print('Result: ${result.result}');
        break;

      case '6':
        await viewChargingHistory(client, vehicle.vin);
        break;

      case '7':
        await viewChargingSessionDetails(client, vehicle.vin);
        break;

      case '8':
        await downloadChargingInvoice(client, vehicle.vin);
        break;

      default:
        print('Invalid choice');
    }
  } on TeslaVehicleException catch (e) {
    print('Vehicle error: ${e.message} (vehicle: ${e.vehicleId})');
  } on TeslaApiException catch (e) {
    print('API error: ${e.message} (status: ${e.statusCode})');
  } finally {
    client.dispose();
  }
}

/// Retrieves and displays charging history with date filtering.
Future<void> viewChargingHistory(TeslaFleetClient client, String? vin) async {
  print('\n--- Charging History ---');

  // Get sessions from the last 30 days
  final sessions = await client.charging.getChargingHistory(
    vin: vin,
    startTime: DateTime.now().subtract(Duration(days: 30)),
    endTime: DateTime.now(),
    limit: 10,
  );

  if (sessions.isEmpty) {
    print('No charging sessions found in the last 30 days.');
    return;
  }

  print('Found ${sessions.length} sessions (last 30 days):\n');

  var totalEnergy = 0.0;
  var totalCost = 0.0;

  for (final session in sessions) {
    print('Session: ${session.sessionId}');
    print('  Location: ${session.siteLocationName ?? "Unknown"}');
    print('  Start: ${session.chargeStartDateTime}');
    print('  Stop: ${session.chargeStopDateTime}');
    print('  SOC: ${session.chargeStartSoc}% -> ${session.chargeStopSoc}%');
    print('  Range: ${session.chargeStartRatedRange} -> '
        '${session.chargeStopRatedRange} miles');
    print('  Energy used: ${session.energyUsed ?? 0} kWh');
    print('  Cost: \$${session.chargeCost ?? 0}');
    print('  Connector: ${session.connectorType}');
    print('');

    totalEnergy += session.energyUsed ?? 0;
    totalCost += session.chargeCost ?? 0;
  }

  print('--- Summary ---');
  print('Total energy: ${totalEnergy.toStringAsFixed(2)} kWh');
  print('Total cost: \$${totalCost.toStringAsFixed(2)}');
  if (sessions.isNotEmpty) {
    print(
        'Average cost per session: \$${(totalCost / sessions.length).toStringAsFixed(2)}');
    print(
        'Average energy per session: ${(totalEnergy / sessions.length).toStringAsFixed(2)} kWh');
  }
}

/// Retrieves detailed information for a specific charging session.
Future<void> viewChargingSessionDetails(
    TeslaFleetClient client, String? vin) async {
  // First, list recent sessions to pick one
  final sessions = await client.charging.getChargingHistory(
    vin: vin,
    limit: 5,
  );

  if (sessions.isEmpty) {
    print('No charging sessions available.');
    return;
  }

  print('\n--- Recent Sessions ---');
  for (var i = 0; i < sessions.length; i++) {
    print('${i + 1}. ${sessions[i].sessionId} '
        '- ${sessions[i].siteLocationName ?? "Unknown"} '
        '(${sessions[i].chargeStartDateTime})');
  }

  stdout.write('Enter session number (1-${sessions.length}): ');
  final input = stdin.readLineSync();
  final index = (int.tryParse(input ?? '') ?? 1) - 1;

  if (index < 0 || index >= sessions.length) {
    print('Invalid selection');
    return;
  }

  final sessionId = sessions[index].sessionId;
  if (sessionId == null) {
    print('Session ID not available');
    return;
  }

  print('\nFetching details for session: $sessionId...');
  final details = await client.charging.getChargingSession(sessionId);

  print('\n--- Session Details ---');
  print('Session ID: ${details.sessionId}');
  print('VIN: ${details.vin}');
  print('Location: ${details.siteLocationName}');
  if (details.location != null) {
    print('Coordinates: ${details.location!.latitude}, '
        '${details.location!.longitude}');
  }
  print('Start: ${details.chargeStartDateTime}');
  print('Stop: ${details.chargeStopDateTime}');
  print('SOC: ${details.chargeStartSoc}% -> ${details.chargeStopSoc}%');
  print('Ideal range: ${details.chargeStartIdealRange} -> '
      '${details.chargeStopIdealRange}');
  print('Rated range: ${details.chargeStartRatedRange} -> '
      '${details.chargeStopRatedRange}');
  print('Energy used: ${details.energyUsed} kWh');
  print('Cost: \$${details.chargeCost}');
  print('Connector: ${details.connectorType}');
  print('Vehicle type: ${details.vehicleMakeType}');
}

/// Downloads a charging invoice for a specific session.
Future<void> downloadChargingInvoice(
    TeslaFleetClient client, String? vin) async {
  final sessions = await client.charging.getChargingHistory(
    vin: vin,
    limit: 5,
  );

  if (sessions.isEmpty) {
    print('No charging sessions available.');
    return;
  }

  print('\n--- Recent Sessions ---');
  for (var i = 0; i < sessions.length; i++) {
    print('${i + 1}. ${sessions[i].sessionId} '
        '- \$${sessions[i].chargeCost ?? 0} '
        '(${sessions[i].chargeStartDateTime})');
  }

  stdout.write('Enter session number (1-${sessions.length}): ');
  final input = stdin.readLineSync();
  final index = (int.tryParse(input ?? '') ?? 1) - 1;

  if (index < 0 || index >= sessions.length) {
    print('Invalid selection');
    return;
  }

  final sessionId = sessions[index].sessionId;
  if (sessionId == null) {
    print('Session ID not available');
    return;
  }

  print('\nFetching invoice for session: $sessionId...');
  final invoice = await client.charging.getChargingInvoice(sessionId);

  print('\n--- Invoice ---');
  print('File name: ${invoice.fileName}');
  print('Invoice type: ${invoice.invoiceType}');
  print('Content type: ${invoice.contentType}');

  if (invoice.content != null && invoice.fileName != null) {
    // Save the invoice to a file (Base64 decoded)
    final bytes = base64Decode(invoice.content!);
    final file = File(invoice.fileName!);
    await file.writeAsBytes(bytes);
    print('Invoice saved to: ${file.path}');
  } else {
    print('No invoice content available for this session.');
  }
}
