import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class AuthService {
  AuthService._();

  static const _tokenKey = 'api_token';
  static const _roleKey = 'user_role';
  static const _userIdKey = 'user_id';

  static String? _cachedToken;
  static String? _cachedRole;
  static String? _cachedUserId;

  // ✅ Save Token
  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      html.window.sessionStorage[_tokenKey] = token; // session only
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    }
    _cachedToken = token;
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    if (kIsWeb) {
      _cachedToken = html.window.sessionStorage[_tokenKey];
    } else {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_tokenKey);
    }
    return _cachedToken;
  }

  static Future<void> clearToken() async {
    if (kIsWeb) {
      html.window.sessionStorage.remove(_tokenKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    }
    _cachedToken = null;
  }

  // ✅ Save Role
  static Future<void> saveRole(String role) async {
    if (kIsWeb) {
      html.window.sessionStorage[_roleKey] = role; // session only
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roleKey, role);
    }
    _cachedRole = role;
  }

  static Future<String?> getRole() async {
    if (_cachedRole != null) return _cachedRole;
    if (kIsWeb) {
      _cachedRole = html.window.sessionStorage[_roleKey];
    } else {
      final prefs = await SharedPreferences.getInstance();
      _cachedRole = prefs.getString(_roleKey);
    }
    return _cachedRole;
  }

  static Future<void> clearRole() async {
    if (kIsWeb) {
      html.window.sessionStorage.remove(_roleKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_roleKey);
    }
    _cachedRole = null;
  }

  // ✅ Save UserId
  static Future<void> saveUserId(String userId) async {
    if (kIsWeb) {
      html.window.sessionStorage[_userIdKey] = userId; // session only
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
    }
    _cachedUserId = userId;
  }

  static Future<String?> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    if (kIsWeb) {
      _cachedUserId = html.window.sessionStorage[_userIdKey];
    } else {
      final prefs = await SharedPreferences.getInstance();
      _cachedUserId = prefs.getString(_userIdKey);
    }
    return _cachedUserId;
  }

  static Future<void> clearUserId() async {
    if (kIsWeb) {
      html.window.sessionStorage.remove(_userIdKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
    }
    _cachedUserId = null;
  }
    static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ✅ Clear All
  static Future<void> clearAuth() async {
    await clearToken();
    await clearRole();
    await clearUserId();
  }
}
