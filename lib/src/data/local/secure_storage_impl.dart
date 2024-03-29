import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:monami/src/data/local/secure_storage.dart';
import 'package:monami/src/utils/logger.dart';

class SecureStorageImpl implements SecureStorage {
  late final _logger = Logger(SecureStorageImpl);
  late FlutterSecureStorage _storage;

  SecureStorageImpl({FlutterSecureStorage? storage}) {
    _storage = storage ?? const FlutterSecureStorage();
  }

  @override
  Future<bool> delete(String key) async {
    try {
      await _storage.delete(key: key);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      _logger.log(e);
      return null;
    }
  }

  @override
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      _logger.log(e);
    }
  }
}
