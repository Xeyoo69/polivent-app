import 'package:flutter/foundation.dart';

import '../config/app_navigator.dart';
import '../config/routes.dart';
import '../models/user.dart';
import '../utils/json_helper.dart';
import '../utils/storage.dart';
import 'api_service.dart';

/// Menyimpan state login (token + user) di memori dan local storage.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  User? _user;
  bool _handlingUnauthorized = false;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  bool get isAdmin => _user?.isAdmin ?? false;

  /// Dipakai saat splash: cek token yang tersimpan lalu ambil data user.
  Future<bool> restoreSession() async {
    final token = await AppStorage.readToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    final cachedUser = await AppStorage.readUser();
    if (cachedUser != null) {
      _user = User.fromJson(cachedUser);
    }

    try {
      final data = await ApiService.instance.get('/me');
      final map = jsonMap(data);

      if (map != null) {
        _user = User.fromJson(map);
        await AppStorage.saveUser(map);
      }

      notifyListeners();

      return _user != null;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await clearSession();

        return false;
      }

      // Server sedang tidak bisa dihubungi: tetap pakai data cache bila ada.
      notifyListeners();

      return _user != null;
    }
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiService.instance.post(
      '/login',
      auth: false,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    return _applyAuthResponse(data);
  }

  Future<User> register({
    required String name,
    required String nim,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final data = await ApiService.instance.post(
      '/register',
      auth: false,
      body: {
        'name': name.trim(),
        'nim': nim.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    return _applyAuthResponse(data);
  }

  Future<void> logout() async {
    try {
      await ApiService.instance.post('/logout');
    } on ApiException {
      // Token mungkin sudah tidak valid; tetap bersihkan session lokal.
    }

    await clearSession();
  }

  Future<User> updateProfile({
    required String name,
    required String nim,
    required String email,
  }) async {
    final data = await ApiService.instance.put(
      '/profile',
      body: {
        'name': name.trim(),
        'nim': nim.trim(),
        'email': email.trim(),
      },
    );

    final map = jsonMap(data);

    if (map != null) {
      _user = User.fromJson(map);
      await AppStorage.saveUser(map);
      notifyListeners();
    }

    return _user!;
  }

  Future<void> clearSession() async {
    _user = null;
    await AppStorage.clear();
    notifyListeners();
  }

  /// Dipanggil ApiService ketika token ditolak (401).
  Future<void> handleUnauthorized() async {
    if (_handlingUnauthorized) {
      return;
    }

    _handlingUnauthorized = true;
    await clearSession();

    final navigator = appNavigatorKey.currentState;
    navigator?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);

    _handlingUnauthorized = false;
  }

  Future<User> _applyAuthResponse(dynamic data) async {
    final map = jsonMap(data) ?? const <String, dynamic>{};
    final token = jsonString(map['token']);
    final userJson = jsonMap(map['user']);

    if (token.isEmpty || userJson == null) {
      throw ApiException('Respons login tidak valid.');
    }

    _user = User.fromJson(userJson);
    await AppStorage.saveToken(token);
    await AppStorage.saveUser(userJson);
    notifyListeners();

    return _user!;
  }
}
