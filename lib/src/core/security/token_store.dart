import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT in the platform keystore/keychain. This is the mobile
/// counterpart of the web BFF's httpOnly `sc_session` cookie: the token never
/// leaves the device except as an `Authorization: Bearer` header to the gateway.
class TokenStore {
  TokenStore(this._storage);

  final FlutterSecureStorage _storage;
  static const _key = 'sc_jwt';

  // Cached in memory so the API client can attach it synchronously per request
  // without an async keystore read on the hot path.
  String? _cached;

  /// Loads the token from secure storage into the in-memory cache. Call once on
  /// startup before the first authenticated request.
  Future<String?> load() async {
    _cached = await _storage.read(key: _key);
    return _cached;
  }

  String? get token => _cached;

  Future<void> save(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}
