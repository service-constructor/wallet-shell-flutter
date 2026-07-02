import 'package:flutter/material.dart';

import '../../domain/entities/currency.dart';
import '../../domain/entities/pay.dart';
import '../../theme/app_theme.dart';

/// Payment confirmation as a modal bottom sheet (the mobile replacement for the
/// web ConsentModal). Shows amount/description and a wallet picker, and returns
/// the chosen walletId on confirm, or null on cancel/dismiss.
///
/// Call via [show]; the result is the selected wallet id (null = declined).
class ConsentSheet extends StatefulWidget {
  const ConsentSheet({super.key, required this.preview, required this.currencies});

  final PreparePreview preview;
  final List<Currency> currencies;

  static Future<String?> show(
    BuildContext context, {
    required PreparePreview preview,
    required List<Currency> currencies,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ConsentSheet(preview: preview, currencies: currencies),
    );
  }

  @override
  State<ConsentSheet> createState() => _ConsentSheetState();
}

class _ConsentSheetState extends State<ConsentSheet> {
  String? _walletId;

  @override
  void initState() {
    super.initState();
    final wallets = widget.preview.wallets;
    if (wallets.isNotEmpty) _walletId = wallets.first.walletId;
  }

  String _currencyLabel(int id) {
    final c = widget.currencies.where((c) => c.id == id).firstOrNull;
    if (c == null) return 'cur #$id';
    return c.symbol.isNotEmpty ? '${c.symbol} ${c.code}' : c.code;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.preview;
    final noWallet = p.wallets.isEmpty;

    return SafeArea(
      child: Padding(
        // Lift content above the keyboard/home indicator.
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.separator,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Confirm payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(p.amount,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text(_currencyLabel(p.currencyId),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              ],
            ),
            if (p.description != null) ...[
              const SizedBox(height: 6),
              Text(p.description!, style: const TextStyle(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 20),
            if (noWallet)
              const Text(
                'No eligible wallet for this currency.',
                style: TextStyle(color: AppColors.accentRed),
              )
            else ...[
              const Text('Pay from', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _walletId,
                items: [
                  for (final w in p.wallets)
                    DropdownMenuItem(value: w.walletId, child: Text(w.walletId)),
                ],
                onChanged: (v) => setState(() => _walletId = v),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (noWallet || _walletId == null)
                        ? null
                        : () => Navigator.of(context).pop(_walletId),
                    child: const Text('Pay'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
