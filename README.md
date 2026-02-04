# Tesla Fleet API - Dart Package

A comprehensive Dart package for interacting with the Tesla Fleet API. This package provides easy-to-use interfaces for managing Tesla vehicles, energy products, charging sessions, and partner accounts with built-in support for multiple authentication flows and regions.

## Features

- **Vehicle Management**: Complete vehicle control and monitoring
- **Energy Products**: Manage Tesla energy products (Powerwall, Solar)
- **Charging History**: Access detailed charging session data and invoices
- **Partner Integration**: Partner account management and registration
- **Multi-Region Support**: North America/Asia-Pacific, Europe/Middle East/Africa, and China
- **Authentication**: OAuth 2.0 Authorization Code and Client Credentials flows
- **Error Handling**: Comprehensive exception handling with detailed error types
- **Rate Limiting**: Automatic rate limit handling with retry logic
- **Interactive Example**: Full-featured example with scope selection and safety features

## Installation

Add this package to your `pubspec.yaml` file:

```yaml
dependencies:
  tesla_fleet_api: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Quick Start

### 1. Authentication Setup

First, create a Tesla developer account and set up your application at [developer.tesla.com](https://developer.tesla.com).

#### Authorization Code Flow (for personal vehicle access)
```dart
import 'package:tesla_fleet_api/tesla_fleet_api.dart';

// Initialize authentication with redirect URI
final auth = TeslaAuth(
  clientId: 'YOUR_CLIENT_ID_HERE',
  clientSecret: 'YOUR_CLIENT_SECRET_HERE',
  privateKey: '', // Optional for Authorization Code flow
  redirectUri: 'YOUR_REDIRECT_URI_HERE',
  region: 'northAmericaAsiaPacific', // or 'europeMiddleEastAfrica', 'china'
);

// Generate authorization URL
final authUrl = auth.generateAuthorizationUrl(
  scopes: ['openid', 'offline_access', 'vehicle_device_data', 'vehicle_cmds'],
  state: 'your-state-string',
);

// User visits authUrl and gets authorization code
// Exchange code for tokens
await auth.exchangeAuthorizationCode('authorization-code-from-redirect');

// Create the client
final client = TeslaFleetClient(auth: auth);
```

#### Client Credentials Flow (for business applications)
```dart
// Initialize authentication for client credentials flow
final auth = TeslaAuth(
  clientId: 'YOUR_CLIENT_ID_HERE',
  clientSecret: 'YOUR_CLIENT_SECRET_HERE',
  privateKey: '', // Not used with client credentials
  region: 'northAmericaAsiaPacific',
);

// Create the client (authentication happens automatically)
final client = TeslaFleetClient(auth: auth);
```

### 2. Vehicle Operations

```dart
// List all vehicles
final vehicles = await client.vehicles.list();
print('Found ${vehicles.length} vehicles');

if (vehicles.isNotEmpty) {
  final vehicle = vehicles.first;
  final vehicleId = vehicle.id.toString();
  
  // Wake up vehicle if needed
  if (vehicle.state == 'asleep' || vehicle.state == 'offline') {
    await client.vehicles.wakeUp(vehicleId);
    await Future.delayed(Duration(seconds: 5)); // Wait for wake up
  }
  
  // Get comprehensive vehicle data
  final vehicleData = await client.vehicles.getVehicleData(vehicleId);
  
  // Battery information
  if (vehicleData.chargeState != null) {
    print('Battery level: ${vehicleData.chargeState!.batteryLevel}%');
    print('Range: ${vehicleData.chargeState!.batteryRange} miles');
    print('Charging state: ${vehicleData.chargeState!.chargingState}');
  }
  
  // Location information
  if (vehicleData.driveState != null) {
    print('Location: ${vehicleData.driveState!.latitude}, ${vehicleData.driveState!.longitude}');
    print('Speed: ${vehicleData.driveState!.speed ?? 0} mph');
  }
  
  // Climate information
  if (vehicleData.climateState != null) {
    print('Inside temp: ${vehicleData.climateState!.insideTemp}°C');
    print('Climate on: ${vehicleData.climateState!.isClimateOn}');
  }
  
  // Vehicle control (requires appropriate scopes)
  await client.vehicles.flashLights(vehicleId);
  await client.vehicles.honkHorn(vehicleId);
  await client.vehicles.startClimate(vehicleId);
  await client.vehicles.setTemperature(vehicleId, 22.0, 22.0);
}
```

### 3. Charging Operations

```dart
// Charging control (requires vehicle_charging_cmds scope)
await client.vehicles.openChargePort(vehicleId);
await client.vehicles.startCharging(vehicleId);
await client.vehicles.stopCharging(vehicleId);
await client.vehicles.setChargeLimit(vehicleId, 80);
await client.vehicles.closeChargePort(vehicleId);

