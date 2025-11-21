# CLAUDE.md - AI Assistant Guide for Tesla Fleet API

This document provides comprehensive guidance for AI assistants working on the Tesla Fleet API Dart package. It covers codebase structure, development workflows, conventions, and best practices.

## Project Overview

**Package Name**: `tesla_fleet_api`
**Version**: 1.0.0
**Language**: Dart
**SDK**: >= 3.0.0 < 4.0.0
**Repository**: https://github.com/cutmail/tesla_fleet_api
**License**: MIT

### Purpose

A comprehensive Dart package for interacting with the Tesla Fleet API, providing:
- Vehicle management and control (lock/unlock, climate, charging)
- Energy product monitoring and control (Solar, Powerwall)
- Charging session history and invoices
- Partner account management
- Multi-region support (North America/Asia-Pacific, Europe/Middle East/Africa, China)
- OAuth 2.0 authentication (Authorization Code and Client Credentials flows)

## Codebase Structure

```
tesla_fleet_api/
├── lib/
│   ├── tesla_fleet_api.dart        # Main entry point (exports all public APIs)
│   └── src/
│       ├── auth/
│       │   └── tesla_auth.dart     # OAuth 2.0 authentication (235 lines)
│       ├── endpoints/
│       │   ├── charging_endpoints.dart    # Charging history/sessions (73 lines)
│       │   ├── energy_endpoints.dart      # Energy products (124 lines)
│       │   ├── partner_endpoints.dart     # Partner management (53 lines)
│       │   └── vehicle_endpoints.dart     # Vehicle operations (233 lines)
│       ├── exceptions/
│       │   └── tesla_exceptions.dart      # Exception hierarchy
│       ├── models/
│       │   ├── charging_models.dart       # Charging data models
│       │   ├── common_models.dart         # Shared models (ApiResponse, Location, etc.)
│       │   ├── energy_models.dart         # Energy product models
│       │   ├── models.dart                # Barrel file (exports all models)
│       │   ├── partner_models.dart        # Partner/user models
│       │   └── vehicle_models.dart        # Vehicle data models (~437 lines)
│       └── tesla_fleet_client.dart        # Core HTTP client (152 lines)
├── test/
│   ├── tesla_fleet_api_test.dart   # Main test suite (317 lines)
│   └── mocks/
│       ├── mock_http_client.dart   # Mock HTTP client for testing
│       └── mock_tesla_auth.dart    # Mock authentication
├── example/
│   └── example.dart                # Interactive example app (500+ lines)
├── pubspec.yaml                    # Dependencies and metadata
├── README.md                       # User-facing documentation
├── CHANGELOG.md                    # Version history
└── LICENSE                         # MIT License
```

### Total Lines of Code
- **Core Implementation** (`lib/src`): ~1,471 lines
- **Tests**: 317 lines + mocks
- **Example**: 500+ lines

## Architecture & Design Patterns

### 1. Layered Architecture

```
┌─────────────────────────────────────────┐
│   Presentation Layer (example.dart)     │
├─────────────────────────────────────────┤
│   API Layer (Endpoints)                 │
│   - VehicleEndpoints                    │
│   - EnergyEndpoints                     │
│   - ChargingEndpoints                   │
│   - PartnerEndpoints                    │
├─────────────────────────────────────────┤
│   Business Logic (TeslaFleetClient)     │
│   - HTTP routing                        │
│   - Response handling                   │
│   - Error processing                    │
├─────────────────────────────────────────┤
│   Authentication Layer (TeslaAuth)      │
│   - Token management                    │
│   - Auto-refresh (300s before expiry)   │
│   - OAuth 2.0 flows                     │
├─────────────────────────────────────────┤
│   Data Layer (Models)                   │
│   - JSON serialization                  │
│   - Type-safe data structures           │
├─────────────────────────────────────────┤
│   Error Layer (Exceptions)              │
│   - TeslaAuthException                  │
│   - TeslaApiException                   │
│   - TeslaRateLimitException             │
│   - TeslaVehicleException               │
└─────────────────────────────────────────┘
```

