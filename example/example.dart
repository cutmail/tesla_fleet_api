import 'dart:io';
import 'package:tesla_fleet_api/tesla_fleet_api.dart';

void main() async {
  print('=== Tesla Fleet API Example ===\n');
  print('Choose authentication method:');
  print('1. Client Credentials Flow (for business/testing)');
  print('2. Authorization Code Flow (for accessing personal vehicles)');
  stdout.write('Enter your choice (1 or 2): ');

  final choice = stdin.readLineSync();

  if (choice == '2') {
    await runAuthorizationCodeFlow();
  } else {
    await runClientCredentialsFlow();
  }
}

Future<void> runAuthorizationCodeFlow() async {
  print('\n=== Authorization Code Flow ===');
  print('This flow allows access to personal Tesla vehicles.\n');

  print('Choose scope for authorization:');
  print('1. Read-Only Access (vehicle data, energy data, user info)');
  print('2. Vehicle Control Access (includes read + vehicle commands)');
  print('3. Full Access (includes all scopes)');
  stdout.write('Enter your choice (1, 2, or 3): ');

  final scopeChoice = stdin.readLineSync();

  List<String> selectedScopes;
  String scopeDescription;

  switch (scopeChoice) {
    case '1':
      selectedScopes = [
        'openid',
        'offline_access',
        'user_data',
        'vehicle_device_data',
        'energy_device_data',
      ];
      scopeDescription = 'Read-Only Access';
      break;
    case '2':
      selectedScopes = [
        'openid',
        'offline_access',
        'user_data',
        'vehicle_device_data',
        'vehicle_cmds',
        'vehicle_charging_cmds',
      ];
      scopeDescription = 'Vehicle Control Access';
      break;
    case '3':
      selectedScopes = [
        'openid',
        'offline_access',
        'user_data',
        'vehicle_device_data',
        'vehicle_cmds',
        'vehicle_charging_cmds',
        'energy_device_data',
        'energy_cmds',
      ];
      scopeDescription = 'Full Access';
      break;
    default:
      selectedScopes = [
        'openid',
        'offline_access',
        'user_data',
        'vehicle_device_data',
      ];
      scopeDescription = 'Basic Read-Only Access';
      break;
  }

  // Initialize authentication with redirect URI
  // Replace with your actual credentials from Tesla Developer Portal
  final auth = TeslaAuth(
    clientId: 'YOUR_CLIENT_ID_HERE',
    clientSecret: 'YOUR_CLIENT_SECRET_HERE',
    privateKey: '',
    redirectUri: 'YOUR_REDIRECT_URI_HERE',
  );

  // Generate authorization URL
  final authUrl = auth.generateAuthorizationUrl(
    scopes: selectedScopes,
    state: 'example-state-${DateTime.now().millisecondsSinceEpoch}',
  );

  print('\n🔐 Selected: $scopeDescription');
  print('📝 Scopes: ${selectedScopes.join(', ')}');
  print('\n🔗 Please visit this URL to authorize:');
  print(authUrl);
  print('\n📋 After authorization, copy the code from the redirect URL:');
  stdout.write('Enter authorization code: ');

  final code = stdin.readLineSync();
  if (code == null || code.trim().isEmpty) {
    print('❌ No code provided');
    return;
  }

  try {
    await auth.exchangeAuthorizationCode(code.trim());
    await runApiTests(TeslaFleetClient(auth: auth), selectedScopes);
  } catch (e) {
    print('❌ Authorization failed: $e');
  }
}

