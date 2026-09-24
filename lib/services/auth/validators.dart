import '../../config/env.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Ingresa tu correo';
  if (!_emailPattern.hasMatch(v)) return 'Correo no válido';
  return null;
}

/// Para el registro: además exige un correo institucional de Duoc UC.
String? validateInstitutionalEmail(String? value) {
  final base = validateEmail(value);
  if (base != null) return base;
  final domain = value!.trim().toLowerCase().split('@').last;
  if (!Env.allowedEmailDomains.contains(domain)) {
    return 'Usa tu correo institucional (@${Env.allowedEmailDomains.join(', @')})';
  }
  return null;
}

String? validateNewPassword(String? value) {
  final v = value ?? '';
  if (v.length < 8) return 'Mínimo 8 caracteres';
  if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
    return 'Debe combinar letras y números';
  }
  return null;
}