### 2. Dependency Injection

- **TeslaFleetClient** accepts `TeslaAuth` instance and optional `http.Client`
- Facilitates testing with mock dependencies
- Clean separation of concerns

### 3. Endpoint Pattern

Each endpoint class:
- Holds reference to `TeslaFleetClient`
- Methods return strongly-typed model objects
- Consistent error handling via `ApiResponse<T>` wrapper
- RESTful API mapping

### 4. JSON Serialization Strategy

- Uses `json_annotation` package with `@JsonSerializable`
- Automatic snake_case field renaming via `FieldRename.snake`
- Generated code in `*.g.dart` files (via `build_runner`)
- Factory constructors: `fromJson(Map<String, dynamic> json)`
- Serialization methods: `toJson() -> Map<String, dynamic>`

## Key Files and Their Responsibilities

### Core Client: `lib/src/tesla_fleet_client.dart`

**Primary Class**: `TeslaFleetClient`

**Responsibilities**:
- HTTP request orchestration
- Automatic token retrieval and injection
- Response parsing and error handling
- Lazy-initialization of endpoint groups

**Key Methods**:
- `get()`, `post()`, `put()`, `delete()` - HTTP operations
- `_makeRequest()` - Core request handler
- `_handleResponse()` - Response processing with error conversion

**Properties**:
- `vehicles` → `VehicleEndpoints`
- `energy` → `EnergyEndpoints`
- `charging` → `ChargingEndpoints`
- `partner` → `PartnerEndpoints`

**Error Handling Flow**:
```dart
HTTP Response
    ├─ 429 → TeslaRateLimitException (with retryAfter Duration)
    ├─ 4xx/5xx → TeslaApiException (with statusCode, message)
    └─ 200-299 → Parse JSON or throw on invalid content
```

### Authentication: `lib/src/auth/tesla_auth.dart`

**Primary Class**: `TeslaAuth`

**Constructor Parameters**:
- `clientId` - Required OAuth client ID
- `clientSecret` - Required OAuth secret
- `privateKey` - Optional JWT signing key
- `region` - `northAmericaAsiaPacific` (default), `europeMiddleEastAfrica`, `china`
- `redirectUri` - Required for Authorization Code flow
- `baseUrl` - Auto-determined by region (can override)
- `authUrl` - Auto-determined by region (can override)

**Token Management**:
- In-memory cache with expiry tracking
- Auto-refresh 300 seconds before expiration
- Thread-safe token retrieval via `getAccessToken()`

**Regional Endpoints**:
| Region | API Base URL | Auth URL |
|--------|-------------|----------|
| North America/Asia-Pacific | `https://fleet-api.prd.na.vn.cloud.tesla.com` | `https://fleet-auth.prd.vn.cloud.tesla.com` |
| Europe/Middle East/Africa | `https://fleet-api.prd.eu.vn.cloud.tesla.com` | `https://fleet-auth.prd.eu.vn.cloud.tesla.com` |
| China | `https://fleet-api.prd.cn.vn.cloud.tesla.cn` | `https://fleet-auth.prd.cn.vn.cloud.tesla.cn` |

**Authentication Flows**:
1. **Authorization Code Flow** (for personal vehicle access)
   - Requires `redirectUri`
   - User authorization via browser
   - Full scope access available

2. **Client Credentials Flow** (for business applications)
   - No user authorization required
   - Limited scopes (typically only `vehicle_device_data`)
   - Automatic token retrieval

### Exception Hierarchy: `lib/src/exceptions/tesla_exceptions.dart`

```dart
TeslaException (abstract base)
├── TeslaAuthException         // Auth failures, invalid credentials
├── TeslaApiException          // General API errors (includes statusCode)
├── TeslaRateLimitException    // HTTP 429 (includes retryAfter Duration)
└── TeslaVehicleException      // Vehicle-specific errors (includes vehicleId)
```

