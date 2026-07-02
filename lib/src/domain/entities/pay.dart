import 'package:equatable/equatable.dart';

/// A wallet eligible to fund a payment (matches the quote currency).
class EligibleWallet extends Equatable {
  const EligibleWallet({required this.walletId, required this.currencyId});

  final String walletId;
  final int currencyId;

  @override
  List<Object?> get props => [walletId, currencyId];
}

/// The consent-sheet data shown before paying. Unlike the web app there is no
/// BFF `/api/prepare`: the shell builds this locally from the quote plus the
/// user's accounts (filtered to the quote currency).
class PreparePreview extends Equatable {
  const PreparePreview({
    required this.amount,
    required this.currencyId,
    required this.wallets,
    this.description,
    this.serviceId,
  });

  final String amount;
  final int currencyId;
  final List<EligibleWallet> wallets;
  final String? description;
  final String? serviceId;

  @override
  List<Object?> get props => [amount, currencyId, wallets, serviceId];
}

/// The order returned by /v1/services/pay, handed back to the mini-app.
class PayResult extends Equatable {
  const PayResult({
    required this.orderId,
    required this.state,
    this.externalRef,
    this.amount,
    this.fee,
    this.net,
  });

  final String orderId;
  final String state;
  final String? externalRef;
  final String? amount;
  final String? fee;
  final String? net;

  factory PayResult.fromJson(Map<String, dynamic> json) => PayResult(
        orderId: json['orderId'] as String? ?? '',
        state: json['state'] as String? ?? '',
        externalRef: json['externalRef'] as String?,
        amount: json['amount'] as String?,
        fee: json['fee'] as String?,
        net: json['net'] as String?,
      );

  /// The raw order JSON, to relay back over the bridge as the pay result.
  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'state': state,
        if (externalRef != null) 'externalRef': externalRef,
        if (amount != null) 'amount': amount,
        if (fee != null) 'fee': fee,
        if (net != null) 'net': net,
      };

  @override
  List<Object?> get props => [orderId, state];
}
