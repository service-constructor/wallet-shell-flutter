import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../blocs/auth/auth_bloc.dart';

/// Login / register screen. Toggles between the two modes; on success the
/// AuthBloc emits AuthAuthenticated and the root swaps to the dashboard.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.error});

  final String? error;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _register = false;
  final _login = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final bloc = context.read<AuthBloc>();
    final login = _login.text.trim();
    final password = _password.text;
    if (login.isEmpty || password.isEmpty) return;
    bloc.add(_register
        ? AuthRegisterRequested(login, password)
        : AuthLoginRequested(login, password));
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthBloc>().state is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('🪪 Cabinet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                _ModeTabs(
                  register: _register,
                  onChanged: (v) => setState(() => _register = v),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _login,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Login'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (widget.error != null) ...[
                  const SizedBox(height: 12),
                  Text(widget.error!,
                      style: const TextStyle(color: AppColors.accentRed)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_register ? 'Create account' : 'Sign in'),
                ),
                if (_register) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Registering provisions you a TON deposit wallet automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.register, required this.onChanged});

  final bool register;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tab('Sign in', !register, () => onChanged(false))),
        const SizedBox(width: 8),
        Expanded(child: _tab('Register', register, () => onChanged(true))),
      ],
    );
  }

  Widget _tab(String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.accentBlue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on ? AppColors.accentBlue : AppColors.separator,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: on ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}
