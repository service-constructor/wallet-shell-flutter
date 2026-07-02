/// The postMessage bridge between a mini-app (running in the WebView) and the
/// shell, ported from the web `src/bridge/protocol.ts`.
///
/// Wire format: every message is an Envelope `{channel: CHANNEL, payload: T}`.
/// The mini-app sends BridgeRequest `{id, type, ...}` where type is one of
/// getContext | prepare | pay; the shell replies BridgeResponse
/// `{id, ok, result}` or `{id, ok:false, error}`, correlated by `id`.
class Bridge {
  Bridge._();

  static const channel = 'sc-wallet-bridge';

  /// Name of the Dart JavaScriptChannel the injected shim posts requests to.
  static const jsChannel = 'SCWalletBridge';

  /// JS injected into the mini-app document. It (1) forwards inbound Envelopes
  /// from the page to the Dart channel, and (2) exposes `window.__scDeliver` so
  /// Dart can post a response Envelope back into the page. It also answers the
  /// mini-app's `window.parent.postMessage`/`window.postMessage` since in a
  /// single WebView there is no separate parent frame.
  static const injectedJs = '''
(function () {
  if (window.__scBridgeInstalled) return;
  window.__scBridgeInstalled = true;
  var CH = '$channel';

  function isEnvelope(d) {
    return d && typeof d === 'object' && d.channel === CH && 'payload' in d;
  }

  // Page -> shell: capture requests the mini-app posts and hand them to Dart.
  window.addEventListener('message', function (ev) {
    var d = ev.data;
    if (!isEnvelope(d)) return;
    // Ignore our own responses echoed back (they carry ok/error, not type).
    if (d.payload && d.payload.type) {
      $jsChannel.postMessage(JSON.stringify(d.payload));
    }
  });

  // shell -> page: Dart calls this with a JSON response payload.
  window.__scDeliver = function (json) {
    var payload = JSON.parse(json);
    window.postMessage({ channel: CH, payload: payload }, '*');
  };
})();
''';
}
