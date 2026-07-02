import 'package:equatable/equatable.dart';

import '../../core/json/parse.dart';

/// One entry in the user's cross-mini-app order history. The mini-app is
/// identified only by `serviceId`; the UI joins it to the app catalog to show a
/// name/icon. `state` is an ORDER_STATE_* enum name.
class Order extends Equatable {
  const Order({
    required this.orderId,
    required this.serviceId,
    required this.state,
    this.walletId,
    this.amount,
    this.currencyId,
    this.fee,
    this.net,
    this.externalRef,
    this.createdAt,
    this.updatedAt,
  });

  final String orderId;
  final String serviceId;
  final String state;
  final String? walletId;
  final String? amount;
  final int? currencyId;
  final String? fee;
  final String? net;
  final String? externalRef;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderId: json['orderId'] as String? ?? '',
        serviceId: json['serviceId'] as String? ?? '',
        state: json['state'] as String? ?? 'ORDER_STATE_UNSPECIFIED',
        walletId: json['walletId'] as String?,
        amount: _nonEmpty(json['amount']),
        currencyId: json['currencyId'] == null ? null : parseInt64(json['currencyId']),
        fee: _nonEmpty(json['fee']),
        net: _nonEmpty(json['net']),
        externalRef: _nonEmpty(json['externalRef']),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );

  static String? _nonEmpty(dynamic v) {
    final s = v as String?;
    return (s == null || s.isEmpty) ? null : s;
  }

  static DateTime? _parseDate(dynamic v) {
    final s = v as String?;
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  @override
  List<Object?> get props => [orderId, state];
}
