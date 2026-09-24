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
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AuthBackend authBackend;
  if (Env.hasSupabase) {
    await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabasePublishableKey);
    authBackend = SupabaseAuthBackend(Supabase.instance.client);
  } else {
    authBackend = DemoAuthBackend();
  }

  runApp(CafApp(authBackend: authBackend));
}

class CafApp extends StatelessWidget {
  final AuthBackend authBackend;

  const CafApp({super.key, required this.authBackend});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(authBackend)..init()),
        ChangeNotifierProvider(create: (_) => AppState()..load()),
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
