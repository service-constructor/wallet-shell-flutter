import 'dart:convert';

import 'package:pinenacl/x25519.dart';

/// Sealed-box encryption of the user id for a mini-app, reproducing the web
/// BFF's `sodium.crypto_box_seal`.
///
/// libsodium sealed box: generate an ephemeral X25519 keypair, derive a nonce =
/// blake2b(ephemeral_pk ‖ recipient_pk), encrypt with crypto_box (X25519 +
/// XSalsa20-Poly1305), and output `ephemeral_pk ‖ ciphertext+MAC`. Only the
/// mini-app service (holder of the recipient private key) can open it; the
/// sender is anonymous. pinenacl's [SealedBox] implements exactly this format,
/// so the output is byte-compatible with the web shell.
class SealedBoxCrypto {
  const SealedBoxCrypto();

  /// Encrypts [userId] to the service's X25519 public key.
  ///
  /// [encryptionPublicKeyBase64] is the raw 32-byte public key in standard
  /// (RFC 4648, padded) base64, exactly as the gateway returns it in
  /// ServiceInfo.encryptionPublicKey. Returns the sealed box in standard base64
  /// — the `encUserId` the mini-app hands to its backend.
  String encryptUserId({
    required String userId,
    required String encryptionPublicKeyBase64,
  }) {
    final pubBytes = base64.decode(encryptionPublicKeyBase64);
    final sealed = SealedBox(PublicKey(pubBytes)).encrypt(
      utf8.encode(userId),
    );
    return base64.encode(sealed);
  }
}
