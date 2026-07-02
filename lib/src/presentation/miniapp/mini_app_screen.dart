import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
  InAppWebViewController? _controller;
  String _encUserId = '';
  bool _paid = false;
  String? _error;
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Precompute the sealed user id BEFORE the page loads, so getContext can
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
    if (mounted) setState(() => _bootstrapping = false);
  }

  // A bridge request arrived from the mini-app. Dispatch, then deliver the
  // response back into the page keyed by the request id.
  Future<void> _onBridgeCall(List<dynamic> args) async {
    if (args.isEmpty) return;
    Map<String, dynamic> req;
    try {
      req = jsonDecode(args.first as String) as Map<String, dynamic>;
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
    final controller = _controller;
    if (controller == null) return;
    // Pass the JSON as a single-quoted JS string argument (double-encode -> a JS
    // string literal), then let the injected __scDeliver dispatch it.
    final arg = jsonEncode(jsonEncode(response));
    await controller.evaluateJavascript(source: 'window.__scDeliver($arg);');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          : (_bootstrapping
              ? const Center(child: CircularProgressIndicator())
              : InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(widget.url.isEmpty ? AppConfig.fallbackMiniAppUrl : widget.url),
                  ),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    transparentBackground: true,
                  ),
                  // Install the bridge at document start, before the mini-app's
                  // bundle runs its `window.parent === window` host check.
                  initialUserScripts: UnmodifiableListView<UserScript>([
                    UserScript(
                      source: Bridge.installJs,
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                    ),
                  ]),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    controller.addJavaScriptHandler(
                      handlerName: Bridge.handler,
                      callback: (args) => _onBridgeCall(args),
                    );
                  },
                )),
    );
  }
}
