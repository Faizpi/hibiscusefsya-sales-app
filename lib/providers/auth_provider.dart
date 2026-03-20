import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  UserModel? _user;
  bool _isLoading = false;

  String? get token => _token;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(AppConfig.tokenKey);
      final savedUser = prefs.getString(AppConfig.userKey);

      if (savedToken != null && savedUser != null) {
        _token = savedToken;
        _user = UserModel.fromJson(jsonDecode(savedUser));

        // Verify token is still valid
        try {
          final api = ApiService(token: _token);
          final response = await api.get('profile');
          _user = UserModel.fromJson(response['user']);
          await prefs.setString(AppConfig.userKey, jsonEncode(_user!.toJson()));
        } catch (_) {
          // Token expired, clear data
          await _clearAuth();
        }
      }
    } catch (_) {
      await _clearAuth();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final api = ApiService();
      final response = await api.post('login', body: {
        'email': email,
        'password': password,
        'device_name': 'flutter_mobile',
      });

      _token = response['token'];
      _user = UserModel.fromJson(response['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.tokenKey, _token!);
      await prefs.setString(AppConfig.userKey, jsonEncode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final api = ApiService(token: _token);
      await api.post('logout');
    } catch (_) {}

    await _clearAuth();
    notifyListeners();
  }

  Future<void> _clearAuth() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
    await prefs.remove(AppConfig.userKey);
  }

  Future<void> updateProfile({
    required String name,
    String? noTelp,
    String? alamat,
  }) async {
    final api = ApiService(token: _token);
    final response = await api.put('profile', body: {
      'name': name,
      if (noTelp != null) 'no_telp': noTelp,
      if (alamat != null) 'alamat': alamat,
    });
    _user = UserModel.fromJson(response['user'] ?? response['data']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.userKey, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final api = ApiService(token: _token);
    await api.post('change-password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    });
  }

  Future<void> refreshProfile() async {
    if (_token == null) return;
    final api = ApiService(token: _token);
    final response = await api.get('profile');
    _user = UserModel.fromJson(response['user']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.userKey, jsonEncode(_user!.toJson()));
    notifyListeners();
  }
}
