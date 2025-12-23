import 'package:eatify/features/nav_bar/nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nnlurzlykwynskcrnwnk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ubHVyemx5a3d5bnNrY3Jud25rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNzI0OTQsImV4cCI6MjA4MTY0ODQ5NH0.67D435-k2Bd5Fyrc_ADKceRsh1h18NytcHIqjbCqKis',
  );

  runApp(const ProviderScope(child: EatifyApp()));
}

class EatifyApp extends ConsumerWidget {
  const EatifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eatify',
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (state) =>
            state.session != null ? const NavBar() : const LoginScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}

