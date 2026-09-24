import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth/auth_backend.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/validators.dart';
import 'auth_layout.dart';

/// Se muestra al volver a la app desde el enlace de recuperación de
/// contraseña que Supabase envía por correo.
class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().updatePassword(_password.text);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nueva contraseña', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Elige una contraseña nueva para tu cuenta.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 22),
            if (_error != null) AuthMessage(text: _error!),
            PasswordField(
              controller: _password,
              label: 'Nueva contraseña',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: validateNewPassword,
            ),
            const SizedBox(height: 14),
            PasswordField(
              controller: _confirm,
              label: 'Repite la contraseña',
              validator: (v) => v != _password.text ? 'Las contraseñas no coinciden' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            AuthSubmitButton(label: 'Guardar contraseña', busy: _busy, onPressed: _submit),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _busy ? null : () => context.read<AuthService>().signOut(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
