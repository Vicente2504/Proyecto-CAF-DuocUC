import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'screens/auth/auth_gate.dart';
import 'services/app_state.dart';
import 'services/auth/auth_backend.dart';
import 'services/auth/auth_service.dart';
import 'services/auth/demo_auth_backend.dart';
import 'services/auth/supabase_auth_backend.dart';
import 'services/data/data_repository.dart';
import 'services/data/local_data_repository.dart';
import 'services/data/supabase_data_repository.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.hasSupabase && !Env.allowDemo) {
    runApp(const MissingConfigApp());
    return;
  }

  final AuthBackend authBackend;
  final DataRepository dataRepository;
  if (Env.hasSupabase) {
    await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabasePublishableKey);
    authBackend = SupabaseAuthBackend(Supabase.instance.client);
    dataRepository = SupabaseDataRepository(Supabase.instance.client);
  } else {
    authBackend = DemoAuthBackend();
    dataRepository = LocalDataRepository();
  }

  runApp(CafApp(authBackend: authBackend, dataRepository: dataRepository));
}

class CafApp extends StatelessWidget {
  final AuthBackend authBackend;
  final DataRepository dataRepository;

  const CafApp({super.key, required this.authBackend, required this.dataRepository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(authBackend)..init()),
        // Los datos se cargan al iniciar sesión (ver HomeShell).
        ChangeNotifierProvider(create: (_) => AppState(dataRepository)),
      ],
      child: MaterialApp(
        title: 'Ficha de Movimiento CAF',
        debugShowCheckedModeBanner: false,
        theme: buildCafTheme(),
        home: const AuthGate(),
      ),
    );
  }
}

/// Se muestra si un build de producción se compiló sin las credenciales de
/// Supabase, para no publicar por error la app en modo demo.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ficha de Movimiento CAF',
      debugShowCheckedModeBanner: false,
      theme: buildCafTheme(),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'La aplicación no está configurada.\n'
              'Compílala con --dart-define-from-file=env.json (ver PRODUCCION.md).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
