import 'package:flutter/material.dart';

import '../../theme.dart';

/// Marco común de las pantallas de autenticación: en pantallas anchas un
/// panel de marca a la izquierda y el formulario a la derecha; en
/// teléfonos y tablets verticales solo el formulario.
class AuthLayout extends StatelessWidget {
  final Widget child;

  const AuthLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!wide) ...[const _BrandMark(), const SizedBox(height: 24)],
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  const Expanded(flex: 5, child: _BrandPanel()),
                  Expanded(flex: 6, child: form),
                ],
              )
            : form,
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: CafColors.accent, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.accessibility_new, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CAF Movimiento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text('Duoc UC · Plaza Vespucio', style: TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    const light = TextStyle(color: Color(0xCCFFFFFF), height: 1.45);
    return Container(
      color: CafColors.accentStrong,
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: CafColors.accent, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.accessibility_new, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 28),
          const Text(
            'Evaluación de\nmovimiento funcional',
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, height: 1.15),
          ),
          const SizedBox(height: 12),
          const Text('Centro de Acondicionamiento Físico · Duoc UC Plaza Vespucio', style: light),
          const SizedBox(height: 36),
          const _RoleLine(icon: Icons.admin_panel_settings_outlined, title: 'Administración', text: 'Métricas del centro e instructores.'),
          const _RoleLine(icon: Icons.fact_check_outlined, title: 'Instructores', text: 'Evaluación de ejercicios y asignación de rutinas.'),
          const _RoleLine(icon: Icons.person_outline, title: 'Estudiantes', text: 'Resultados, progreso y plan de correctivos.'),
        ],
      ),
    );
  }
}

class _RoleLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _RoleLine({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CafColors.accentTint, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(text, style: const TextStyle(color: Color(0xCCFFFFFF))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso de error o éxito dentro de los formularios.
class AuthMessage extends StatelessWidget {
  final String text;
  final bool isError;

  const AuthMessage({super.key, required this.text, this.isError = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? CafColors.coralTint : CafColors.accentTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 20,
            color: isError ? CafColors.coralStrong : CafColors.accentStrong,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: isError ? CafColors.coralStrong : CafColors.accentStrong),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón principal que muestra un indicador mientras la acción está en
/// curso.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  const AuthSubmitButton({super.key, required this.label, required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Campo de contraseña con botón para mostrar u ocultar el texto.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Contraseña',
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
