import 'package:caf_movimiento_flutter/main.dart';
import 'package:caf_movimiento_flutter/services/auth/demo_auth_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester, {Size size = const Size(1280, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(CafApp(authBackend: DemoAuthBackend()));
  await tester.pumpAndSettle();
}

Future<void> _login(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), email);
  await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
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
