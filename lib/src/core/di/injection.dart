import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../data/network/api_client.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/cabinet/cabinet_bloc.dart';
import '../security/token_store.dart';

final getIt = GetIt.instance;

/// Wires dependencies bottom-up (infra → storage → network → repo → blocs),
/// matching the redo_wallet convention: singletons for infra/repos, factories
/// for blocs.
Future<void> initDependencies() async {
  // Infra / storage.
  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  getIt.registerLazySingleton<TokenStore>(() => TokenStore(getIt()));

  // Load any persisted token into the in-memory cache before first use.
  await getIt<TokenStore>().load();

  // Network + repository.
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(tokenStore: getIt()));
  getIt.registerLazySingleton<WalletRepository>(
    () => WalletRepository(api: getIt(), tokens: getIt()),
  );

  // Blocs (new instance per subscription).
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt()));
  getIt.registerFactory<CabinetBloc>(() => CabinetBloc(getIt()));
}
