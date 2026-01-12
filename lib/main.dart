import 'package:eatify/features/nav_bar/nav_bar.dart';
import 'package:eatify/providers/shared_cart_provider.dart';
import 'package:eatify/theme/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/login_screen.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Supabase.initialize(
    url: 'https://nnlurzlykwynskcrnwnk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ubHVyemx5a3d5bnNrY3Jud25rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNzI0OTQsImV4cCI6MjA4MTY0ODQ5NH0.67D435-k2Bd5Fyrc_ADKceRsh1h18NytcHIqjbCqKis',
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations', // <-- folder with en.json & ar.json
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: EatifyApp()),
    ),
  );
}

class EatifyApp extends ConsumerStatefulWidget {
  const EatifyApp({super.key});

  @override
  ConsumerState<EatifyApp> createState() => _EatifyAppState();
}

class _EatifyAppState extends ConsumerState<EatifyApp> {
  @override
  void initState() {
    super.initState();

    // Listen to auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (session != null) {
        // User just logged in → reload shared cart
        ref.read(sharedCartProvider.notifier).loadActiveSharedCart();
      } else {
        // User logged out → reset shared cart
        ref.invalidate(sharedCartProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eatify',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeProvider),

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      home: authState.when(
        data: (state) =>
            state.session != null ? const NavBar() : const LoginScreen(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}
