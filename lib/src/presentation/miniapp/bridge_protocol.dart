/// The postMessage bridge between a mini-app (running in the WebView) and the
/// shell, ported from the web `src/bridge/protocol.ts` and adapted for a WebView.
///
/// Wire format: every message is an Envelope `{channel: CHANNEL, payload: T}`.
/// The mini-app sends BridgeRequest `{id, type, ...}` (getContext | prepare |
/// pay); the shell replies BridgeResponse `{id, ok, result}` / `{id, ok:false,
/// error}`, correlated by `id`.
///
/// The mini-app SDK (example-image-miniapp `WalletBridge.ts`):
///   - decides it is "hosted in a wallet shell" purely by `window.parent !== window`;
///   - sends requests via `window.parent.postMessage(envelope, '*')`;
///   - accepts a reply only when `ev.source === window.parent` and channel matches.
///
/// A single WebView has no parent frame (`window.parent === window`), so the SDK
/// would throw "not hosted in a wallet shell". [installJs] fixes this at document
/// start by creating a hidden same-origin iframe and pointing `window.parent`
/// (and `top`) at its real `contentWindow` — a genuine Window the engine accepts
/// as a `MessageEvent.source`. It intercepts that window's `postMessage` to
/// forward requests to Dart, and delivers replies as MessageEvents whose
/// `source` is that same window, satisfying the SDK's `ev.source` gate.
class Bridge {
  Bridge._();

  static const channel = 'sc-wallet-bridge';

  /// Name of the flutter_inappwebview JavaScript handler the shim posts to.
  static const handler = 'scWalletBridge';

  /// Installed as a document-start UserScript, BEFORE the mini-app bundle runs.
  static const installJs = '''
(function () {
  if (window.__scBridgeInstalled) return;
  window.__scBridgeInstalled = true;
  var CH = '$channel';

  // Forwards a request payload to Dart. Assigned to the synthetic parent's
  // postMessage so `window.parent.postMessage(envelope, '*')` reaches the shell.
  function forward(msg) {
    try {
      if (msg && msg.channel === CH && msg.payload && msg.payload.type) {
        window.flutter_inappwebview.callHandler('$handler', JSON.stringify(msg.payload));
      }
    } catch (e) {}
  }

  // The synthetic parent. Start with a plain object so `window.parent !== window`
  // holds SYNCHRONOUSLY at document start (before the mini-app bundle runs its
  // host check). Once the DOM is ready we upgrade it to a hidden same-origin
  // iframe's contentWindow — a REAL Window the engine accepts as a
  // MessageEvent.source, so replies pass the SDK's `ev.source === window.parent`
  // gate. `host` is captured by closure, so upgrading it updates window.parent.
  var host = { postMessage: forward };

  function upgradeToIframeWindow() {
    if (host && host.__scReal) return;
    try {
      var f = document.createElement('iframe');
      f.setAttribute('aria-hidden', 'true');
      f.style.display = 'none';
      (document.body || document.documentElement).appendChild(f);
      var w = f.contentWindow;
      if (w) {
        w.postMessage = forward; // intercept before anyone uses it
        w.__scReal = true;
        host = w;
      }
    } catch (e) {}
  }

  if (document.body) {
    upgradeToIframeWindow();
  } else {
    document.addEventListener('DOMContentLoaded', upgradeToIframeWindow);
  }

  // Point window.parent / window.top at the synthetic host window (via closure,
  // so the later iframe upgrade is reflected automatically).
  try { Object.defineProperty(window, 'parent', { get: function () { return host; }, configurable: true }); } catch (e) {}
  try { Object.defineProperty(window, 'top', { get: function () { return host; }, configurable: true }); } catch (e) {}

  // Dart -> page: deliver a response Envelope as a MessageEvent whose `source`
  // is the synthetic host window, satisfying `ev.source === window.parent`.
  window.__scDeliver = function (json) {
    var payload = JSON.parse(json);
    var data = { channel: CH, payload: payload };
    var ev;
    try {
      ev = new MessageEvent('message', { data: data, source: host });
    } catch (e) {
      ev = new MessageEvent('message', { data: data });
    }
    window.dispatchEvent(ev);
  };
})();
''';
}
