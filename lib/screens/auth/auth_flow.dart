import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth/auth_backend.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/demo_auth_backend.dart';
import '../../services/auth/validators.dart';
import '../../theme.dart';
import 'auth_layout.dart';

enum _AuthMode { login, register, forgotPassword }

/// Pantallas para usuarios sin sesión: ingreso, registro y recuperación
/// de contraseña. Se alternan dentro del mismo widget (sin rutas), así al
/// iniciar sesión no queda ninguna pantalla de login apilada debajo.
class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  _AuthMode _mode = _AuthMode.login;
  String? _notice;

  void _go(_AuthMode mode, {String? notice}) => setState(() {
        _mode = mode;
        _notice = notice;
      });

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: switch (_mode) {
          _AuthMode.login => _LoginForm(
              key: const ValueKey('login'),
              notice: _notice,
              onRegister: () => _go(_AuthMode.register),
              onForgotPassword: () => _go(_AuthMode.forgotPassword),
            ),
          _AuthMode.register => _RegisterForm(
              key: const ValueKey('register'),
              onBack: () => _go(_AuthMode.login),
              onNeedsConfirmation: (email) => _go(
                _AuthMode.login,
                notice: 'Te enviamos un correo a $email. Confirma tu cuenta y luego ingresa.',
              ),
            ),
          _AuthMode.forgotPassword => _ForgotPasswordForm(
              key: const ValueKey('forgot'),
              onBack: () => _go(_AuthMode.login),
            ),
        },
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FormHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ingreso
// ---------------------------------------------------------------------------

class _LoginForm extends StatefulWidget {
  final String? notice;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  const _LoginForm({super.key, this.notice, required this.onRegister, required this.onForgotPassword});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().signIn(email: _email.text, password: _password.text);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fillDemo(String email) {
    _email.text = email;
    _password.text = DemoAuthBackend.demoPassword;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = context.read<AuthService>().isDemo;

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FormHeader(title: 'Iniciar sesión', subtitle: 'Ingresa con tu correo institucional.'),
            if (widget.notice != null) AuthMessage(text: widget.notice!, isError: false),
            if (_error != null) AuthMessage(text: _error!),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email, AutofillHints.username],
              validator: validateEmail,
              decoration: const InputDecoration(
                labelText: 'Correo',
                hintText: 'nombre.apellido@duocuc.cl',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 14),
            PasswordField(
              controller: _password,
              autofillHints: const [AutofillHints.password],
              validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : widget.onForgotPassword,
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
            const SizedBox(height: 6),
            AuthSubmitButton(label: 'Ingresar', busy: _busy, onPressed: _submit),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('¿No tienes cuenta?', style: TextStyle(color: Colors.black54)),
                TextButton(onPressed: _busy ? null : widget.onRegister, child: const Text('Regístrate')),
              ],
            ),
            if (isDemo) _DemoAccounts(onPick: _busy ? null : _fillDemo),
          ],
        ),
      ),
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  final ValueChanged<String>? onPick;

  const _DemoAccounts({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: CafColors.warnTint, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MODO DEMO · sin Supabase configurado',
            style: TextStyle(fontSize: 11, letterSpacing: .6, fontWeight: FontWeight.w700, color: CafColors.warn),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ingresa con una cuenta de prueba (contraseña ${DemoAuthBackend.demoPassword}):',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final u in DemoAuthBackend.demoAccounts)
                ActionChip(
                  label: Text(u.role.label),
                  tooltip: u.email,
                  onPressed: onPick == null ? null : () => onPick!(u.email),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Registro
// ---------------------------------------------------------------------------

class _RegisterForm extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onNeedsConfirmation;

  const _RegisterForm({super.key, required this.onBack, required this.onNeedsConfirmation});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
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
      final needsConfirmation = await context.read<AuthService>().signUp(
            fullName: _name.text,
            email: _email.text,
            password: _password.text,
          );
      if (needsConfirmation && mounted) widget.onNeedsConfirmation(_email.text.trim().toLowerCase());
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FormHeader(
              title: 'Crear cuenta',
              subtitle: 'Las cuentas nuevas quedan como estudiante. Los roles de instructor '
                  'y administrador los asigna la administración del CAF.',
            ),
            if (_error != null) AuthMessage(text: _error!),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (v) => (v == null || v.trim().length < 3) ? 'Ingresa tu nombre y apellido' : null,
              decoration: const InputDecoration(labelText: 'Nombre y apellido', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: validateInstitutionalEmail,
              decoration: const InputDecoration(
                labelText: 'Correo institucional',
                hintText: 'nombre.apellido@duocuc.cl',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 14),
            PasswordField(
              controller: _password,
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
            AuthSubmitButton(label: 'Crear cuenta', busy: _busy, onPressed: _submit),
            const SizedBox(height: 10),
            TextButton(onPressed: _busy ? null : widget.onBack, child: const Text('Ya tengo cuenta · Iniciar sesión')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recuperar contraseña
// ---------------------------------------------------------------------------

class _ForgotPasswordForm extends StatefulWidget {
  final VoidCallback onBack;

  const _ForgotPasswordForm({super.key, required this.onBack});

  @override
  State<_ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<_ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FormHeader(
            title: 'Recuperar contraseña',
            subtitle: 'Te enviaremos un enlace para crear una contraseña nueva.',
          ),
          if (_error != null) AuthMessage(text: _error!),
          if (_sent)
            const AuthMessage(
              isError: false,
              text: 'Si el correo está registrado, recibirás un enlace en unos minutos. '
                  'Revisa también la carpeta de spam.',
            )
          else ...[
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline)),
            ),
            const SizedBox(height: 20),
            AuthSubmitButton(label: 'Enviar enlace', busy: _busy, onPressed: _submit),
          ],
          const SizedBox(height: 10),
          TextButton(onPressed: _busy ? null : widget.onBack, child: const Text('Volver a iniciar sesión')),
        ],
      ),
    );
  }
}
