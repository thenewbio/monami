import 'dart:convert';
import 'package:monami/src/data/local/local_cache.dart';
import 'package:monami/src/data/local/secure_storage.dart';
import 'package:monami/src/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheImpl implements LocalCache {
  late final _logger = Logger(LocalCacheImpl);
  static const _userId = 'userId';
  static const _privateKey = 'privateEncKey';
  static const _publicKey = 'publicEncKey';
  static const _savedStories = 'savedstories';
  static const _loginStatus = 'loginStatus';

  late SecureStorage _storage;
  late SharedPreferences _sharedPreferences;

  LocalCacheImpl({
    required SecureStorage storage,
    required SharedPreferences sharedPreferences,
  }) {
    _storage = storage;
    _sharedPreferences = sharedPreferences;
  }

  @override
  Future<void> deleteUserId() async {
    try {
      await _storage.delete(_userId);
    } catch (e) {
      _logger.log(e);
    }
  }

  @override
  Object? getFromLocalCache(String key) {
    try {
      return _sharedPreferences.get(key);
    } catch (e) {
      _logger.log(e);
      return null;
    }
  }

  @override
  Future<String> getUserId() async {
    return (await _storage.read(_userId)) ?? "";
  }

  @override
  Future<void> removeFromLocalCache(String key) async {
    await _sharedPreferences.remove(key);
  }

  @override
  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userId, value: userId);
    } catch (e) {
      _logger.log(e);
    }
  }

  @override
  Future<void> saveToLocalCache({required String key, required value}) async {
    _logger.log('Data being saved: key: $key, value: $value');

    if (value is String) {
      await _sharedPreferences.setString(key, value);
    }
    if (value is bool) {
      await _sharedPreferences.setBool(key, value);
    }
    if (value is int) {
      await _sharedPreferences.setInt(key, value);
    }
    if (value is double) {
      await _sharedPreferences.setDouble(key, value);
    }
    if (value is List<String>) {
      await _sharedPreferences.setStringList(key, value);
    }
    if (value is Map) {
      await _sharedPreferences.setString(key, json.encode(value));
    }
  }

  @override
  Future<void> clearCache() async {
    await _storage.delete(_userId);
    await _storage.delete(_privateKey);
    await _storage.delete(_publicKey);
  }

  @override
  Future<String> getPrivateKey() async {
    return (await _storage.read(_privateKey)) ?? "";
  }

  @override
  Future<String> getPublicKey() async {
    return (await _storage.read(_publicKey)) ?? "";
  }

  @override
  Future<void> saveKeys({
    required String privateKey,
    required String publicKey,
  }) async {
    try {
      await _storage.write(key: _privateKey, value: privateKey);
      await _storage.write(key: _publicKey, value: publicKey);
    } catch (e) {
      _logger.log(e);
    }
  }

  @override
  bool getLoginStatus() {
    try {
      return getFromLocalCache(_loginStatus) as bool? ?? false;
    } catch (e) {
      _logger.log(e);
    }
    return false;
  }

  @override
  Future<void> persistLoginStatus(bool isLoggedIn) async {
    try {
      await _sharedPreferences.setBool(_loginStatus, isLoggedIn);
    } catch (e) {
      _logger.log(e);
    }
  }
}