**When to Use Each Exception**:
- **TeslaAuthException**: Token refresh failures, OAuth errors, invalid credentials
- **TeslaApiException**: HTTP 4xx/5xx errors (except 429), invalid JSON responses
- **TeslaRateLimitException**: HTTP 429 only, extract `retry-after` header
- **TeslaVehicleException**: Vehicle-specific errors (asleep, offline, command failures)

### Models: `lib/src/models/`

**Common Models** (`common_models.dart`):
```dart
ApiResponse<T> {
  T? response;              // Success data
  String? error;            // Error code
  List<String>? errorDescription;
  bool? errorAndMessages;
}

Location { double? latitude; double? longitude; }
CommandResponse { bool result; String? reason; }
```

**Vehicle Models** (`vehicle_models.dart` - ~437 lines):
- `Vehicle` - Basic vehicle info (id, vin, displayName, state, tokens)
- `VehicleData` - Complete snapshot (extends Vehicle + all state data)
- `DriveState` - Location, speed, heading, power
- `ClimateState` - Temperature, HVAC, seat heaters (25+ fields)
- `ChargeState` - Battery, charging, range (40+ fields)
- `GuiSettings` - Display preferences (units, time format)
- `VehicleState` - Lock status, odometer, doors/windows (28 fields)
- `VehicleConfig` - Car type, colors, features (26 fields)

**Energy Models** (`energy_models.dart`):
- `EnergyProduct` - Product info (energySiteId, siteName, components)
- `EnergyLiveStatus` - Real-time power flows (solar, battery, grid, load)
- `EnergyHistory` - Historical energy data with time series

**Charging Models** (`charging_models.dart`):
- `ChargingSession` - Session details (32 fields: energy, cost, location, SOC)
- `ChargingInvoice` - Invoice data (Base64 content)

**Partner Models** (`partner_models.dart`):
- `PartnerAccount` - publicKey, domain
- `User` - email, fullName, profileImageUrl

## Development Workflows

### Setting Up Development Environment

```bash
# Clone repository
git clone https://github.com/cutmail/tesla_fleet_api.git
cd tesla_fleet_api

# Install dependencies
dart pub get

# Generate JSON serialization code
dart run build_runner build

# Run tests
dart test

# Run example (requires Tesla credentials)
dart run example/example.dart
```

### Code Generation Workflow

This package uses **code generation** for JSON serialization. When adding or modifying models:

1. **Add/modify model class** with `@JsonSerializable()` annotation
2. **Import required packages**:
   ```dart
   import 'package:json_annotation/json_annotation.dart';
   part 'your_model.g.dart';
   ```
3. **Define model with annotations**:
   ```dart
   @JsonSerializable(fieldRename: FieldRename.snake)
   class YourModel {
     final String someField;
     final int? optionalField;

     YourModel({required this.someField, this.optionalField});

     factory YourModel.fromJson(Map<String, dynamic> json) =>
         _$YourModelFromJson(json);

     Map<String, dynamic> toJson() => _$YourModelToJson(this);
   }
   ```
4. **Run code generation**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
5. **Verify generated `*.g.dart` file** is created

### Testing Workflow

**Running Tests**:
```bash
# Run all tests
dart test

# Run specific test file
dart test test/tesla_fleet_api_test.dart

# Run with coverage
dart test --coverage=coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

**Test Structure** (AAA Pattern):
```dart
test('description of test', () {
  // Arrange
  final mockClient = MockHttpClient();
  final auth = MockTeslaAuth();
  final client = TeslaFleetClient(auth: auth, httpClient: mockClient);

  mockClient.setResponse(
    statusCode: 200,
    body: '{"response": {...}}',
  );

  // Act
  final result = await client.vehicles.list();

  // Assert
  expect(result.length, greaterThan(0));
  expect(mockClient.lastRequest?.url.path, '/api/1/vehicles');
});
```

**Mock Classes**:
- `MockTeslaAuth` - Returns fixed token, no actual OAuth calls
- `MockHttpClient` - Allows setting responses, tracks last request

### Adding New Endpoints

1. **Define model classes** in `lib/src/models/` with `@JsonSerializable()`
2. **Generate JSON code**: `dart run build_runner build`
3. **Create endpoint class** in `lib/src/endpoints/`
4. **Add endpoint property** to `TeslaFleetClient`
5. **Export from barrel file** (`lib/src/endpoints/endpoints.dart`)
6. **Write tests** in `test/tesla_fleet_api_test.dart`
7. **Update documentation** in README.md

**Example Endpoint Class**:
```dart
class NewEndpoints {
  final TeslaFleetClient _client;