// Get charging history (requires vehicle_charging_cmds scope)
final chargingSessions = await client.charging.getChargingHistory(
  vin: vehicles.first.vin,
  limit: 10,
);

for (final session in chargingSessions) {
  print('Session: ${session.sessionId}');
  print('Location: ${session.siteLocationName}');
  print('Energy used: ${session.energyUsed} kWh');
  print('Cost: \$${session.chargeCost}');
}
```

### 4. Energy Products

```dart
// List energy products (requires energy_device_data scope)
final energyProducts = await client.energy.list();

if (energyProducts.isNotEmpty) {
  final product = energyProducts.first;
  final energySiteId = product.energySiteId!;
  
  print('Energy product: ${product.siteName}');
  print('Resource type: ${product.resourceType}');
  
  // Get live status
  final liveStatus = await client.energy.getLiveStatus(energySiteId);
  print('Solar power: ${liveStatus.solarPower}W');
  print('Battery power: ${liveStatus.batteryPower}W');
  print('Grid power: ${liveStatus.gridPower}W');
  print('Battery level: ${liveStatus.percentageCharged}%');
  
  // Get energy history
  final history = await client.energy.getHistory(
    energySiteId,
    period: 'day',
    startDate: DateTime.now().subtract(Duration(days: 7)),
    endDate: DateTime.now(),
  );
  print('History entries: ${history.timeSeries?.length ?? 0}');
  
  // Control energy products (requires energy_cmds scope)
  await client.energy.setBackupReservePercent(energySiteId, 20);
  await client.energy.enableStormMode(energySiteId, true);
}
```

## Authentication

The Tesla Fleet API supports two OAuth 2.0 authentication flows:

### Authorization Code Flow
For applications that need to access personal Tesla accounts and vehicles:

1. Create a Tesla developer account at [developer.tesla.com](https://developer.tesla.com)
2. Create an application and configure redirect URI
3. Select required scopes (see Scopes section below)
4. Get authorization from users via browser redirect

### Client Credentials Flow  
For business applications with limited access:

1. Create a Tesla developer account and business application
2. This flow has very limited scopes (typically only `vehicle_device_data`)
3. No user authorization required, but limited functionality

### Regions
The package supports multiple Tesla regions:

- `northAmericaAsiaPacific` (default) - North America and Asia-Pacific
- `europeMiddleEastAfrica` - Europe, Middle East, and Africa  
- `china` - China (uses different domains)

```dart
final auth = TeslaAuth(
  clientId: 'YOUR_CLIENT_ID_HERE',
  clientSecret: 'YOUR_CLIENT_SECRET_HERE',
  privateKey: '', // Optional for most flows
  redirectUri: 'YOUR_REDIRECT_URI_HERE', // Required for Authorization Code flow
  region: 'northAmericaAsiaPacific', // Choose appropriate region
);
```

### Scopes
Different scopes provide access to different functionality:

- `openid` - Basic OpenID Connect
- `offline_access` - Refresh token support  
- `user_data` - User profile information
- `vehicle_device_data` - Vehicle data and status
- `vehicle_cmds` - Vehicle control commands
- `vehicle_charging_cmds` - Charging control commands
- `energy_device_data` - Energy product data
- `energy_cmds` - Energy product control

## Error Handling

The package provides comprehensive error handling with specific exception types:

```dart
try {
  final vehicles = await client.vehicles.list();
} on TeslaAuthException catch (e) {
  print('Authentication error: ${e.message}');
  // Handle token refresh or re-authorization
} on TeslaRateLimitException catch (e) {
  print('Rate limited. Retry after: ${e.retryAfter}');
  // Implement backoff and retry logic
} on TeslaVehicleException catch (e) {
  print('Vehicle error for ${e.vehicleId}: ${e.message}');
  // Handle vehicle-specific errors (vehicle asleep, etc.)
} on TeslaApiException catch (e) {
  print('API error: ${e.message}');
  // Handle general API errors
}
```

### Common Error Scenarios

- **HTTP 412**: Vehicle is asleep or not ready. Try waking up the vehicle first.
- **HTTP 403**: Insufficient permissions or missing scopes.
- **HTTP 404**: Vehicle or resource not found.
- **Rate Limiting**: Automatic retry with exponential backoff.
- **Registration Required**: Use `client.partner.registerPartner(domain)` for first-time setup.

## Partner Registration

For first-time API access, you may need to register your partner account:

```dart
try {
  // Attempt to register partner account
  await client.partner.registerPartner('your-domain.com');
  print('Partner registration successful!');
  
  // Wait for registration to propagate
  await Future.delayed(Duration(seconds: 30));
} catch (e) {
  print('Registration failed: $e');
}
```

## Complete Example

Run the interactive example to explore all features:

```bash
dart run example/example.dart
```

The example provides:
- **Interactive Authentication**: Choose between Authorization Code and Client Credentials flows
- **Scope Selection**: Select appropriate scopes for your use case
- **Safety Features**: Separate safe data retrieval from vehicle control commands
- **Comprehensive Testing**: Test all available endpoints based on your scopes
- **Error Handling**: Demonstrates proper error handling and recovery
- **Automatic Registration**: Handles partner account registration automatically

### Example Features

1. **Authorization Code Flow**: For personal vehicle access with full functionality
2. **Client Credentials Flow**: For business applications with limited access
3. **Scope-based Testing**: Only runs tests available for your selected scopes
4. **Vehicle Control Safety**: Separate confirmation required for vehicle control commands
5. **Automatic Wake-up**: Handles vehicle wake-up automatically when needed
6. **Energy Product Support**: Full energy product management (Solar, Powerwall)
7. **Charging History**: Detailed charging session analysis

## Available Endpoints

### Vehicle Endpoints
- `list()` - List all vehicles
- `getVehicleData(vehicleId)` - Get comprehensive vehicle data
- `wakeUp(vehicleId)` - Wake up vehicle
- `unlockDoors(vehicleId)` / `lockDoors(vehicleId)` - Door control
- `honkHorn(vehicleId)` / `flashLights(vehicleId)` - Horn and lights
- `startClimate(vehicleId)` / `stopClimate(vehicleId)` - Climate control
- `setTemperature(vehicleId, driverTemp, passengerTemp)` - Temperature control
- `startCharging(vehicleId)` / `stopCharging(vehicleId)` - Charging control
- `setChargeLimit(vehicleId, percent)` - Set charge limit
- `openChargePort(vehicleId)` / `closeChargePort(vehicleId)` - Charge port control

### Energy Endpoints
- `list()` - List energy products (Solar, Powerwall)
- `getLiveStatus(energySiteId)` - Get real-time energy data
- `getHistory(energySiteId, period, startDate, endDate)` - Get historical energy data
- `setBackupReservePercent(energySiteId, percent)` - Set backup reserve
- `setOperationMode(energySiteId, mode)` - Set operation mode
- `enableStormMode(energySiteId, enabled)` - Enable/disable storm mode

### Charging Endpoints
- `getChargingHistory(vin, limit)` - Get charging session history
- `getChargingSession(sessionId)` - Get specific charging session
- `getChargingInvoice(sessionId)` - Get charging invoice

### Partner Endpoints
- `getPartnerAccount()` - Get partner account info
- `registerPartner(domain)` - Register as partner (automatic in example)
- `getMe()` - Get current user info (requires user_data scope)

## Rate Limiting

The package automatically handles rate limiting by throwing `TeslaRateLimitException` with retry-after information. The example demonstrates proper retry logic with exponential backoff.

## Getting Started

1. **Setup Tesla Developer Account**: Visit [developer.tesla.com](https://developer.tesla.com)
2. **Create Application**: Configure your app with appropriate scopes and redirect URI
3. **Replace Credentials**: Update the example with your actual `clientId`, `clientSecret`, and `redirectUri`
4. **Run Example**: `dart run example/example.dart` to test your setup
5. **Build Your App**: Use the patterns from the example in your application

## Requirements

- Dart SDK >= 3.5.0
- Active Tesla Developer Account
- Tesla vehicle or energy product for testing (some endpoints)

## Troubleshooting

- **HTTP 412 Errors**: Vehicle is asleep - use `wakeUp()` first
- **Missing Scopes**: Ensure your app has the required scopes in Tesla Developer Portal
- **Registration Required**: Run `client.partner.registerPartner(domain)` on first use
- **Rate Limiting**: The package handles this automatically with exponential backoff

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This package is not officially affiliated with Tesla, Inc. Use at your own risk. Always test vehicle control commands in a safe environment.