Future<void> runClientCredentialsFlow() async {
  print('\n=== Client Credentials Flow ===');
  print('This flow is for business applications (limited access).\n');

  // Initialize authentication
  // Replace with your actual credentials from Tesla Developer Portal
  final auth = TeslaAuth(
    clientId: 'YOUR_CLIENT_ID_HERE',
    clientSecret: 'YOUR_CLIENT_SECRET_HERE',
    privateKey: '', // Not used with client_credentials flow
  );

  try {
    // Client credentials flow has very limited scopes
    // Typically only vehicle_device_data is available
    await runApiTests(TeslaFleetClient(auth: auth), ['vehicle_device_data']);
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> runApiTests(TeslaFleetClient client, List<String> scopes) async {
  print('\n=== Available Tests Based on Scopes ===');
  print('📝 Your scopes: ${scopes.join(', ')}');

  // Check what tests are available based on scopes
  final hasVehicleData = scopes.contains('vehicle_device_data');
  final hasVehicleControl = scopes.contains('vehicle_cmds') ||
      scopes.contains('vehicle_charging_cmds');
  final hasEnergyData = scopes.contains('energy_device_data');
  final hasEnergyControl = scopes.contains('energy_cmds');
  final hasUserData = scopes.contains('user_data');

  print('\n✅ Available tests:');
  if (hasVehicleData) print('   • Vehicle Data Retrieval');
  if (hasVehicleControl) print('   • Vehicle Control Commands');
  if (hasEnergyData) print('   • Energy Data Retrieval');
  if (hasEnergyControl) print('   • Energy Control Commands');
  if (hasUserData) print('   • User Info');

  print('\n❌ Unavailable tests:');
  if (!hasVehicleData)
    print('   • Vehicle Data Retrieval (missing vehicle_device_data scope)');
  if (!hasVehicleControl)
    print(
        '   • Vehicle Control Commands (missing vehicle_cmds/vehicle_charging_cmds scope)');
  if (!hasEnergyData)
    print('   • Energy Data Retrieval (missing energy_device_data scope)');
  if (!hasEnergyControl)
    print('   • Energy Control Commands (missing energy_cmds scope)');
  if (!hasUserData) print('   • User Info (missing user_data scope)');

  print('\nChoose test type:');
  print('1. Safe Data Retrieval Only (read-only operations)');
  if (hasVehicleControl) {
    print(
        '2. Vehicle Control Commands (⚠️  CAUTION: will affect your vehicle)');
  } else {
    print('2. Vehicle Control Commands (❌ UNAVAILABLE - insufficient scopes)');
  }
  stdout.write('Enter your choice (1 or 2): ');

  final testChoice = stdin.readLineSync();

  if (testChoice == '2') {
    if (!hasVehicleControl) {
      print(
          '❌ Vehicle control commands are not available with your current scopes');
      print('💡 You need vehicle_cmds and/or vehicle_charging_cmds scopes');
      await runSafeDataTests(client, scopes);
      return;
    }

    print('\n⚠️  WARNING: You are about to test vehicle control commands!');
    print(
        '⚠️  This may cause your vehicle to flash lights, honk, or start climate control.');
    stdout.write('Are you sure? Type "YES" to continue: ');

    final confirmation = stdin.readLineSync();
    if (confirmation != 'YES') {
      print('❌ Vehicle control test cancelled for safety.');
      await runSafeDataTests(client, scopes);
      return;
    }

    await runVehicleControlTests(client, scopes);
  } else {
    await runSafeDataTests(client, scopes);
  }
}

Future<void> runSafeDataTests(
    TeslaFleetClient client, List<String> scopes) async {
  try {
    print('\n=== SAFE DATA RETRIEVAL TESTS ===');
    print('(Read-only operations - no vehicle control)\n');

    // Example 1: List all vehicles (requires vehicle_device_data scope)
    if (!scopes.contains('vehicle_device_data')) {
      print('❌ Vehicle tests skipped (missing vehicle_device_data scope)');
      return;
    }

    print('=== Listing Vehicles ===');

    List<Vehicle> vehicles = [];
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        vehicles = await client.vehicles.list();
        print('Found ${vehicles.length} vehicles');
        break; // Success, exit retry loop
      } catch (e) {
        retryCount++;
        if (e.toString().contains('412')) {
          print(
              '❌ Vehicle list unavailable (HTTP 412) - Attempt $retryCount/$maxRetries');

          // Check if it's a registration issue
          if (e
              .toString()
              .contains('must be registered in the current region')) {
            print(
                '🌍 REGISTRATION REQUIRED: Account not registered in current region');
            print('🔄 Attempting automatic partner account registration...');

            try {
              await client.partner.registerPartner('undersoil.co.jp');
              print('✅ Partner account registration successful!');
              print('⏳ Waiting 30 seconds for registration to propagate...');
              await Future.delayed(Duration(seconds: 30));

              // Try once more after registration
              print('🔄 Retrying vehicle list after registration...');
              continue; // This will retry the vehicle list
            } catch (regError) {
              print('❌ Automatic registration failed: $regError');
              print('📋 Manual registration required:');
              print('   1. Visit Tesla Developer Portal');
              print('   2. Register your application for this region');
              print('   3. Wait 10-15 minutes after registration');
              print('   4. Try again');
              throw e;
            }
          }

          if (retryCount < maxRetries) {
            print('⏳ Waiting 10 seconds before retry...');
            await Future.delayed(Duration(seconds: 10));
            print('🔄 Retrying vehicle list...');
          } else {
            print('❌ Failed to get vehicle list after $maxRetries attempts');
            print('💡 Possible solutions:');
            print('   • Open Tesla mobile app and check vehicle connectivity');
            print(
                '   • Wait for vehicle to wake up naturally (someone uses it)');
            print('   • Try again in 15-30 minutes');
            throw e; // Re-throw to trigger catch block
          }
        } else {
          throw e; // Re-throw non-412 errors immediately
        }
      }
    }

    if (vehicles.isNotEmpty) {
      final vehicle = vehicles.first;
      print('Vehicle: ${vehicle.displayName} (${vehicle.vin})');
      print('State: ${vehicle.state}');
      print('Vehicle ID: ${vehicle.id}');

      // Check if vehicle needs to be woken up
      print('\n=== Checking Vehicle State ===');
      print('Vehicle state: ${vehicle.state}');

      // If vehicle is asleep, try to wake it up first (this is safe)
      if (vehicle.state == 'asleep' || vehicle.state == 'offline') {
        print('\n=== Waking Up Vehicle (Safe - required for data access) ===');
        try {
          final wakeResponse =
              await client.vehicles.wakeUp(vehicle.id.toString());
          print('Wake up result: ${wakeResponse.result}');

          if (wakeResponse.result == true) {
            print('Waiting 5 seconds for vehicle to wake up...');
            await Future.delayed(Duration(seconds: 5));
          }
        } catch (e) {
          print('⚠️  Could not wake up vehicle: $e');
          print('⚠️  Some data may not be available');
        }
      }

      // Example 2: Get vehicle data (safe - read-only)
      print('\n=== Getting Vehicle Data (Safe) ===');
      try {
        final vehicleData =
            await client.vehicles.getVehicleData(vehicle.id.toString());

        // Battery information
        if (vehicleData.chargeState != null) {
          print('🔋 Battery level: ${vehicleData.chargeState!.batteryLevel}%');
          print('🔋 Range: ${vehicleData.chargeState!.batteryRange} miles');
          print('🔋 Charging state: ${vehicleData.chargeState!.chargingState}');
          print('🔋 Charge limit: ${vehicleData.chargeState!.chargeLimitSoc}%');
        }

        // Location information
        if (vehicleData.driveState != null) {
          print(
              '📍 Location: ${vehicleData.driveState!.latitude}, ${vehicleData.driveState!.longitude}');
          print('📍 Speed: ${vehicleData.driveState!.speed ?? 0} mph');
          print('📍 Gear: ${vehicleData.driveState!.shiftState ?? 'Unknown'}');
        }

        // Climate information
        if (vehicleData.climateState != null) {
          print('🌡️  Inside temp: ${vehicleData.climateState!.insideTemp}°C');
          print(
              '🌡️  Outside temp: ${vehicleData.climateState!.outsideTemp}°C');
          print(
              '🌡️  Driver temp setting: ${vehicleData.climateState!.driverTempSetting}°C');
          print('🌡️  Climate on: ${vehicleData.climateState!.isClimateOn}');
        }

        // Vehicle state information
        if (vehicleData.vehicleState != null) {
          print('🚗 Odometer: ${vehicleData.vehicleState!.odometer} miles');
          print('🚗 Software version: ${vehicleData.vehicleState!.carVersion}');
          print('🚗 Locked: ${vehicleData.vehicleState!.locked}');
          print('🚗 Valet mode: ${vehicleData.vehicleState!.valetMode}');
          print('🚗 User present: ${vehicleData.vehicleState!.isUserPresent}');
        }
      } catch (e) {
        if (e.toString().contains('412')) {
          print('❌ Vehicle data unavailable (HTTP 412)');
          print('💡 This usually means:');
          print('   • Vehicle is asleep/offline and needs to be woken up');
          print('   • Vehicle is not ready to respond to commands');
          print('   • Network connectivity issues');
          print('⚠️  Try waking up the vehicle first, then retry');
        } else {
          print('❌ Could not get vehicle data: $e');
        }
      }
    }

    // Safe energy and charging data (scope-dependent)
    if (scopes.contains('energy_device_data')) {
      await runSafeEnergyTests(client);
    } else {
      print('\n❌ Energy tests skipped (missing energy_device_data scope)');
    }

    if (scopes.contains('vehicle_charging_cmds')) {
      await runSafeChargingHistoryTests(client);
    } else {
      print(
          '\n❌ Charging history tests skipped (missing vehicle_charging_cmds scope)');
    }

    if (scopes.contains('user_data')) {
      await runSafeUserInfoTests(client);
    } else {
      print('\n❌ User info tests skipped (missing user_data scope)');
    }
  } catch (e) {
    if (e.toString().contains('412')) {
      if (e.toString().contains('must be registered in the current region')) {
        print('❌ ACCOUNT NOT REGISTERED');
        print('🌍 Your Tesla account must be registered for Fleet API access');
        print('🔧 Quick fix:');
        print('   dart run example/register_partner.dart');
        print('💡 Or visit Tesla Developer Portal to register manually');
      } else {
        print('❌ API request failed (HTTP 412)');
        print('💡 This usually means:');
        print('   • Vehicle is in deep sleep mode');
        print('   • Tesla servers are temporarily unavailable');
        print('   • Rate limiting or API restrictions');
        print('🔄 Suggestion: Try again in a few minutes');
      }
    } else if (e.toString().contains('403')) {
      print('❌ Access forbidden (HTTP 403)');
      print('💡 This usually means:');
      print('   • Insufficient permissions/scopes');
      print('   • Token has expired');
      print('   • Application not properly authorized');
    } else {
      print('❌ Error in safe data tests: $e');
    }
  } finally {
    client.dispose();
  }
}

