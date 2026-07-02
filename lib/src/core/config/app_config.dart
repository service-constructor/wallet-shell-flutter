/// Environment configuration, overridable at build time with --dart-define.
///
/// Unlike the web shell there is no BFF: the app talks directly to the unified
/// gateway (`/v1/*`, Bearer auth). GATEWAY_BASE points at that gateway.
class AppConfig {
  AppConfig._();

  /// Base URL of the unified gateway (auth + platform routes under one origin).
  static const String gatewayBase = String.fromEnvironment(
    'GATEWAY_BASE',
    defaultValue: 'https://api.serviceconstructor.dev',
  );

  /// Fallback mini-app URL for a catalog entry with no miniappUrl configured.
  static const String fallbackMiniAppUrl = String.fromEnvironment(
    'FALLBACK_MINIAPP_URL',
    defaultValue: 'https://image-miniapp.serviceconstructor.dev',
  );
}
