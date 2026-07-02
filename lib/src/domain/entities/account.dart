import 'package:equatable/equatable.dart';

import '../../core/json/parse.dart';

/// One ledger account (one per currency). `available`/`held` are decimal
/// strings (never parse to double for money — display as-is).
class Account extends Equatable {
  const Account({
    required this.walletId,
    required this.currencyId,
    required this.tonAddress,
    required this.depositMemo,
    required this.available,
    required this.held,
  });

  final String walletId;
  final int currencyId;
  final String tonAddress;
  final String depositMemo;
  final String available;
  final String held;

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        walletId: json['walletId'] as String? ?? '',
        currencyId: parseInt64(json['currencyId']),
        tonAddress: json['tonAddress'] as String? ?? '',
        depositMemo: json['depositMemo'] as String? ?? '',
        available: json['available'] as String? ?? '0',
        held: json['held'] as String? ?? '0',
      );

  @override
  List<Object?> get props => [walletId, currencyId, available, held];
}
