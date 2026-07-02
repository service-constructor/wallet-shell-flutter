import '../../core/crypto/sealed_box.dart';
import '../../core/security/token_store.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/currency.dart';
import '../../domain/entities/mini_app.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/pay.dart';
import '../../domain/entities/user.dart';
import '../network/api_client.dart';

/// The app's single gateway-facing repository — the mobile counterpart of the
/// web `api.ts` + BFF. Every method maps to a `/v1/*` gateway route; identity is
/// carried by the stored JWT (Bearer), never in request bodies.
class WalletRepository {
  WalletRepository({
    required ApiClient api,
    required TokenStore tokens,
    SealedBoxCrypto sealedBox = const SealedBoxCrypto(),
  })  : _api = api,
        _tokens = tokens,
        _sealedBox = sealedBox;

  final ApiClient _api;
  final TokenStore _tokens;
  final SealedBoxCrypto _sealedBox;

  // --- Auth ----------------------------------------------------------------

  Future<AuthResult> register(String login, String password) =>
      _authenticate('/v1/auth/register', login, password);

  Future<AuthResult> login(String login, String password) =>
      _authenticate('/v1/auth/login', login, password);

  Future<AuthResult> _authenticate(String path, String login, String password) async {
    final json = await _api.postJson(path, {'login': login, 'password': password});
    final result = AuthResult.fromJson(json);
    await _tokens.save(result.token);
    return result;
  }

  /// Validates a stored token by fetching the current user. Throws
  /// ApiException(401) if the token is gone/expired.
  Future<User> me() async {
    final json = await _api.getJson('/v1/auth/me');
    return User.fromJson(json);
  }

  /// Logout is purely local on mobile: drop the token. No network call.
  Future<void> logout() => _tokens.clear();

  // --- Catalogs ------------------------------------------------------------

  Future<List<Account>> accounts() async {
    final json = await _api.getJson('/v1/auth/accounts');
    final list = (json['accounts'] as List<dynamic>? ?? const []);
    return list.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Currency>> currencies() async {
    final json = await _api.getJson('/v1/currencies');
    final list = (json['currencies'] as List<dynamic>? ?? const []);
    return list.map((e) => Currency.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MiniApp>> apps() async {
    // The platform returns {services: ServiceInfo[]}; the shell calls them apps.
    final json = await _api.getJson('/v1/services');
    final list = (json['services'] as List<dynamic>? ?? const []);
    return list.map((e) => MiniApp.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Order>> orders() async {
    final json = await _api.getJson('/v1/orders');
    final list = (json['orders'] as List<dynamic>? ?? const []);
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Simulate an on-chain deposit (demo only; the gateway rejects it for real
  /// currencies). Returns whether it was applied (idempotent on ref).
  Future<bool> deposit({
    required String memo,
    required String ref,
    required String amount,
    required int currencyId,
  }) async {
    final json = await _api.postJson('/v1/auth/deposits', {
      'memo': memo,
      'ref': ref,
      'amount': amount,
      'currencyId': currencyId,
    });
    return json['applied'] as bool? ?? false;
  }

  // --- Payment -------------------------------------------------------------

  /// Builds the consent preview locally from the quote + the user's accounts
  /// (the BFF's `/api/prepare` has no gateway equivalent). Eligible wallets are
  /// those whose currency matches the quote currency.
  Future<PreparePreview> prepare(Map<String, dynamic> quote) async {
    final all = await accounts();
    final currencyId = _asInt(quote['currencyId']);
    final wallets = all
        .where((a) => a.currencyId == currencyId)
        .map((a) => EligibleWallet(walletId: a.walletId, currencyId: a.currencyId))
        .toList();
    return PreparePreview(
      amount: (quote['amount'] ?? '').toString(),
      currencyId: currencyId,
      description: quote['description'] as String?,
      serviceId: quote['serviceId'] as String?,
      wallets: wallets,
    );
  }

  /// Runs the payment saga. Mirrors the BFF: sends {quote, selectedWalletId,
  /// selectedWalletCurrencyId (string)} and omits consent (CONSENT_MODE=none).
  Future<PayResult> pay(Map<String, dynamic> quote, String selectedWalletId) async {
    final json = await _api.postJson('/v1/services/pay', {
      'quote': quote,
      'selectedWalletId': selectedWalletId,
      'selectedWalletCurrencyId': _asInt(quote['currencyId']).toString(),
    });
    return PayResult.fromJson(json);
  }

  // --- Mini-app open (sealed-box user id) ----------------------------------

  /// Computes the sealed `encUserId` a mini-app receives: fetch the service's
  /// public key, then encrypt [userId] to it. Reproduces the BFF `open-service`
  /// without a network round-trip for identity (we already hold the user).
  Future<String> encUserIdFor({required String serviceId, required String userId}) async {
    final info = await _api.getJson('/v1/services/${Uri.encodeComponent(serviceId)}/info');
    final pubKey = info['encryptionPublicKey'] as String?;
    if (pubKey == null || pubKey.isEmpty) {
      throw StateError('service has no encryption key configured');
    }
    return _sealedBox.encryptUserId(userId: userId, encryptionPublicKeyBase64: pubKey);
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
