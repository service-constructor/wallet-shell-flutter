import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/wallet_repository.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/currency.dart';
import '../../../domain/entities/mini_app.dart';
import '../../../domain/entities/order.dart';

part 'cabinet_event.dart';
part 'cabinet_state.dart';

/// Holds the signed-in dashboard data: accounts, currency catalog, mini-app
/// catalog, and order history. Each catalog is best-effort — a failed fetch
/// leaves that slice empty rather than failing the whole screen.
class CabinetBloc extends Bloc<CabinetEvent, CabinetState> {
  CabinetBloc(this._repo) : super(const CabinetState()) {
    on<CabinetLoadRequested>(_onLoad);
    on<CabinetRefreshAfterPay>(_onRefreshAfterPay);
    on<CabinetDepositRequested>(_onDeposit);
  }

  final WalletRepository _repo;

  Future<void> _onLoad(CabinetLoadRequested event, Emitter<CabinetState> emit) async {
    emit(state.copyWith(loading: true, clearNote: true));
    final results = await Future.wait([
      _repo.accounts().catchError((_) => <Account>[]),
      _repo.currencies().catchError((_) => <Currency>[]),
      _repo.apps().catchError((_) => <MiniApp>[]),
      _repo.orders().catchError((_) => <Order>[]),
    ]);
    emit(state.copyWith(
      loading: false,
      accounts: results[0] as List<Account>,
      currencies: results[1] as List<Currency>,
      apps: results[2] as List<MiniApp>,
      orders: results[3] as List<Order>,
    ));
  }

  Future<void> _onRefreshAfterPay(CabinetRefreshAfterPay event, Emitter<CabinetState> emit) async {
    final results = await Future.wait([
      _repo.accounts().catchError((_) => <Account>[]),
      _repo.orders().catchError((_) => <Order>[]),
    ]);
    emit(state.copyWith(
      accounts: results[0] as List<Account>,
      orders: results[1] as List<Order>,
    ));
  }

  Future<void> _onDeposit(CabinetDepositRequested event, Emitter<CabinetState> emit) async {
    try {
      // ref must be unique per deposit (ledger idempotency).
      final ref = 'demo-${event.memo}-${DateTime.now().microsecondsSinceEpoch}';
      final applied = await _repo.deposit(
        memo: event.memo,
        ref: ref,
        amount: '10.00',
        currencyId: event.currencyId,
      );
      final accounts = await _repo.accounts().catchError((_) => state.accounts);
      emit(state.copyWith(
        accounts: accounts,
        note: applied ? 'Deposited 10.00' : 'Deposit already applied',
      ));
    } catch (e) {
      emit(state.copyWith(note: e.toString()));
    }
  }
}