Future<void> runVehicleControlTests(
    TeslaFleetClient client, List<String> scopes) async {
  try {
    print('\n=== ⚠️  VEHICLE CONTROL TESTS ===');
    print('(These commands will affect your vehicle!)\n');

    // Get vehicles first
    final vehicles = await client.vehicles.list();
    if (vehicles.isEmpty) {
      print('❌ No vehicles found for control tests');
      return;
    }

    final vehicle = vehicles.first;
    print('Controlling vehicle: ${vehicle.displayName} (${vehicle.vin})\n');

    // Wake up vehicle first (necessary for most commands)
    print('=== Waking Up Vehicle ===');
    try {
      final wakeResponse = await client.vehicles.wakeUp(vehicle.id.toString());
      print('Wake up result: ${wakeResponse.result}');

      // Wait a moment for the vehicle to wake up
      print('Waiting 3 seconds for vehicle to wake up...');
      await Future.delayed(Duration(seconds: 3));
    } catch (e) {
      print('❌ Could not wake up vehicle: $e');
      return;
    }

    // Vehicle visual/audio commands (requires vehicle_cmds scope)
    if (scopes.contains('vehicle_cmds')) {
      print('\n=== Vehicle Visual/Audio Commands ===');

      try {
        // Flash lights
        print('Flashing lights...');
        final flashResponse =
            await client.vehicles.flashLights(vehicle.id.toString());
        print('💡 Flash lights result: ${flashResponse.result}');
        await Future.delayed(Duration(seconds: 2));

        // Honk horn
        print('Honking horn...');
        final honkResponse =
            await client.vehicles.honkHorn(vehicle.id.toString());
        print('📯 Honk horn result: ${honkResponse.result}');
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        print('❌ Visual/audio commands failed: $e');
      }
    } else {
      print(
          '\n❌ Vehicle visual/audio commands skipped (missing vehicle_cmds scope)');
    }

    // Climate control commands (requires vehicle_cmds scope)
    if (scopes.contains('vehicle_cmds')) {
      print('\n=== Climate Control Commands ===');

      try {
        // Start climate control
        print('Starting climate control...');
        final climateResponse =
            await client.vehicles.startClimate(vehicle.id.toString());
        print('🌡️  Start climate result: ${climateResponse.result}');
        await Future.delayed(Duration(seconds: 2));

        // Set temperature
        print('Setting temperature to 22°C...');
        final tempResponse = await client.vehicles
            .setTemperature(vehicle.id.toString(), 22.0, 22.0);
        print('🌡️  Set temperature result: ${tempResponse.result}');
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        print('❌ Climate control commands failed: $e');
      }
    } else {
      print(
          '\n❌ Climate control commands skipped (missing vehicle_cmds scope)');
    }

    // Charging commands (requires vehicle_charging_cmds scope)
    if (scopes.contains('vehicle_charging_cmds')) {
      print('\n=== Charging Commands ===');

      try {
        // Open charge port
        print('Opening charge port...');
        final openPortResponse =
            await client.vehicles.openChargePort(vehicle.id.toString());
        print('🔌 Open charge port result: ${openPortResponse.result}');
        await Future.delayed(Duration(seconds: 2));

        // Set charge limit
        print('Setting charge limit to 80%...');
        final chargeLimitResponse =
            await client.vehicles.setChargeLimit(vehicle.id.toString(), 80);
        print('🔋 Set charge limit result: ${chargeLimitResponse.result}');
      } catch (e) {
        print('❌ Charging commands failed: $e');
      }
    } else {
      print(
          '\n❌ Charging commands skipped (missing vehicle_charging_cmds scope)');
    }

    print('\n✅ Vehicle control tests completed!');
  } catch (e) {
    print('❌ Error in vehicle control tests: $e');
  } finally {
    client.dispose();
  }
}

