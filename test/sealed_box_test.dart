import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pinenacl/x25519.dart';
import 'package:wallet_shell_flutter/src/core/crypto/sealed_box.dart';

void main() {
  group('SealedBoxCrypto', () {
    test('encrypts a user id that the recipient key can decrypt', () {
      // Recipient = the mini-app service. In production only it holds the
      // private key; here we generate a pair so we can prove the round-trip.
      final recipient = PrivateKey.generate();
      final pubB64 = base64.encode(recipient.publicKey.toList());

      const userId = 'usr_f37c9c2e86fd45f686b847d6516909fe';
      final encB64 = const SealedBoxCrypto()
          .encryptUserId(userId: userId, encryptionPublicKeyBase64: pubB64);

      // Output is standard base64 of the sealed box: 32 (ephemeral pk) + msg + 16 (MAC).
      final sealed = base64.decode(encB64);
      expect(sealed.length, 32 + userId.length + 16);

      final opened = SealedBox(recipient).decrypt(sealed);
      expect(utf8.decode(opened), userId);
    });

    test('produces a different ciphertext each call (ephemeral key)', () {
      final recipient = PrivateKey.generate();
      final pubB64 = base64.encode(recipient.publicKey.toList());
      const crypto = SealedBoxCrypto();

      final a = crypto.encryptUserId(userId: 'u1', encryptionPublicKeyBase64: pubB64);
      final b = crypto.encryptUserId(userId: 'u1', encryptionPublicKeyBase64: pubB64);
      expect(a, isNot(equals(b)));
    });
  });
}
