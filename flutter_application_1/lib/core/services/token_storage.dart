import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _keyToken      = 'auth_token';
  static const _keyPersonalId = 'personal_id';
  static const _keyNombre     = 'nombre_completo';
  static const _keyTipo       = 'tipo';

  final _storage = const FlutterSecureStorage();
  String? _cachedToken;

  String? get token => _cachedToken;

  Future<void> setToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: _keyToken, value: token);
  }

  Future<void> setUserData({
    required String personalId,
    required String nombreCompleto,
    required String tipo,
  }) async {
    await Future.wait([
      _storage.write(key: _keyPersonalId, value: personalId),
      _storage.write(key: _keyNombre,     value: nombreCompleto),
      _storage.write(key: _keyTipo,       value: tipo),
    ]);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await Future.wait([
      _storage.delete(key: _keyToken),
      _storage.delete(key: _keyPersonalId),
      _storage.delete(key: _keyNombre),
      _storage.delete(key: _keyTipo),
    ]);
  }

  Future<String?> getToken() async {
    _cachedToken ??= await _storage.read(key: _keyToken);
    return _cachedToken;
  }

  Future<bool> hasToken() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  Future<String?> getNombre()     => _storage.read(key: _keyNombre);
  Future<String?> getPersonalId() => _storage.read(key: _keyPersonalId);
  Future<String?> getTipo()       => _storage.read(key: _keyTipo);
}
