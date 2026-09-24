import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth/auth_service.dart';
import '../home_shell.dart';
import 'auth_flow.dart';
import 'update_password_screen.dart';

/// Decide qué mostrar según el estado de la sesión.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return switch (auth.status) {
      AuthStatus.initializing => const Scaffold(body: Center(child: CircularProgressIndicator())),
      AuthStatus.signedOut => const AuthFlow(),
      AuthStatus.passwordRecovery => const UpdatePasswordScreen(),
      // La key reinicia el estado del cascarón si cambia el usuario.
      AuthStatus.signedIn => HomeShell(key: ValueKey(auth.user!.id), user: auth.user!),
    };
  }
}
