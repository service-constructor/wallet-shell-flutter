import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_config.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../domain/entities/mini_app.dart';
import '../../domain/entities/user.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/cabinet/cabinet_bloc.dart';
import '../miniapp/mini_app_screen.dart';
import 'home_view.dart';
import 'orders_view.dart';

/// The signed-in dashboard: a Home tab (accounts + apps) and a My Orders tab.
/// Opening an app pushes the WebView mini-app host.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    context.read<CabinetBloc>().add(const CabinetLoadRequested());
  }

  Future<void> _openApp(MiniApp app) async {
    final repo = context.read<WalletRepository>();
    final cabinet = context.read<CabinetBloc>();
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MiniAppScreen(
          repo: repo,
          user: widget.user,
          serviceId: app.serviceId,
          title: app.name,
          url: app.miniAppUrl ?? AppConfig.fallbackMiniAppUrl,
          currencies: cabinet.state.currencies,
        ),
      ),
    );
    // A payment inside the app may have changed balances and added an order.
    if (paid == true) cabinet.add(const CabinetRefreshAfterPay());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🪪 Cabinet'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(widget.user.login,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: BlocConsumer<CabinetBloc, CabinetState>(
        listenWhen: (prev, curr) => curr.note != null && prev.note != curr.note,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.note!)));
        },
        builder: (context, state) {
          if (state.loading && state.accounts.isEmpty && state.apps.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          Future<void> reload() async {
            context.read<CabinetBloc>().add(const CabinetLoadRequested());
          }

          if (_tab == 0) {
            return HomeView(
              accounts: state.accounts,
              currencies: state.currencies,
              apps: state.apps,
              onRefresh: reload,
              onOpenApp: _openApp,
              onSimulateDeposit: (a) => context
                  .read<CabinetBloc>()
                  .add(CabinetDepositRequested(memo: a.depositMemo, currencyId: a.currencyId)),
            );
          }
          return OrdersView(
            orders: state.orders,
            apps: state.apps,
            currencies: state.currencies,
            onRefresh: reload,
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'My orders'),
        ],
      ),
    );
  }
}
