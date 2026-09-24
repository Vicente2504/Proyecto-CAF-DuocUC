import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/student.dart';
import '../services/app_state.dart';
import '../services/auth/auth_service.dart';
import '../theme.dart';
import 'admin_screen.dart';
import 'instructor_screen.dart';
import 'student_screen.dart';

enum AppSection { admin, instructor, estudiantes }

/// Secciones visibles para cada rol. El estudiante solo ve su propia ficha.
List<AppSection> _sectionsFor(UserRole role) => switch (role) {
      UserRole.admin => [AppSection.admin, AppSection.instructor, AppSection.estudiantes],
      UserRole.instructor => [AppSection.instructor, AppSection.estudiantes],
      UserRole.estudiante => const [],
    };

/// Cascarón de la aplicación para un usuario con sesión iniciada: la
/// cabecera muestra las secciones permitidas según su rol y el menú de
/// cuenta para cerrar sesión.
class HomeShell extends StatefulWidget {
  final AppUser user;

  const HomeShell({super.key, required this.user});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final List<AppSection> _sections = _sectionsFor(widget.user.role);
  late AppSection? _section = _sections.isEmpty ? null : _sections.first;
  String? _selectedStudentId;

  void _goToStudent(String studentId) {
    setState(() {
      _section = AppSection.estudiantes;
      _selectedStudentId = studentId;
    });
  }

  Widget _buildBody(AppState appState) {
    switch (_section) {
      case AppSection.admin:
        return const AdminScreen();
      case AppSection.instructor:
        return InstructorScreen(onViewStudent: _goToStudent);
      case AppSection.estudiantes:
        return StudentScreen(
          selectedStudentId: _selectedStudentId,
          onSelectStudent: (id) => setState(() => _selectedStudentId = id),
        );
      case null:
        // Rol estudiante: la ficha se vincula por correo con el registro
        // que crea el instructor.
        final email = widget.user.email.toLowerCase();
        final Student? own = appState.students
            .where((s) => s.email.trim().toLowerCase() == email)
            .firstOrNull;
        if (own == null) return _NoFichaYet(user: widget.user);
        return StudentScreen(selectedStudentId: own.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Ficha de Movimiento CAF'),
        actions: [_AccountMenu(user: widget.user), const SizedBox(width: 12)],
        bottom: _sections.length < 2
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<AppSection>(
                      segments: [
                        for (final s in _sections)
                          ButtonSegment(
                            value: s,
                            label: Text(switch (s) {
                              AppSection.admin => 'Administrador',
                              AppSection.instructor => 'Instructor',
                              AppSection.estudiantes => 'Estudiantes',
                            }),
                          ),
                      ],
                      selected: {_section!},
                      onSelectionChanged: (s) => setState(() => _section = s.first),
                    ),
                  ),
                ),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: _buildBody(appState),
          ),
        ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  final AppUser user;

  const _AccountMenu({required this.user});

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar tu sesión en este dispositivo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthService>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: 'Cuenta',
      offset: const Offset(0, 48),
      itemBuilder: (_) => [
        PopupMenuItem<void>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF16211D))),
              Text(user.email, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              Text(user.role.label.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11, letterSpacing: .6, fontWeight: FontWeight.w700, color: CafColors.accentStrong)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          onTap: () => _confirmSignOut(context),
          child: const Row(
            children: [Icon(Icons.logout, size: 20), SizedBox(width: 10), Text('Cerrar sesión')],
          ),
        ),
      ],
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: CafColors.accentTint,
            child: Text(user.initials,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CafColors.accentStrong)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

class _NoFichaYet extends StatelessWidget {
  final AppUser user;

  const _NoFichaYet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hola, ${user.displayName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const Text(
            'Todavía no tienes una ficha de movimiento funcional. Tu instructor del CAF la '
            'creará en tu primera evaluación y aquí verás tus resultados y tu plan de ejercicios.',
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }
}
