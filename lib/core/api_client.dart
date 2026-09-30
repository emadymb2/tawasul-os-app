import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'env.dart';

class TawasulApiException implements Exception {
  TawasulApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'TawasulApiException($statusCode): $message';
}

class AuthTokens {
  const AuthTokens({required this.token, required this.refreshToken, this.person = const {}});

  final String token;
  final String refreshToken;
  final Map<String, dynamic> person;
}

/// Thin client over the school REST API v2.
///
/// A personal bearer token (from `POST /auth/login`) is used whenever one is
/// available. No shared school key is used as a fallback: each request runs
/// under the signed-in person's own role permissions.
class TawasulApiClient {
  TawasulApiClient({String? baseUrl, String? apiKey, http.Client? httpClient})
      : baseUrl = baseUrl ?? Env.baseUrl,
        apiKey = apiKey ?? Env.apiKey,
        _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final String apiKey;
  final http.Client _httpClient;

  String? _token;
  String? _refreshToken;

  /// Called when a refresh produces new tokens, so the session can persist them.
  void Function(String token, String refreshToken)? onTokensRefreshed;

  void setTokens({String? token, String? refreshToken}) {
    _token = token;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _token = null;
    _refreshToken = null;
  }

  bool get hasToken => (_token ?? '').isNotEmpty;
  bool get isConfigured => hasToken || apiKey.trim().isNotEmpty;

  Uri _uri(String path, [Map<String, String>? query]) {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$cleanBase$cleanPath');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Map<String, String> _headers({bool anonymous = false}) {
    final credential = _token ?? (apiKey.isNotEmpty ? apiKey : null);
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      // The API requires a bearer credential on every request, including login.
      if (credential != null) 'Authorization': 'Bearer $credential',
    };
  }

  // ---------------------------------------------------------------- auth ----

  Future<AuthTokens> login({required String username, required String password}) async {
    final response = await _httpClient.post(
      _uri('/auth/login'),
      headers: _headers(anonymous: true),
      body: jsonEncode({'username': username, 'password': password}),
    );
    final body = _decode(response);
    final tokens = _tokensFrom(body);
    if (tokens == null) {
      throw TawasulApiException('The sign-in response did not include a token.', statusCode: response.statusCode);
    }
    setTokens(token: tokens.token, refreshToken: tokens.refreshToken);
    return tokens;
  }

  Future<bool> refreshSession() async {
    final refresh = _refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final response = await _httpClient.post(
        _uri('/auth/refresh'),
        headers: _headers(anonymous: true),
        body: jsonEncode({'refreshToken': refresh}),
      );
      final tokens = _tokensFrom(_decode(response));
      if (tokens == null) return false;
      setTokens(token: tokens.token, refreshToken: tokens.refreshToken);
      onTokensRefreshed?.call(tokens.token, tokens.refreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    if (!hasToken) return;
    try {
      await _httpClient.post(_uri('/auth/logout'), headers: _headers());
    } catch (_) {
      // Signing out locally is enough even when the server cannot be reached.
    }
    clearTokens();
  }

  AuthTokens? _tokensFrom(Map<String, dynamic> body) {
    final data = body['data'] is Map ? Map<String, dynamic>.from(body['data'] as Map) : body;
    String? pick(Map<String, dynamic> source, List<String> keys) {
      for (final key in keys) {
        final value = source[key];
        if (value is String && value.isNotEmpty) return value;
      }
      return null;
    }

    final token = pick(data, ['token', 'accessToken', 'access_token']) ?? pick(body, ['token', 'accessToken']);
    if (token == null) return null;
    final refresh = pick(data, ['refreshToken', 'refresh_token']) ?? pick(body, ['refreshToken']) ?? '';
    final person = data['person'] is Map
        ? Map<String, dynamic>.from(data['person'] as Map)
        : (data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : <String, dynamic>{});
    return AuthTokens(token: token, refreshToken: refresh, person: person);
  }

  // -------------------------------------------------------------- requests --

  Future<Map<String, dynamic>> getMap(String path, {Map<String, String>? query}) =>
      _send((h) => _httpClient.get(_uri(path, query), headers: h));

  /// Downloads a file. School-system paths are sent with the person's own
  /// credential; outside links are fetched without it.
  Future<Uint8List> getBytes(String pathOrUrl, {Map<String, String>? query}) async {
    final external = pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://');
    final uri = external ? Uri.parse(pathOrUrl) : _uri(pathOrUrl, query);
    final sameHost = uri.host == Uri.parse(baseUrl).host;
    Map<String, String> headers() {
      final h = Map<String, String>.from(_headers(anonymous: external && !sameHost));
      h['Accept'] = 'application/pdf,application/octet-stream,*/*';
      h.remove('Content-Type');
      return h;
    }
    var response = await _httpClient.get(uri, headers: headers());
    if (response.statusCode == 401 && !external && await refreshSession()) {
      response = await _httpClient.get(uri, headers: headers());
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TawasulApiException(_errorMessage(response.body), statusCode: response.statusCode);
    }
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> postMap(String path, Map<String, dynamic> body) =>
      _send((h) => _httpClient.post(_uri(path), headers: h, body: jsonEncode(body)));

  Future<Map<String, dynamic>> putMap(String path, Map<String, dynamic> body) =>
      _send((h) => _httpClient.put(_uri(path), headers: h, body: jsonEncode(body)));

  Future<Map<String, dynamic>> patchMap(String path, Map<String, dynamic> body) =>
      _send((h) => _httpClient.patch(_uri(path), headers: h, body: jsonEncode(body)));

  Future<Map<String, dynamic>> deleteMap(String path) =>
      _send((h) => _httpClient.delete(_uri(path), headers: h));

  /// Convenience read that returns the `data` array of a collection.
  Future<List<Map<String, dynamic>>> getList(String path, {Map<String, String>? query}) async {
    final body = await getMap(path, query: query);
    return extractList(body);
  }

  static List<Map<String, dynamic>> extractList(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is List) {
      return data.whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList();
    }
    if (data is Map && data['records'] is List) {
      return (data['records'] as List).whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList();
    }
    if (body['records'] is List) {
      return (body['records'] as List).whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> _send(Future<http.Response> Function(Map<String, String> headers) request) async {
    if (!isConfigured) {
      throw TawasulApiException('Not signed in.', statusCode: 401);
    }
    var response = await request(_headers());
    if (response.statusCode == 401 && await refreshSession()) {
      response = await request(_headers());
    }
    // No fallback to a shared school key: every request runs under the signed-in
    // person's own permissions. A 403 means their role genuinely lacks access.
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.trim();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TawasulApiException(_errorMessage(body), statusCode: response.statusCode);
    }
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is List) return {'data': decoded};
    return {'data': decoded};
  }

  String _errorMessage(String body) {
    if (body.isEmpty) return 'Request failed.';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final error = decoded['error'] as Map;
        return error['message']?.toString() ?? 'Request failed.';
      }
    } catch (_) {
      // Fall through to the raw body.
    }
    return body;
  }
}