Future<void> runSafeEnergyTests(TeslaFleetClient client) async {
  try {
    print('\n=== Energy Products (Safe) ===');
    final energyProducts = await client.energy.list();

    if (energyProducts.isEmpty) {
      print('ℹ️  No energy products found (Solar panels, Powerwall, etc.)');
      print(
          '💡 Energy products need to be registered separately in Tesla account');
      return;
    }

    print('Found ${energyProducts.length} energy products');

    for (final product in energyProducts) {
      print('Energy product: ${product.siteName ?? 'Unknown'}');
      print('  Energy Site ID: ${product.energySiteId}');
      print('  Resource Type: ${product.resourceType}');

      if (product.energySiteId == null) {
        print('  ⚠️  Energy Site ID is null, skipping detailed data');
        continue;
      }

      try {
        // Get live status (safe - read-only)
        final liveStatus =
            await client.energy.getLiveStatus(product.energySiteId!);
        print('  ⚡ Solar power: ${liveStatus.solarPower}W');
        print('  🔋 Battery power: ${liveStatus.batteryPower}W');
        print('  🏠 Grid power: ${liveStatus.gridPower}W');
        print('  📊 Battery level: ${liveStatus.percentageCharged}%');

        // Get energy history (safe - read-only)
        final history = await client.energy.getHistory(
          product.energySiteId!,
          period: 'day',
          startDate: DateTime.now().subtract(Duration(days: 7)),
          endDate: DateTime.now(),
        );
        print(
            '  📈 Energy history entries: ${history.timeSeries?.length ?? 0}');
      } catch (e) {
        print('  ❌ Could not get energy data: $e');
      }
    }
  } catch (e) {
    print('❌ Energy products test failed: $e');
  }
}

