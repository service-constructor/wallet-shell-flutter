/// Thrown by the API client when the gateway returns a non-2xx response.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  /// The session is gone/invalid (gateway rejected the bearer token).
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
