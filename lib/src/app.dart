import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'data/repositories/wallet_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/cabinet/cabinet_bloc.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'theme/app_theme.dart';

/// Root widget: provides the repository and blocs, then swaps between the auth
/// screen and the dashboard based on AuthBloc state.
class WalletShellApp extends StatelessWidget {
  const WalletShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<WalletRepository>.value(
      value: getIt<WalletRepository>(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
          ),
          BlocProvider<CabinetBloc>(create: (_) => getIt<CabinetBloc>()),
        ],
        child: MaterialApp(
          title: 'Service Constructor Cabinet',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const _Root(),
        ),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return switch (state) {
          AuthInitial() || AuthLoading() =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
          AuthAuthenticated(:final user) => HomeScreen(key: ValueKey(user.userId), user: user),
          AuthUnauthenticated(:final error) => AuthScreen(error: error),
        };
      },
    );
  }
}
