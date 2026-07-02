import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/currency.dart';
import '../../domain/entities/mini_app.dart';
import '../../domain/entities/order.dart';
import '../../theme/app_theme.dart';
import 'order_state_ui.dart';

/// "My orders" — the user's order history across all mini-apps, newest first.
/// Orders carry only a serviceId, so we join them to the app catalog for a
/// name/icon and to the currency catalog for the amount label.
class OrdersView extends StatelessWidget {
  const OrdersView({
    super.key,
    required this.orders,
    required this.apps,
    required this.currencies,
    required this.onRefresh,
  });

  final List<Order> orders;
  final List<MiniApp> apps;
  final List<Currency> currencies;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No orders yet.\nOpen an app to make your first purchase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _OrderCard(
          order: orders[i],
          app: apps.where((a) => a.serviceId == orders[i].serviceId).firstOrNull,
          currencies: currencies,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.app, required this.currencies});

  final Order order;
  final MiniApp? app;
  final List<Currency> currencies;

  String _currencyLabel(int? id) {
    if (id == null) return '';
    final c = currencies.where((c) => c.id == id).firstOrNull;
    if (c == null) return 'cur #$id';
    return c.symbol.isNotEmpty ? '${c.symbol} ${c.code}' : c.code;
  }

  @override
  Widget build(BuildContext context) {
    final name = app?.name ?? order.serviceId;
    final icon = (app?.iconUrl?.isNotEmpty ?? false) ? app!.iconUrl! : '🧩';
    final st = OrderStateUi.of(order.state);
    final when = order.createdAt == null
        ? null
        : DateFormat.yMMMd().add_Hm().format(order.createdAt!.toLocal());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                _Badge(label: st.label, color: st.color),
              ],
            ),
            if (order.amount != null) ...[
              const SizedBox(height: 10),
              _kv('Amount', '${order.amount} ${_currencyLabel(order.currencyId)}',
                  strong: true),
            ],
            const SizedBox(height: 6),
            _kv('Order', order.orderId, mono: true),
            if (order.externalRef != null) ...[
              const SizedBox(height: 6),
              _kv('Reference', order.externalRef!, mono: true),
            ],
            if (when != null) ...[
              const SizedBox(height: 6),
              _kv('Placed', when),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {bool mono = false, bool strong = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(k, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: mono ? 'monospace' : null,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
