import 'package:equatable/equatable.dart';

/// The authenticated user. All users in the demo share one TON deposit address
/// but each has a unique deposit memo tag; deposits are routed by memo.
class User extends Equatable {
  const User({
    required this.userId,
    required this.login,
    required this.tonAddress,
    required this.depositMemo,
    required this.walletId,
  });

  final String userId;
  final String login;
  final String tonAddress;
  final String depositMemo;
  final String walletId;

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['userId'] as String? ?? '',
        login: json['login'] as String? ?? '',
        tonAddress: json['tonAddress'] as String? ?? '',
        depositMemo: json['depositMemo'] as String? ?? '',
        walletId: json['walletId'] as String? ?? '',
      );

  @override
  List<Object?> get props => [userId, login, walletId];
}
