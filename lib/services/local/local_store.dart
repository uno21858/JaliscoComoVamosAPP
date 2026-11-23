import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento cifrado del teléfono (Keychain en iOS, Keystore en
/// Android). Aquí van el borrador de encuesta (RF-ENC-07) y, más adelante,
/// el token de sesión. Nunca SharedPreferences en texto plano.
class LocalStore {
  LocalStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (error) {
      debugPrint('LocalStore.read($key) falló: $error');
      return null;
    }
  }

  Future<bool> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return true;
    } catch (error) {
      debugPrint('LocalStore.write($key) falló: $error');
      return false;
    }
  }

  /// Borra todas las llaves que empiezan con [prefix].
  Future<void> deletePrefix(String prefix) async {
    try {
      for (final key in (await _storage.readAll()).keys.where((k) => k.startsWith(prefix)).toList()) {
        await _storage.delete(key: key);
      }
    } catch (error) {
      debugPrint('LocalStore.deletePrefix($prefix) falló: $error');
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (error) {
      debugPrint('LocalStore.delete($key) falló: $error');
    }
  }
}
