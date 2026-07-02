# wallet-shell-flutter

Mobile (iOS + Android) personal cabinet for **Service Constructor** — the native
counterpart of the web `wallet-shell` (../wallet-shell). Register/login, view
accounts and balances, browse the mini-app catalog and order history, and **host
mini-apps in a WebView** with a **bottom-sheet payment confirmation**.

## How it differs from the web shell

The web app runs a BFF (Express) that hides the JWT in an httpOnly cookie and
does sealed-box encryption server-side. **The mobile app has no BFF** — it talks
directly to the unified gateway (`/v1/*`, Bearer auth):

| Concern | Web shell | This app |
|---|---|---|
| Backend hop | SPA -> BFF -> gateway | app -> **gateway** directly |
| JWT storage | httpOnly cookie (`sc_session`) | `flutter_secure_storage` (keychain/keystore) |
| Auth to gateway | BFF attaches Bearer | `ApiClient` attaches `Authorization: Bearer` |
| `userId` sealed box | libsodium in the BFF | **`pinenacl` on-device** (`SealedBoxCrypto`) |
| Mini-app host | `<iframe>` + postMessage | **WebView** + JS channel bridge |
| Payment consent | modal over the iframe | **modal bottom sheet** (`ConsentSheet`) |

The sealed box is byte-compatible with libsodium `crypto_box_seal` (X25519 +
XSalsa20-Poly1305, `ephemeral_pk || ciphertext+MAC`, standard base64), verified
by a round-trip unit test.

## Architecture

Clean Architecture (layer-first) + **flutter_bloc** + **get_it**, mirroring the
`redo_wallet_app` conventions.

```
lib/
  main.dart                      bootstrap: initDependencies() -> WalletShellApp
  src/
    app.dart                     root: AuthBloc state -> AuthScreen | HomeScreen
    core/
      config/app_config.dart     GATEWAY_BASE, fallback mini-app URL (--dart-define)
      crypto/sealed_box.dart     crypto_box_seal of the user id (pinenacl)
      di/injection.dart          get_it wiring
      json/parse.dart            protojson int64-as-string parsing
      security/token_store.dart  JWT in secure storage
    data/
      network/api_client.dart    http + Bearer over the gateway
      repositories/wallet_repository.dart   the api.ts equivalent
    domain/entities/             User, Account, Currency, MiniApp, Order, Pay...
    presentation/
      blocs/{auth,cabinet}/      session + dashboard state
      miniapp/                   WebView host + postMessage bridge
      screens/                   auth, home (accounts+apps), orders
      widgets/consent_sheet.dart bottom-sheet payment confirmation
```

### Mini-app bridge

Ported from the web `src/bridge/protocol.ts`. Injected JS forwards the mini-app's
`postMessage` envelopes (`{channel:'sc-wallet-bridge', payload}`) to a Dart
`JavaScriptChannel`; Dart dispatches `getContext` / `prepare` / `pay` and posts
the `{id, ok, result}` response back into the page. `pay` shows the consent
bottom sheet and only pays if the user confirms.

## Run

```sh
flutter pub get
flutter run \
  --dart-define=GATEWAY_BASE=https://api.serviceconstructor.dev \
  --dart-define=FALLBACK_MINIAPP_URL=https://image-miniapp.serviceconstructor.dev
```

Defaults point at the production gateway, so a bare `flutter run` works too.

```sh
flutter test       # sealed-box round-trip + JSON parsing
flutter analyze
```

## Gateway endpoints used

`POST /v1/auth/{register,login}` . `GET /v1/auth/me` . `GET /v1/auth/accounts` .
`GET /v1/currencies` . `GET /v1/services` (catalog) .
`GET /v1/services/{id}/info` (encryption key) . `GET /v1/orders` .
`POST /v1/services/pay` . `POST /v1/auth/deposits` (demo).

All User-scoped routes carry the stored JWT as `Authorization: Bearer`; identity
comes from the token's `sub`, never a request body.