  NewEndpoints(this._client);

  Future<YourModel> getSomething(String id) async {
    final response = await _client.get('/api/1/your_endpoint/$id');
    final apiResponse = ApiResponse<YourModel>.fromJson(
      response,
      (json) => YourModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.response!;
  }

  Future<CommandResponse> doSomething(String id, Map<String, dynamic> params) async {
    final response = await _client.post(
      '/api/1/your_endpoint/$id/action',
      body: params,
    );
    return CommandResponse.fromJson(response['response']);
  }
}
```

### Git Workflow

**Branch Strategy**:
- Main branch: `main` (or as specified in git status)
- Feature branches: `claude/claude-md-<session-id>` for AI assistant work
- Always create feature branches from main

**Commit Guidelines**:
- Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`
- Be descriptive but concise
- Reference issue numbers when applicable

**Current Working Branch**:
```
claude/claude-md-mi83mhh6gv55b3ot-011hitHoWykkeYCDd4abPVkC
```

**Important Git Rules**:
- Always push with: `git push -u origin <branch-name>`
- Branch must start with `claude/` and end with matching session ID
- Retry on network failures up to 4 times with exponential backoff (2s, 4s, 8s, 16s)

## Coding Conventions

### Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Classes | PascalCase | `TeslaFleetClient`, `VehicleEndpoints` |
| Methods | camelCase | `getVehicleData()`, `startCharging()` |
| Variables | camelCase | `vehicleId`, `energySiteId` |
| Constants | camelCase | `baseUrl`, `authUrl` |
| JSON Fields | snake_case | `vehicle_id`, `charge_state` (auto-converted) |
| Private Fields | _prefixed | `_client`, `_auth`, `_httpClient` |
| Enums | PascalCase | N/A (using strings) |

### Code Style

**Prefer**:
- Null-safety: Use `?` for nullable types, avoid `!` when possible
- Named parameters for methods with 2+ parameters
- Final variables whenever possible
- Explicit return types
- Async/await over `.then()`

**Avoid**:
- Force unwrapping (`!`) without null checks
- Deeply nested code (max 3-4 levels)
- Magic numbers (use named constants)
- Catching generic `Exception` (use specific types)

**Example Good Code**:
```dart
Future<VehicleData> getVehicleData(String vehicleId) async {
  final response = await _client.get('/api/1/vehicles/$vehicleId/vehicle_data');
  final apiResponse = ApiResponse<VehicleData>.fromJson(
    response,
    (json) => VehicleData.fromJson(json as Map<String, dynamic>),
  );

  if (apiResponse.response == null) {
    throw TeslaApiException(
      'No vehicle data returned for vehicle: $vehicleId',
    );
  }

  return apiResponse.response!;
}
```

### Error Handling Patterns

**Always**:
1. Use specific exception types
2. Include context in error messages (vehicle ID, endpoint, etc.)
3. Handle HTTP 429 separately with `TeslaRateLimitException`
4. Validate responses before accessing data

**HTTP Status Code Mapping**:
```dart
switch (response.statusCode) {
  case 429:
    final retryAfter = Duration(
      seconds: int.parse(response.headers['retry-after'] ?? '60')
    );
    throw TeslaRateLimitException(
      'Rate limit exceeded',
      retryAfter: retryAfter,
    );
  case >= 400 && < 500:
    throw TeslaApiException(
      'Client error: ${response.body}',
      statusCode: response.statusCode,
    );
  case >= 500:
    throw TeslaApiException(
      'Server error: ${response.body}',
      statusCode: response.statusCode,
    );
}
```

### Documentation Standards

**Every public API must have**:
1. Dartdoc comment (///)
2. Parameter descriptions
3. Return type description
4. Exception documentation
5. Usage example (for complex methods)

**Example**:
```dart
/// Retrieves comprehensive data for a specific vehicle.
///
/// This includes drive state, climate state, charge state, vehicle state,
/// vehicle config, and GUI settings.
///
/// Parameters:
///   [vehicleId] - The unique identifier for the vehicle
///
/// Returns:
///   A [VehicleData] object containing all vehicle information
///
/// Throws:
///   [TeslaAuthException] if authentication fails
///   [TeslaApiException] if the API request fails
///   [TeslaVehicleException] if the vehicle is not found or unavailable
///
/// Example:
/// ```dart
/// final vehicleData = await client.vehicles.getVehicleData('12345');
/// print('Battery: ${vehicleData.chargeState?.batteryLevel}%');
/// ```
Future<VehicleData> getVehicleData(String vehicleId) async {
  // Implementation...
}
```

## Common Tasks and Patterns

### Task 1: Adding a New Vehicle Command

```dart
// 1. Add method to VehicleEndpoints class
Future<CommandResponse> yourNewCommand(
  String vehicleId, {
  required String param1,
  int? optionalParam,
}) async {
  final response = await _client.post(
    '/api/1/vehicles/$vehicleId/command/your_command',
    body: {
      'param1': param1,
      if (optionalParam != null) 'optional_param': optionalParam,
    },
  );
  return CommandResponse.fromJson(response['response']);
}

// 2. Add test
test('yourNewCommand sends correct request', () async {
  mockClient.setResponse(
    statusCode: 200,
    body: '{"response": {"result": true}}',
  );

  final result = await client.vehicles.yourNewCommand(
    vehicleId,
    param1: 'value',
  );

  expect(result.result, isTrue);
  expect(mockClient.lastRequest?.url.path,
    '/api/1/vehicles/$vehicleId/command/your_command');
});

// 3. Document in README.md
```

### Task 2: Adding a New Model Field

```dart
// 1. Add field to model class
@JsonSerializable(fieldRename: FieldRename.snake)
class VehicleData {
  final String? vin;
  final ChargeState? chargeState;
  final NewField? newField;  // <- Add this

  VehicleData({
    this.vin,
    this.chargeState,
    this.newField,  // <- Add this
  });

  factory VehicleData.fromJson(Map<String, dynamic> json) =>
      _$VehicleDataFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleDataToJson(this);
}

// 2. Run code generation
// $ dart run build_runner build --delete-conflicting-outputs

// 3. Update tests to include new field
```

### Task 3: Handling Rate Limiting

```dart
// Implement exponential backoff
Future<T> _retryWithBackoff<T>(Future<T> Function() operation) async {
  int attempts = 0;
  const maxAttempts = 4;

  while (attempts < maxAttempts) {
    try {
      return await operation();
    } on TeslaRateLimitException catch (e) {
      attempts++;
      if (attempts >= maxAttempts) rethrow;

      final delay = e.retryAfter ?? Duration(seconds: 2 << attempts);
      print('Rate limited. Retrying after $delay...');
      await Future.delayed(delay);
    }
  }

  throw TeslaApiException('Max retry attempts exceeded');
}

// Usage
final vehicles = await _retryWithBackoff(() => client.vehicles.list());
```

### Task 4: Waking Up a Sleeping Vehicle

```dart
Future<VehicleData> getVehicleDataWithWakeup(String vehicleId) async {
  final vehicles = await client.vehicles.list();
  final vehicle = vehicles.firstWhere((v) => v.id.toString() == vehicleId);

  if (vehicle.state == 'asleep' || vehicle.state == 'offline') {
    print('Vehicle is ${vehicle.state}, waking up...');
    await client.vehicles.wakeUp(vehicleId);

    // Poll until vehicle is online (max 30 seconds)
    for (int i = 0; i < 6; i++) {
      await Future.delayed(Duration(seconds: 5));
      final updatedVehicles = await client.vehicles.list();
      final updatedVehicle = updatedVehicles.firstWhere(
        (v) => v.id.toString() == vehicleId
      );

      if (updatedVehicle.state == 'online') {
        print('Vehicle is now online');
        break;
      }
    }
  }

  return await client.vehicles.getVehicleData(vehicleId);
}
```

## Testing Strategy

### Unit Tests
- Mock HTTP client and auth
- Test all endpoint methods
- Validate request paths and parameters
- Test error handling paths
- Verify JSON parsing

### Integration Tests
- Test with real credentials (separate from unit tests)
- Use safe endpoints only (data retrieval, not vehicle control)
- Test token refresh flow
- Test multi-region support

### Test Coverage Goals
- **Models**: 100% (all fromJson/toJson)
- **Endpoints**: >90% (all public methods)
- **Client**: >90% (request/response handling)
- **Auth**: >80% (token management)
- **Exceptions**: 100% (simple classes)

### Example Test Pattern

```dart
group('VehicleEndpoints', () {
  late MockHttpClient mockClient;
  late MockTeslaAuth auth;
  late TeslaFleetClient client;

  setUp(() {
    mockClient = MockHttpClient();
    auth = MockTeslaAuth();
    client = TeslaFleetClient(auth: auth, httpClient: mockClient);
  });

  test('list returns vehicles on success', () async {
    mockClient.setResponse(
      statusCode: 200,
      body: '''
        {
          "response": [
            {"id": 123, "vin": "ABC123", "display_name": "My Tesla"}
          ]
        }
      ''',
    );

    final vehicles = await client.vehicles.list();

    expect(vehicles, hasLength(1));
    expect(vehicles.first.vin, equals('ABC123'));
    expect(mockClient.lastRequest?.url.path, equals('/api/1/vehicles'));
  });

  test('list throws on API error', () async {
    mockClient.setResponse(statusCode: 500, body: 'Server error');

    expect(
      () => client.vehicles.list(),
      throwsA(isA<TeslaApiException>()),
    );
  });
});
```

## Important Considerations

### Security
- **Never commit credentials** to version control
- Use environment variables for sensitive data
- Example file should use placeholders (`YOUR_CLIENT_ID_HERE`)
- Warn users about vehicle control safety in documentation

### API Rate Limits
- Tesla enforces rate limits (exact limits not publicly documented)
- Always handle `TeslaRateLimitException`
- Implement exponential backoff
- Consider caching data when possible

### Vehicle States
- **online**: Vehicle is awake and responsive
- **asleep**: Vehicle is sleeping (low power mode)
- **offline**: Vehicle is offline (no connectivity)

**Best Practice**: Always wake vehicle before sending commands

### Scope Requirements

| Scope | Access |
|-------|--------|
| `openid` | Basic OpenID Connect |
| `offline_access` | Refresh tokens |
| `user_data` | User profile (`/api/1/users/me`) |
| `vehicle_device_data` | Vehicle data retrieval |
| `vehicle_cmds` | Vehicle control commands |
| `vehicle_charging_cmds` | Charging control + history |
| `energy_device_data` | Energy product data |
| `energy_cmds` | Energy product control |

### Common Error Codes

| HTTP Code | Meaning | Action |
|-----------|---------|--------|
| 401 | Unauthorized | Refresh token or re-authenticate |
| 403 | Forbidden | Check scopes, may need partner registration |
| 404 | Not found | Verify vehicle/resource ID |
| 412 | Precondition failed | Vehicle unavailable, try waking up |
| 429 | Rate limited | Implement backoff, respect `retry-after` |
| 500 | Server error | Retry with exponential backoff |

## Troubleshooting Guide

### Issue: HTTP 412 Errors
**Cause**: Vehicle is asleep or unavailable
**Solution**: Call `wakeUp(vehicleId)` first, wait 5-10 seconds

### Issue: Missing Scopes
**Cause**: Application doesn't have required OAuth scopes
**Solution**: Update app configuration at developer.tesla.com

### Issue: Registration Required
**Cause**: First-time API access requires partner registration
**Solution**: Call `client.partner.registerPartner(domain)`, wait 30s

### Issue: Invalid JSON Response
**Cause**: API returned unexpected format or error
**Solution**: Check API documentation, validate response structure

### Issue: Token Refresh Failures
**Cause**: Refresh token expired or invalid
**Solution**: Re-authenticate using Authorization Code flow

## Dependencies

### Runtime Dependencies
- `http: ^1.1.0` - HTTP client for API requests
- `crypto: ^3.0.3` - Cryptographic functions (JWT signing)
- `jwt_decode: ^0.3.1` - JWT token parsing
- `json_annotation: ^4.8.1` - JSON serialization annotations

### Dev Dependencies
- `test: ^1.24.0` - Testing framework
- `build_runner: ^2.4.7` - Code generation runner
- `json_serializable: ^6.7.1` - JSON code generator
- `lints: ^6.0.0` - Dart linting rules

### Updating Dependencies

```bash
# Check for outdated packages
dart pub outdated

# Update dependencies
dart pub upgrade

# Update specific package
dart pub upgrade http

# After updating, run tests
dart test
```

## Version History

### v1.0.0 (2024-06-14)
- Initial release
- Complete Tesla Fleet API implementation
- Multi-region support
- OAuth 2.0 authentication (both flows)
- Comprehensive test suite
- Interactive example application

## Resources

### Official Documentation
- **Tesla Fleet API**: https://developer.tesla.com/docs/fleet-api
- **Tesla Developer Portal**: https://developer.tesla.com

### Package Resources
- **Repository**: https://github.com/cutmail/tesla_fleet_api
- **Issues**: https://github.com/cutmail/tesla_fleet_api/issues
- **pub.dev**: https://pub.dev/packages/tesla_fleet_api (when published)

### Dart Resources
- **Dart Documentation**: https://dart.dev/guides
- **JSON Serialization**: https://docs.flutter.dev/data-and-backend/json
- **Testing**: https://dart.dev/guides/testing

## Quick Reference

### Essential Commands

```bash
# Setup
dart pub get
dart run build_runner build

# Development
dart run build_runner watch          # Auto-regenerate on changes
dart analyze                         # Static analysis
dart format lib/ test/ example/      # Format code

# Testing
dart test
dart test --coverage=coverage

# Running Example
dart run example/example.dart
```

### Key API Patterns

```dart
// Initialize client
final auth = TeslaAuth(
  clientId: 'YOUR_CLIENT_ID',
  clientSecret: 'YOUR_CLIENT_SECRET',
  region: 'northAmericaAsiaPacific',
);
final client = TeslaFleetClient(auth: auth);

// Get vehicles
final vehicles = await client.vehicles.list();

// Get vehicle data
final data = await client.vehicles.getVehicleData(vehicleId);

// Send command
final result = await client.vehicles.honkHorn(vehicleId);

// Energy status
final status = await client.energy.getLiveStatus(energySiteId);

// Charging history
final sessions = await client.charging.getChargingHistory(vin: vin);

// Error handling
try {
  await client.vehicles.list();
} on TeslaRateLimitException catch (e) {
  await Future.delayed(e.retryAfter);
} on TeslaAuthException catch (e) {
  // Re-authenticate
} on TeslaApiException catch (e) {
  print('API Error: ${e.statusCode} - ${e.message}');
}
```

---

**Last Updated**: 2024-11-21
**For**: AI assistants working on tesla_fleet_api Dart package
**Maintained By**: Project contributors
