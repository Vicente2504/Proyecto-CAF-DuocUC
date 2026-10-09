import 'package:caf_movimiento_flutter/main.dart';
import 'package:caf_movimiento_flutter/models/app_user.dart';
import 'package:caf_movimiento_flutter/services/auth/auth_backend.dart';
import 'package:caf_movimiento_flutter/services/auth/demo_auth_backend.dart';
import 'package:caf_movimiento_flutter/services/data/local_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester, {Size size = const Size(1280, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(CafApp(authBackend: DemoAuthBackend(), dataRepository: LocalDataRepository()));
  await tester.pumpAndSettle();
}

Future<void> _login(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), email);
  await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
  await tester.pumpAndSettle();
}

Future<void> _register(WidgetTester tester, String name, String email) async {
  await tester.tap(find.text('Regístrate'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'Nombre y apellido'), name);
  await tester.enterText(find.widgetWithText(TextFormField, 'Correo institucional'), email);
  await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'clave1234');
  await tester.enterText(find.widgetWithText(TextFormField, 'Repite la contraseña'), 'clave1234');
  await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
  await tester.pumpAndSettle();
}

Future<void> _signOut(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Cuenta'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cerrar sesión'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('muestra el login cuando no hay sesión', (tester) async {
    await _pumpApp(tester);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('MODO DEMO · sin Supabase configurado'), findsOneWidget);
  });

  testWidgets('el login cabe en un teléfono y permite registrarse', (tester) async {
    await _pumpApp(tester, size: const Size(360, 740));
    expect(find.text('CAF Movimiento'), findsOneWidget);
    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();
    expect(find.text('Crear cuenta'), findsWidgets);
  });

  testWidgets('contraseña incorrecta muestra error', (tester) async {
    await _pumpApp(tester);
    await _login(tester, 'instructor@duoc.cl', 'incorrecta1');
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
  });

  testWidgets('instructor ve sus secciones, no la de administrador', (tester) async {
    await _pumpApp(tester);
    await _login(tester, 'instructor@duoc.cl', DemoAuthBackend.demoPassword);
    expect(find.text('Ficha de Movimiento CAF'), findsOneWidget);
    expect(find.text('Instructor'), findsOneWidget);
    expect(find.text('Estudiantes'), findsOneWidget);
    expect(find.text('Administrador'), findsNothing);

    await tester.tap(find.text('Nueva evaluación').first);
    await tester.pumpAndSettle();
    expect(find.text('1. Press banca'), findsOneWidget);
    expect(find.text('0 / 30'), findsNothing);
    expect(find.text('20 / 30'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('10. Curl de bíceps'), 200,
        scrollable: find.descendant(of: find.byType(Dialog), matching: find.byType(Scrollable)).first);
    expect(find.text('10. Curl de bíceps'), findsOneWidget);
  });

  testWidgets('estudiante ve solo su ficha y puede cerrar sesión', (tester) async {
    await _pumpApp(tester);
    await _login(tester, 'javiera.munoz@duocuc.cl', DemoAuthBackend.demoPassword);
    expect(find.text('Javiera Muñoz'), findsOneWidget);
    expect(find.byType(SegmentedButton), findsNothing);
    expect(find.byType(DropdownButton<String>), findsNothing);

    await tester.tap(find.byTooltip('Cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('el estudiante que se registra aparece en la lista del instructor', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre y apellido'), 'Ana Pérez');
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo institucional'), 'ana.perez@duocuc.cl');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'clave1234');
    await tester.enterText(find.widgetWithText(TextFormField, 'Repite la contraseña'), 'clave1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    // El estudiante entra directo a su ficha (vacía), no al aviso de "sin ficha".
    expect(find.text('Ana Pérez'), findsWidgets);
    expect(find.textContaining('Todavía no tienes una ficha'), findsNothing);

    await tester.tap(find.byTooltip('Cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    await _login(tester, 'instructor@duoc.cl', DemoAuthBackend.demoPassword);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('ana.perez@duocuc.cl'), findsOneWidget);
  });

  testWidgets('el admin convierte a un estudiante en instructor desde Usuarios', (tester) async {
    await _pumpApp(tester);
    await _register(tester, 'Ana Pérez', 'ana.perez@duocuc.cl');
    await _signOut(tester);

    await _login(tester, 'admin@duoc.cl', DemoAuthBackend.demoPassword);
    await tester.tap(find.text('Usuarios'));
    await tester.pumpAndSettle();
    expect(find.text('Administración CAF (tú)'), findsOneWidget);
    final ownRow = find.ancestor(of: find.text('Administración CAF (tú)'), matching: find.byType(ListTile));
    final ownDropdown = tester.widget<DropdownButton<UserRole>>(
        find.descendant(of: ownRow, matching: find.byType(DropdownButton<UserRole>)));
    expect(ownDropdown.onChanged, isNull, reason: 'el admin no puede cambiar su propio rol');

    final anaRow = find.ancestor(of: find.text('Ana Pérez'), matching: find.byType(ListTile));
    await tester.tap(find.descendant(of: anaRow, matching: find.byType(DropdownButton<UserRole>)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instructor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cambiar rol'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Pérez ahora es Instructor.'), findsOneWidget);
    await _signOut(tester);

    await _login(tester, 'ana.perez@duocuc.cl', 'clave1234');
    expect(find.text('Instructor'), findsOneWidget);
    expect(find.text('Mis estudiantes'), findsOneWidget);
    expect(find.text('Usuarios'), findsNothing);
  });

  test('modo demo: solo un admin cambia roles y siempre queda uno', () async {
    final backend = DemoAuthBackend();
    await backend.signIn(email: 'instructor@duoc.cl', password: DemoAuthBackend.demoPassword);
    expect(backend.listUsers(), throwsA(isA<AuthFailure>()));
    expect(backend.updateUserRole('demo-instructor', UserRole.admin), throwsA(isA<AuthFailure>()));

    await backend.signIn(email: 'admin@duoc.cl', password: DemoAuthBackend.demoPassword);
    expect(
      backend.updateUserRole('demo-admin', UserRole.instructor),
      throwsA(isA<AuthFailure>().having((e) => e.message, 'message', contains('al menos un administrador'))),
    );
    await backend.updateUserRole('demo-instructor', UserRole.admin);
    final users = await backend.listUsers();
    expect(users.firstWhere((u) => u.id == 'demo-instructor').role, UserRole.admin);
  });

  testWidgets('registro rechaza correos no institucionales', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre y apellido'), 'Ana Pérez');
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo institucional'), 'ana@gmail.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Usa tu correo institucional'), findsOneWidget);
  });
}
