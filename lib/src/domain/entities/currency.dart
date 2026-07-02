import 'package:equatable/equatable.dart';

import '../../core/json/parse.dart';

/// A ledger currency. `isReal=false` is test money (mock-fundable via the demo
/// deposit endpoint); real money is funded only by on-chain deposits.
class Currency extends Equatable {
  const Currency({
    required this.id,
    required this.code,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.isReal,
  });

  final int id;
  final String code;
  final String name;
  final String symbol;
  final int decimals;
  final bool isReal;

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        id: parseInt64(json['id']),
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        symbol: json['symbol'] as String? ?? '',
        decimals: parseInt64(json['decimals']),
        isReal: json['isReal'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, code];
}
