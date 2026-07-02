import 'package:flutter/material.dart';

import '../../domain/entities/account.dart';
import '../../domain/entities/currency.dart';
import '../../domain/entities/mini_app.dart';
import '../../theme/app_theme.dart';

/// The Home tab: the user's accounts (balances + deposit info) and the mini-app
/// catalog. Tapping an app calls [onOpenApp].
class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.accounts,
    required this.currencies,
    required this.apps,
    required this.onRefresh,
    required this.onOpenApp,
    required this.onSimulateDeposit,
  });

  final List<Account> accounts;
  final List<Currency> currencies;
  final List<MiniApp> apps;
  final Future<void> Function() onRefresh;
  final void Function(MiniApp app) onOpenApp;
  final void Function(Account account) onSimulateDeposit;

  Currency? _currency(int id) => currencies.where((c) => c.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Your accounts'),
          const SizedBox(height: 12),
          if (accounts.isEmpty)
            const Text('No accounts yet.', style: TextStyle(color: AppColors.textSecondary)),
          for (final a in accounts) ...[
            _AccountCard(
              account: a,
              currency: _currency(a.currencyId),
              onSimulateDeposit: () => onSimulateDeposit(a),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          const _SectionTitle('Apps'),
          const SizedBox(height: 12),
          if (apps.isEmpty)
            const Text('No apps available yet.',
                style: TextStyle(color: AppColors.textSecondary)),
          for (final app in apps) ...[
            _AppTile(app: app, onOpen: () => onOpenApp(app)),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700));
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.currency,
    required this.onSimulateDeposit,
  });

  final Account account;
  final Currency? currency;
  final VoidCallback onSimulateDeposit;

  @override
  Widget build(BuildContext context) {
    final label = currency?.code ?? 'cur #${account.currencyId}';
    final symbol = currency?.symbol ?? '';
    final isTestMoney = currency != null && !currency!.isReal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(account.available,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text(symbol.isNotEmpty ? '$symbol $label' : label,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            Text('held: ${account.held}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const Divider(height: 20),
            _kv('Wallet', account.walletId),
            const SizedBox(height: 6),
            _kv('Memo tag', account.depositMemo),
            const SizedBox(height: 12),
            if (isTestMoney)
              OutlinedButton(
                onPressed: onSimulateDeposit,
                child: const Text('Simulate deposit +10'),
              )
            else
              Text('Send $label to the deposit address with this memo tag to top up.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(k, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(v,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
        ],
      );
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app, required this.onOpen});
  final MiniApp app;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final icon = (app.iconUrl?.isNotEmpty ?? false) ? app.iconUrl! : '🧩';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (app.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(app.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(minimumSize: const Size(84, 40)),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}
