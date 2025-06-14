import 'dart:convert';
import 'package:http/http.dart' as http;
import '../exceptions/tesla_exceptions.dart';

class TeslaAuth {
  final String clientId;
  final String clientSecret;
  final String privateKey;
  final String baseUrl;
  final String authUrl;
  final String? redirectUri;
  final String region;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  TeslaAuth({
    required this.clientId,
    required this.clientSecret,
    required this.privateKey,
    this.region = 'northAmericaAsiaPacific',
    String? baseUrl,
    String? authUrl,
    this.redirectUri,
  }) : baseUrl = baseUrl ?? _getBaseUrl(region),
       authUrl = authUrl ?? _getAuthUrl(region);

  static String _getBaseUrl(String region) {
    switch (region) {
      case 'northAmericaAsiaPacific':
        return 'https://fleet-api.prd.na.vn.cloud.tesla.com';
      case 'europeMiddleEastAfrica':
        return 'https://fleet-api.prd.eu.vn.cloud.tesla.com';
      case 'china':
        return 'https://fleet-api.prd.cn.vn.cloud.tesla.cn';
      default:
        throw ArgumentError('Unsupported region: $region. Supported regions: northAmericaAsiaPacific, europeMiddleEastAfrica, china');
    }
  }

  static String _getAuthUrl(String region) {
    switch (region) {
      case 'northAmericaAsiaPacific':
        return 'https://fleet-auth.prd.vn.cloud.tesla.com';
      case 'europeMiddleEastAfrica':
        return 'https://fleet-auth.prd.eu.vn.cloud.tesla.com';
      case 'china':
        return 'https://fleet-auth.prd.cn.vn.cloud.tesla.cn';
      default:
        throw ArgumentError('Unsupported region: $region. Supported regions: northAmericaAsiaPacific, europeMiddleEastAfrica, china');
    }
  }

  Future<String> getAccessToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    await _refreshTokenClientCredentials();
    return _accessToken!;
  }

  String generateAuthorizationUrl({
    required List<String> scopes,
    String? state,
  }) {
    if (redirectUri == null) {
      throw TeslaAuthException(
          'Redirect URI is required for Authorization Code flow');
    }

    final params = {
      'client_id': clientId,
      'locale': 'en-US',
      'prompt': 'login',
      'redirect_uri': redirectUri!,
      'response_type': 'code',
      'scope': scopes.join(' '),
      if (state != null) 'state': state,
    };

    final query = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$authUrl/oauth2/v3/authorize?$query';
  }

  Future<void> exchangeAuthorizationCode(String code) async {
    if (redirectUri == null) {
      throw TeslaAuthException(
          'Redirect URI is required for Authorization Code flow');
    }

    try {
      print('🔄 Exchanging authorization code for token...');

      final response = await http.post(
        Uri.parse('$authUrl/oauth2/v3/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'audience': baseUrl,
          'redirect_uri': redirectUri!,
        },
      );

      print('📊 Token Exchange Response Status: ${response.statusCode}');
      print('📋 Token Exchange Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 300));
        print('✅ Authorization code exchange successful!');
      } else {
        throw TeslaAuthException(
            'Failed to exchange authorization code: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw TeslaAuthException('Authorization code exchange error: $e');
    }
  }

  Future<void> refreshAccessToken() async {
    if (_refreshToken == null) {
      throw TeslaAuthException('No refresh token available');
    }

    try {
      print('🔄 Refreshing access token...');

      final response = await http.post(
        Uri.parse('$authUrl/oauth2/v3/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'client_id': clientId,
          'refresh_token': _refreshToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        if (data['refresh_token'] != null) {
          _refreshToken = data['refresh_token'];
        }
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 300));
        print('✅ Token refresh successful!');
      } else {
        throw TeslaAuthException(
            'Failed to refresh token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw TeslaAuthException('Token refresh error: $e');
    }
  }

  Future<void> _refreshTokenClientCredentials() async {
    try {
      print('🔐 Attempting authentication...');
      print('🌐 Auth URL: $authUrl/oauth2/v3/token');
      print('🆔 Client ID: $clientId');
      print('🌍 Region: $region');

      final response = await http.post(
        Uri.parse('$authUrl/oauth2/v3/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
          'scope': 'openid offline_access vehicle_device_data',
        },
      );

      print('📊 Auth Response Status: ${response.statusCode}');
      print('📋 Auth Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 300));
        print('✅ Authentication successful! Token expires in ${expiresIn}s');
      } else {
        throw TeslaAuthException(
            'Failed to authenticate: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw TeslaAuthException('Authentication error: $e');
    }
  }

  Future<void> registerPartner() async {
    try {
      final token = await getAccessToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/1/partner_accounts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'domain': 'your-domain.com',
        }),
      );

      if (response.statusCode != 200) {
        throw TeslaApiException(
            'Failed to register partner: ${response.statusCode}');
      }
    } catch (e) {
      throw TeslaApiException('Partner registration error: $e');
    }
  }

}