Future<void> runSafeChargingHistoryTests(TeslaFleetClient client) async {
  try {
    print('\n=== Charging History (Safe) ===');
    final vehicles = await client.vehicles.list();

    if (vehicles.isNotEmpty) {
      final chargingSessions = await client.charging.getChargingHistory(
        vin: vehicles.first.vin,
        limit: 10,
      );
      print('Found ${chargingSessions.length} charging sessions');

      if (chargingSessions.isNotEmpty) {
        for (final session in chargingSessions.take(3)) {
          // Show only first 3 for brevity
          print('  🔌 Session: ${session.sessionId}');
          print('  📍 Location: ${session.siteLocationName}');
          print('  ⚡ Energy used: ${session.energyUsed} kWh');
          print('  💰 Cost: \$${session.chargeCost}');
          print('');
        }
      }
    }
  } catch (e) {
    print('❌ Charging history test failed: $e');
  }
}

Future<void> runSafeUserInfoTests(TeslaFleetClient client) async {
  try {
    print('\n=== User Info (Safe) ===');
    final user = await client.partner.getMe();
    print('👤 User: ${user.fullName} (${user.email})');
  } catch (e) {
    if (e.toString().contains('403') &&
        e.toString().contains('missing scopes')) {
      print('❌ User info unavailable: Missing user_data scope');
      print('💡 This is normal for Client Credentials flow');
      print('💡 Use Authorization Code flow to access user information');
    } else {
      print('❌ User info test failed: $e');
    }
  }
}
