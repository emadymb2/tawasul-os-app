import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineStore {
  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(value));
  }

  Future<Map<String, dynamic>?> readJson(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(key);
    if (value == null || value.isEmpty) return null;
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  }

  Future<void> writeJsonList(String key, List<Map<String, dynamic>> values) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(values));
  }

  Future<List<Map<String, dynamic>>> readJsonList(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(key);
    if (value == null || value.isEmpty) return const [];
    final decoded = jsonDecode(value);
    if (decoded is! List) return const [];
    return decoded.whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList();
  }

  Future<void> writeString(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  Future<String?> readString(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  Future<void> remove(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }
}
