import 'user.dart';

/// Response of /v1/auth/login and /v1/auth/register: a JWT plus the user. The
/// web BFF hid the token in a cookie; on mobile we keep it in secure storage.
class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final User user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String? ?? '',
        user: User.fromJson((json['user'] as Map<String, dynamic>?) ?? const {}),
      );
}
