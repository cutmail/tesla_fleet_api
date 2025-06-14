import 'package:tesla_fleet_api/src/auth/tesla_auth.dart';

class MockTeslaAuth extends TeslaAuth {
  String _mockToken = 'mock-access-token';

  MockTeslaAuth()
      : super(
          clientId: 'test-client-id',
          clientSecret: 'test-client-secret',
          privateKey: 'test-private-key',
        );

  void setMockToken(String token) {
    _mockToken = token;
  }

  @override
  Future<String> getAccessToken() async {
    return _mockToken;
  }

  @override
  String generateAuthorizationUrl({
    required List<String> scopes,
    String? state,
  }) {
    return 'https://mock-auth-url.com/authorize';
  }

  @override
  Future<void> exchangeAuthorizationCode(String code) async {
    // Mock implementation - do nothing
  }

  @override
  Future<void> refreshAccessToken() async {
    // Mock implementation - do nothing
  }
}