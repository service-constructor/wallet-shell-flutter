import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/error/exceptions.dart';
import '../../core/security/token_store.dart';

/// Thin JSON client over the unified gateway. Attaches `Authorization: Bearer`
/// from the [TokenStore] on every request (public routes tolerate a missing
/// token) and decodes JSON bodies. There is no BFF hop — this talks straight to
/// `/v1/*`.
class ApiClient {
  ApiClient({required TokenStore tokenStore, http.Client? httpClient})
      : _tokens = tokenStore,
        _http = httpClient ?? http.Client();

  final TokenStore _tokens;
  final http.Client _http;

  Uri _uri(String path) => Uri.parse('${AppConfig.gatewayBase}$path');

  Map<String, String> _headers() {
    final h = <String, String>{'Content-Type': 'application/json'};
    final t = _tokens.token;
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final res = await _http.get(_uri(path), headers: _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final res = await _http.post(_uri(path), headers: _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final Map<String, dynamic> data;
    try {
      data = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(res.statusCode, 'invalid response');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // The gateway reports failures as {"error": "..."} or {"message": "..."}.
      final msg = (data['error'] ?? data['message'] ?? 'request failed') as String;
      throw ApiException(res.statusCode, msg);
    }
    return data;
  }

  void close() => _http.close();
}
