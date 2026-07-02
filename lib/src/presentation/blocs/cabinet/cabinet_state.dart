part of 'cabinet_bloc.dart';

/// Cabinet data is best-effort: individual catalogs load independently and the
/// UI renders whatever arrived. A single state carries them all plus flags.
class CabinetState extends Equatable {
  const CabinetState({
    this.loading = false,
    this.accounts = const [],
    this.currencies = const [],
    this.apps = const [],
    this.orders = const [],
    this.note,
  });

  final bool loading;
  final List<Account> accounts;
  final List<Currency> currencies;
  final List<MiniApp> apps;
  final List<Order> orders;

  /// Transient message from the last deposit action (shown then cleared).
  final String? note;

  CabinetState copyWith({
    bool? loading,
    List<Account>? accounts,
    List<Currency>? currencies,
    List<MiniApp>? apps,
    List<Order>? orders,
    String? note,
    bool clearNote = false,
  }) {
    return CabinetState(
      loading: loading ?? this.loading,
      accounts: accounts ?? this.accounts,
      currencies: currencies ?? this.currencies,
      apps: apps ?? this.apps,
      orders: orders ?? this.orders,
      note: clearNote ? null : (note ?? this.note),
    );
  }

  @override
  List<Object?> get props => [loading, accounts, currencies, apps, orders, note];
}
