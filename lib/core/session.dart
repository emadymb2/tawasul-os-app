import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'models.dart';
import 'offline_store.dart';

class AuthUser {
  const AuthUser({
    required this.personId,
    required this.name,
    required this.username,
    required this.role,
    this.roleLabel = '',
    this.email = '',
  });

  final String personId;
  final String name;
  final String username;
  final ConsoleRole role;
  final String roleLabel;
  final String email;

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'name': name,
        'username': username,
        'role': role.name,
        'roleLabel': roleLabel,
        'email': email,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        personId: json['personId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        role: ConsoleRole.values.firstWhere(
          (role) => role.name == json['role'],
          orElse: () => ConsoleRole.student,
        ),
        roleLabel: json['roleLabel']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
      );

  factory AuthUser.fromPerson(Map<String, dynamic> person) {
    final preferred = person['preferredName']?.toString() ?? person['firstName']?.toString() ?? '';
    final surname = person['surname']?.toString() ?? '';
    final name = [preferred, surname].where((part) => part.isNotEmpty).join(' ').trim();
    final category = person['roleCategory']?.toString() ?? '';
    final primary = person['rolePrimary']?.toString() ?? '';
    return AuthUser(
      personId: person['tawasulPersonID']?.toString() ?? '',
      name: name.isEmpty ? (person['username']?.toString() ?? '') : name,
      username: person['username']?.toString() ?? '',
      role: _roleFrom(category, primary),
      roleLabel: primary.isEmpty ? category : primary,
      email: person['email']?.toString() ?? '',
    );
  }

  static ConsoleRole _roleFrom(String category, String primary) {
    final value = '$category $primary'.toLowerCase();
    if (value.contains('student')) return ConsoleRole.student;
    if (value.contains('parent') || value.contains('guardian')) return ConsoleRole.parent;
    // Administrators land on the admin portal even when they also teach.
    if (value.contains('admin')) return ConsoleRole.admin;
    if (value.contains('teacher')) return ConsoleRole.teacher;
    // Staff category without a teaching role: support, etc.
    return ConsoleRole.staff;
  }
}

enum SessionStatus { loading, signedOut, signedIn }

class SessionController extends ChangeNotifier {
  SessionController({required this.api, required this.store}) {
    api.onTokensRefreshed = (token, refresh) {
      _token = token;
      _refreshToken = refresh;
      _persist();
    };
  }

  static const _storeKey = 'tawasul_session_v1';

  final TawasulApiClient api;
  final OfflineStore store;

  SessionStatus status = SessionStatus.loading;
  AuthUser? user;
  String? _token;
  String? _refreshToken;

  Future<void> restore() async {
    final saved = await store.readJson(_storeKey);
    if (saved == null || (saved['token']?.toString() ?? '').isEmpty) {
      status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }
    _token = saved['token']?.toString();
    _refreshToken = saved['refreshToken']?.toString();
    api.setTokens(token: _token, refreshToken: _refreshToken);
    if (saved['user'] is Map) {
      user = AuthUser.fromJson(Map<String, dynamic>.from(saved['user'] as Map));
    }
    status = SessionStatus.signedIn;
    notifyListeners();
    // Refresh the profile quietly; stale details should not block offline use.
    unawaited(_loadProfile());
  }

  /// Returns null on success, or a message describing why sign-in failed.
  Future<String?> signIn({required String username, required String password}) async {
    try {
      final tokens = await api.login(username: username.trim(), password: password);
      _token = tokens.token;
      _refreshToken = tokens.refreshToken;
      if (tokens.person.isNotEmpty) {
        user = AuthUser.fromPerson(tokens.person);
      }
      final profileLoaded = await _loadProfile();
      if (!profileLoaded && user == null) {
        return 'Signed in, but the account details could not be read.';
      }
      status = SessionStatus.signedIn;
      await _persist();
      notifyListeners();
      return null;
    } on TawasulApiException catch (error) {
      if (error.statusCode == 401) return 'wrong-credentials';
      if (error.statusCode == 403) return 'login-disabled';
      if (error.statusCode == 429) return 'too-many-attempts';
      if (error.statusCode == null) return 'network';
      return 'Server error: ${error.statusCode}';
    } catch (e) {
      // Surface the actual exception for debugging network/parse errors
      return 'connection-failed';
    }
  }

  Future<bool> _loadProfile() async {
    try {
      final body = await api.getMap('/auth/me');
      final data = body['data'] is Map ? Map<String, dynamic>.from(body['data'] as Map) : body;
      final person = data['person'] is Map ? Map<String, dynamic>.from(data['person'] as Map) : <String, dynamic>{};
      if (person.isEmpty) return false;
      user = AuthUser.fromPerson(person);
      await _persist();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await api.logout();
    _token = null;
    _refreshToken = null;
    user = null;
    status = SessionStatus.signedOut;
    await store.remove(_storeKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_token == null) return;
    await store.writeJson(_storeKey, {
      'token': _token,
      'refreshToken': _refreshToken,
      if (user != null) 'user': user!.toJson(),
    });
  }
}
