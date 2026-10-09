import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../services/auth/auth_backend.dart';
import '../services/auth/auth_service.dart';

/// Sección del administrador para asignar roles. Quien se registra queda
/// como estudiante; aquí se le puede convertir en instructor o
/// administrador.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<AppUser>? _users;
  String? _error;
  String _query = '';
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final users = await context.read<AuthService>().listUsers();
      if (mounted) setState(() => _users = users);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _changeRole(AppUser user, UserRole role) async {
    if (role == user.role) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar rol'),
        content: Text(
          '¿Cambiar el rol de ${user.displayName} de ${user.role.label} a ${role.label}?\n\n'
          'Verá el cambio la próxima vez que inicie sesión.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cambiar rol')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving.add(user.id));
    try {
      final updated = await context.read<AuthService>().updateUserRole(user.id, role);
      if (!mounted) return;
      setState(() => _users = [for (final u in _users!) u.id == updated.id ? updated : u]);
      messenger.showSnackBar(SnackBar(content: Text('${updated.displayName} ahora es ${role.label}.')));
    } on AuthFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthService>().user;
    final users = _users;
    final q = _query.trim().toLowerCase();
    final visible = users
        ?.where((u) => q.isEmpty || u.email.contains(q) || u.fullName.toLowerCase().contains(q))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Usuarios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text(
                      'Quien se registra queda como estudiante. Aquí puedes asignar los roles de '
                      'instructor y administrador.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(tooltip: 'Actualizar lista', onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 12),
          if (users != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in UserRole.values)
                  Chip(label: Text('${r.label}: ${users.where((u) => u.role == r).length}')),
              ],
            ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar por nombre o correo',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Reintentar')),
                      ],
                    ),
                  )
                : visible == null
                    ? const Center(child: CircularProgressIndicator())
                    : visible.isEmpty
                        ? const Center(
                            child: Text('No hay usuarios que coincidan.', style: TextStyle(color: Colors.black54)),
                          )
                        : ListView.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final u = visible[i];
                              final isMe = u.id == me?.id;
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(child: Text(u.initials)),
                                  title: Text(isMe ? '${u.displayName} (tú)' : u.displayName),
                                  subtitle: Text(u.email),
                                  trailing: _saving.contains(u.id)
                                      ? const SizedBox(
                                          width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                      : DropdownButton<UserRole>(
                                          value: u.role,
                                          underline: const SizedBox.shrink(),
                                          // Tu propio rol no se cambia aquí, para no quedarte
                                          // sin acceso por error.
                                          onChanged: isMe ? null : (r) => _changeRole(u, r!),
                                          items: [
                                            for (final r in UserRole.values)
                                              DropdownMenuItem(value: r, child: Text(r.label)),
                                          ],
                                        ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
