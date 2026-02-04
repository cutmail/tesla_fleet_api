/// Demonstrates energy product management using the Tesla Fleet API.
///
/// This example shows how to:
/// - List energy products (Solar, Powerwall)
/// - Read live energy status (solar, battery, grid, load power)
/// - Retrieve energy history over a time range
/// - Set backup reserve percentage
/// - Change operation mode (self-powered, time-based control, backup)
/// - Enable/disable storm mode
///
/// Required scopes: energy_device_data, energy_cmds
///
/// Usage:
///   dart run example/energy_management.dart
import 'dart:io';
import 'package:tesla_fleet_api/tesla_fleet_api.dart';

void main() async {
  print('=== Energy Management Demo ===\n');

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
      'energy_device_data',
      'energy_cmds',
    ],
    state: 'energy-${DateTime.now().millisecondsSinceEpoch}',
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
    // List energy products
    print('\n--- Energy Products ---');
    final products = await client.energy.list();

    if (products.isEmpty) {
      print('No energy products found.');
      print('Energy products include Solar panels, Powerwall, etc.');
      print('These must be registered in your Tesla account.');
      return;
    }

    print('Found ${products.length} energy product(s):\n');
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      print('${i + 1}. ${p.siteName ?? "Unnamed site"}');
      print('   Energy Site ID: ${p.energySiteId}');
      print('   Resource Type: ${p.resourceType}');
      print('   Gateway ID: ${p.gatewayId}');
      if (p.components != null && p.components!.isNotEmpty) {
        print('   Components: ${p.components!.join(", ")}');
      }
    }

    // Select an energy product
    int selectedIndex = 0;
    if (products.length > 1) {
      stdout.write('\nSelect product (1-${products.length}): ');
      final input = stdin.readLineSync();
      selectedIndex = (int.tryParse(input ?? '') ?? 1) - 1;
      selectedIndex = selectedIndex.clamp(0, products.length - 1);
    }

    final product = products[selectedIndex];
    final siteId = product.energySiteId;
    if (siteId == null) {
      print('Energy Site ID is null, cannot continue.');
      return;
    }

    print('\nSelected: ${product.siteName ?? "Site"} (ID: $siteId)');

    // Show live status
    await showLiveStatus(client, siteId);

    // Energy management menu
    while (true) {
      print('\n--- Energy Management Menu ---');
      print('1. Refresh live status');
      print('2. View energy history (last 7 days)');
      print('3. View energy history (last 30 days)');
      print('4. Set backup reserve percentage');
      print('5. Set operation mode');
      print('6. Toggle storm mode');
      print('7. Exit');
      stdout.write('Enter choice (1-7): ');

      final choice = stdin.readLineSync();
      switch (choice) {
        case '1':
          await showLiveStatus(client, siteId);
          break;

        case '2':
          await showEnergyHistory(client, siteId, days: 7);
          break;

        case '3':
          await showEnergyHistory(client, siteId, days: 30);
          break;

        case '4':
          await setBackupReserve(client, siteId);
          break;

        case '5':
          await setOperationMode(client, siteId);
          break;

        case '6':
          await toggleStormMode(client, siteId);
          break;

        case '7':
          print('Exiting.');
          return;

        default:
          print('Invalid choice');
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

/// Displays the live energy status for a site.
Future<void> showLiveStatus(TeslaFleetClient client, int siteId) async {
  print('\n--- Live Energy Status ---');
  final status = await client.energy.getLiveStatus(siteId);

  print('Solar power:     ${_formatPower(status.solarPower)}');
  print('Battery power:   ${_formatPower(status.batteryPower)}');
  print('Grid power:      ${_formatPower(status.gridPower)}');
  print('Home load:       ${_formatPower(status.loadPower)}');
  print('Battery level:   ${status.percentageCharged?.toStringAsFixed(1) ?? "N/A"}%');
  print('Energy left:     ${status.energyLeft?.toStringAsFixed(1) ?? "N/A"} Wh');
  print('Total pack:      ${status.totalPackEnergy?.toStringAsFixed(1) ?? "N/A"} Wh');
  print('Grid status:     ${status.gridStatus}');
  print('Island status:   ${status.islandStatus ?? "N/A"}');
  print('Storm mode:      ${status.stormModeActive ?? "N/A"}');
  print('Grid services:   ${status.gridServicesActive ?? "N/A"}');
  print('Timestamp:       ${status.timestamp ?? "N/A"}');

  // Power flow summary
  print('\nPower flow summary:');
  final solar = status.solarPower ?? 0;
  final battery = status.batteryPower ?? 0;
  final grid = status.gridPower ?? 0;
  final load = status.loadPower ?? 0;

  if (solar > 0) print('  Solar is generating ${_formatPower(solar)}');
  if (battery > 0) {
    print('  Battery is discharging ${_formatPower(battery)}');
  } else if (battery < 0) {
    print('  Battery is charging ${_formatPower(battery.abs())}');
  }
  if (grid > 0) {
    print('  Importing ${_formatPower(grid)} from grid');
  } else if (grid < 0) {
    print('  Exporting ${_formatPower(grid.abs())} to grid');
  }
  if (load > 0) print('  Home is consuming ${_formatPower(load)}');
}

/// Retrieves and displays energy history.
Future<void> showEnergyHistory(TeslaFleetClient client, int siteId,
    {required int days}) async {
  print('\n--- Energy History (last $days days) ---');

  final history = await client.energy.getHistory(
    siteId,
    period: 'day',
    startDate: DateTime.now().subtract(Duration(days: days)),
    endDate: DateTime.now(),
  );

  final entries = history.timeSeries;
  if (entries == null || entries.isEmpty) {
    print('No history data available.');
    return;
  }

  print('Period: ${history.period}');
  print('Entries: ${entries.length}\n');

  var totalSolar = 0.0;
  var totalGridImport = 0.0;
  var totalGridExport = 0.0;
  var totalBatteryImport = 0.0;
  var totalBatteryExport = 0.0;
  var totalConsumption = 0.0;

  for (final entry in entries) {
    final date = entry.timestamp?.split('T').first ?? 'Unknown';
    final solar = entry.solarEnergyExported ?? 0;
    final gridIn = entry.gridEnergyImported ?? 0;
    final gridOut = entry.gridEnergyExported ?? 0;
    final battIn = entry.batteryEnergyImported ?? 0;
    final battOut = entry.batteryEnergyExported ?? 0;
    final consumed = entry.consumerEnergyImported ?? 0;

    print('$date:');
    print('  Solar: ${_formatEnergy(solar)} | '
        'Grid in: ${_formatEnergy(gridIn)} | '
        'Grid out: ${_formatEnergy(gridOut)}');
    print('  Battery in: ${_formatEnergy(battIn)} | '
        'Battery out: ${_formatEnergy(battOut)} | '
        'Consumed: ${_formatEnergy(consumed)}');

    totalSolar += solar;
    totalGridImport += gridIn;
    totalGridExport += gridOut;
    totalBatteryImport += battIn;
    totalBatteryExport += battOut;
    totalConsumption += consumed;
  }

  print('\n--- Totals ---');
  print('Solar produced:   ${_formatEnergy(totalSolar)}');
  print('Grid imported:    ${_formatEnergy(totalGridImport)}');
  print('Grid exported:    ${_formatEnergy(totalGridExport)}');
  print('Battery charged:  ${_formatEnergy(totalBatteryImport)}');
  print('Battery used:     ${_formatEnergy(totalBatteryExport)}');
  print('Total consumed:   ${_formatEnergy(totalConsumption)}');

  if (totalConsumption > 0) {
    final selfSufficiency =
        ((totalSolar - totalGridExport) / totalConsumption * 100)
            .clamp(0, 100);
    print(
        'Self-sufficiency:  ${selfSufficiency.toStringAsFixed(1)}%');
  }
}

/// Sets the backup reserve percentage on a Powerwall.
Future<void> setBackupReserve(TeslaFleetClient client, int siteId) async {
  stdout.write('\nEnter backup reserve percentage (0-100): ');
  final input = stdin.readLineSync();
  final percent = int.tryParse(input ?? '') ?? 20;
  final clamped = percent.clamp(0, 100);

  print('Setting backup reserve to $clamped%...');
  final result = await client.energy.setBackupReservePercent(siteId, clamped);
  print('Result: ${result.result}');
  if (result.reason != null) {
    print('Reason: ${result.reason}');
  }
}

/// Sets the energy site operation mode.
Future<void> setOperationMode(TeslaFleetClient client, int siteId) async {
  print('\nAvailable operation modes:');
  print('1. self_consumption - Maximize self-powered usage');
  print('2. autonomous      - Time-based control');
  print('3. backup          - Backup only');
  stdout.write('Enter choice (1-3): ');

  final choice = stdin.readLineSync();
  String mode;
  switch (choice) {
    case '1':
      mode = 'self_consumption';
      break;
    case '2':
      mode = 'autonomous';
      break;
    case '3':
      mode = 'backup';
      break;
    default:
      print('Invalid choice');
      return;
  }

  print('Setting operation mode to "$mode"...');
  final result = await client.energy.setOperationMode(siteId, mode);
  print('Result: ${result.result}');
  if (result.reason != null) {
    print('Reason: ${result.reason}');
  }
}

/// Toggles storm mode on or off.
Future<void> toggleStormMode(TeslaFleetClient client, int siteId) async {
  // Check current status first
  final status = await client.energy.getLiveStatus(siteId);
  final currentlyActive = status.stormModeActive == 'true';

  print('\nStorm mode is currently: ${currentlyActive ? "ON" : "OFF"}');
  final newState = !currentlyActive;
  stdout.write('${newState ? "Enable" : "Disable"} storm mode? (y/n): ');

  final confirm = stdin.readLineSync();
  if (confirm?.toLowerCase() != 'y') {
    print('Cancelled.');
    return;
  }

  print('${newState ? "Enabling" : "Disabling"} storm mode...');
  final result = await client.energy.enableStormMode(siteId, newState);
  print('Result: ${result.result}');
  if (result.reason != null) {
    print('Reason: ${result.reason}');
  }
}

/// Formats a power value in watts to a human-readable string.
String _formatPower(double? watts) {
  if (watts == null) return 'N/A';
  if (watts.abs() >= 1000) {
    return '${(watts / 1000).toStringAsFixed(2)} kW';
  }
  return '${watts.toStringAsFixed(0)} W';
}

/// Formats an energy value in watt-hours to a human-readable string.
String _formatEnergy(double wh) {
  if (wh.abs() >= 1000) {
    return '${(wh / 1000).toStringAsFixed(2)} kWh';
  }
  return '${wh.toStringAsFixed(0)} Wh';
}
