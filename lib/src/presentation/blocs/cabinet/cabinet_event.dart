part of 'cabinet_bloc.dart';

sealed class CabinetEvent extends Equatable {
  const CabinetEvent();
  @override
  List<Object?> get props => [];
}

/// Load (or reload) every catalog: accounts, currencies, apps, orders.
class CabinetLoadRequested extends CabinetEvent {
  const CabinetLoadRequested();
}

/// Refresh only balances + orders (after a payment inside a mini-app).
class CabinetRefreshAfterPay extends CabinetEvent {
  const CabinetRefreshAfterPay();
}

/// Simulate a demo deposit to a test-money account, then refresh balances.
class CabinetDepositRequested extends CabinetEvent {
  const CabinetDepositRequested({required this.memo, required this.currencyId});
  final String memo;
  final int currencyId;
  @override
  List<Object?> get props => [memo, currencyId];
}
