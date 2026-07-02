import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_shell_flutter/src/core/json/parse.dart';
import 'package:wallet_shell_flutter/src/domain/entities/account.dart';

void main() {
  group('parseInt64', () {
    test('accepts the protojson int64-as-string form', () {
      expect(parseInt64('1'), 1);
      expect(parseInt64('42'), 42);
    });
    test('accepts a plain number', () {
      expect(parseInt64(7), 7);
      expect(parseInt64(3.0), 3);
    });
    test('falls back on null/garbage', () {
      expect(parseInt64(null), 0);
      expect(parseInt64('abc', fallback: -1), -1);
    });
  });

  test('Account parses currencyId from a string (live gateway shape)', () {
    final a = Account.fromJson(const {
      'walletId': 'wlt_1',
      'currencyId': '1',
      'available': '336',
      'held': '0',
      'tonAddress': 'UQ...',
      'depositMemo': 'memo-x',
    });
    expect(a.currencyId, 1);
    expect(a.available, '336');
  });
}
