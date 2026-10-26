import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final DateTime? expiresAt;
  final User user;

  String get apiKey => token;

  bool get isExpired =>
      expiresAt == null || !expiresAt!.isAfter(DateTime.now());

  Map<String, dynamic> toJson() => {
    'token': token,
    'expires_at': expiresAt?.toIso8601String(),
    'user': user.toJson(),
  };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    if (json['token'] == null || rawUser is! Map) {
      throw const FormatException('Sesión guardada inválida.');
    }
    return AuthSession(
      token: '${json['token']}',
      expiresAt: DateTime.tryParse('${json['expires_at'] ?? ''}'),
      user: User.fromJson(Map<String, dynamic>.from(rawUser)),
    );
  }
}

class AuthRepository {
  AuthRepository({
    ApiClient? client,
    this.preferences,
    FlutterSecureStorage? secureStorage,
  }) : _client = client ?? ApiClient(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final ApiClient _client;
  final SharedPreferences? preferences;
  final FlutterSecureStorage _secureStorage;
  static const _sessionKey = 'auth_session';
  static const _emailKey = 'auth_email';
  static const _passwordKey = 'auth_password';
  Future<AuthSession>? _refreshInFlight;

  Future<SharedPreferences> _storage() async =>
      preferences ?? await SharedPreferences.getInstance();

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/auth/login.php', {
      'email': email,
      'password': password,
    });
    if (response is! Map<String, dynamic> ||
        response['token'] == null ||
        response['user'] is! Map) {
      throw const ApiException(
        'La respuesta de inicio de sesión no es válida.',
      );
    }
    final session = AuthSession(
      token: '${response['token']}',
      expiresAt: DateTime.tryParse('${response['expires_at'] ?? ''}'),
      user: User.fromJson(Map<String, dynamic>.from(response['user'] as Map)),
    );
    await saveSession(session);
    await _secureStorage.write(key: _emailKey, value: email);
    await _secureStorage.write(key: _passwordKey, value: password);
    return session;
  }

  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    };
    await _client.post('/users/create.php', body);
  }

  Future<String?> refreshToken() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return (await inFlight).token;

    final refresh = _refresh();
    _refreshInFlight = refresh;
    try {
      return (await refresh).token;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<AuthSession> _refresh() async {
    final email = await _secureStorage.read(key: _emailKey);
    final password = await _secureStorage.read(key: _passwordKey);
    if (email == null || email.isEmpty || password == null) {
      throw const ApiException(
        'La sesión expiró y no hay credenciales guardadas para renovarla.',
        statusCode: 401,
      );
    }
    return login(email: email, password: password);
  }

  Future<void> saveSession(AuthSession session) async {
    final storage = await _storage();
    await storage.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<AuthSession?> loadSession() async {
    final storage = await _storage();
    final raw = storage.getString(_sessionKey);
    if (raw == null) return null;
    try {
      final session = AuthSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (session.isExpired) {
        await clearSession();
        return null;
      }
      return session;
    } on FormatException {
      await clearSession();
      return null;
    } on TypeError {
      await clearSession();
      return null;
    }
  }

  Future<String?> getApiKey() async => (await loadSession())?.apiKey;

  Future<bool> isSessionExpired() async {
    final storage = await _storage();
    final raw = storage.getString(_sessionKey);
    if (raw == null) return true;
    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>)
          .isExpired;
    } on FormatException {
      return true;
    } on TypeError {
      return true;
    }
  }

  Future<void> clearSession() async {
    final storage = await _storage();
    await storage.remove(_sessionKey);
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
  }

  Future<User> me(String token) async {
    final response = await ApiClient(token: token).get('/auth/me.php');
    final user = response is Map<String, dynamic> && response['user'] is Map
        ? response['user']
        : response;
    if (user is! Map) {
      throw const ApiException('La respuesta del usuario no es válida.');
    }
    return User.fromJson(Map<String, dynamic>.from(user));
  }
}
