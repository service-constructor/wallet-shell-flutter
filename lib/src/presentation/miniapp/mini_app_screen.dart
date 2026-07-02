import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/app_config.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../domain/entities/currency.dart';
import '../../domain/entities/user.dart';
import '../../theme/app_theme.dart';
import '../widgets/consent_sheet.dart';
import 'bridge_protocol.dart';

/// Hosts a mini-app in a full-screen WebView and is the trusted shell behind the
/// postMessage bridge. The mini-app requests context/prepare/pay; the shell
/// serves them, showing the consent bottom sheet and performing the
/// authenticated pay itself (the mini-app never sees the session or pays
/// directly). Ported from the web MiniAppHost + ConsentModal.
///
/// Pops with `true` if a payment completed (so the caller can refresh balances).
class MiniAppScreen extends StatefulWidget {
  const MiniAppScreen({
    super.key,
    required this.repo,
    required this.user,
    required this.serviceId,
    required this.title,
    required this.url,
    required this.currencies,
  });

  final WalletRepository repo;
  final User user;
  final String serviceId;
  final String title;
  final String url;
  final List<Currency> currencies;

  @override
  State<MiniAppScreen> createState() => _MiniAppScreenState();
}

class _MiniAppScreenState extends State<MiniAppScreen> {
  late final WebViewController _controller;
  String _encUserId = '';
  bool _ready = false;
  bool _paid = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Precompute the sealed user id BEFORE loading the page, so getContext can
    // answer immediately.
    try {
      _encUserId = await widget.repo.encUserIdFor(
        serviceId: widget.serviceId,
        userId: widget.user.userId,
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to open service: $e');
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.backgroundPrimary)
      ..addJavaScriptChannel(Bridge.jsChannel, onMessageReceived: _onBridgeMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _controller.runJavaScript(Bridge.injectedJs),
        ),
      )
      ..loadRequest(Uri.parse(widget.url.isEmpty ? AppConfig.fallbackMiniAppUrl : widget.url));

    setState(() {
      _controller = controller;
      _ready = true;
    });
  }

  // A bridge request arrived from the mini-app. Dispatch, then deliver the
  // response back into the page keyed by the request id.
  Future<void> _onBridgeMessage(JavaScriptMessage message) async {
    Map<String, dynamic> req;
    try {
      req = jsonDecode(message.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final id = req['id'];
    Map<String, dynamic> response;
    try {
      final result = await _handle(req);
      response = {'id': id, 'ok': true, 'result': result};
    } catch (e) {
      response = {'id': id, 'ok': false, 'error': e.toString()};
    }
    await _deliver(response);
  }

  Future<Object?> _handle(Map<String, dynamic> req) async {
    switch (req['type'] as String?) {
      case 'getContext':
        // encUserId is the trusted identity (only the service can decrypt it);
        // userId is a plaintext UI hint only.
        return {'userId': widget.user.userId, 'encUserId': _encUserId};
      case 'prepare':
        final preview = await widget.repo.prepare(_asQuote(req['quote']));
        return {
          'amount': preview.amount,
          'currencyId': preview.currencyId,
          'description': preview.description,
          'serviceId': preview.serviceId,
          'wallets': [
            for (final w in preview.wallets)
              {'walletId': w.walletId, 'currencyId': w.currencyId},
          ],
        };
      case 'pay':
        final quote = _asQuote(req['quote']);
        final preview = await widget.repo.prepare(quote);
        if (!mounted) return null;
        final walletId = await ConsentSheet.show(
          context,
          preview: preview,
          currencies: widget.currencies,
        );
        if (walletId == null) return null; // user declined
        final result = await widget.repo.pay(quote, walletId);
        _paid = true;
        return result.toJson();
      default:
        throw StateError('unknown bridge request');
    }
  }

  Map<String, dynamic> _asQuote(dynamic v) =>
      v is Map<String, dynamic> ? v : <String, dynamic>{};

  Future<void> _deliver(Map<String, dynamic> response) async {
    // Pass the JSON as a single-quoted JS string argument (escape for safety).
    final json = jsonEncode(response);
    final escaped = jsonEncode(json); // double-encode -> a JS string literal
    await _controller.runJavaScript('window.__scDeliver($escaped);');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Report whether a payment happened so the cabinet refreshes on return.
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(_paid),
          ),
        ),
        body: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, style: const TextStyle(color: AppColors.accentRed)),
                ),
              )
            : (_ready
                ? WebViewWidget(controller: _controller)
                : const Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
