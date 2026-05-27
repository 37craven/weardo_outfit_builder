import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weardo_outfit_builder/features/auth/providers/auth_provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/providers/saved_outfits_provider.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/providers/builder_provider.dart';
import 'package:weardo_outfit_builder/features/auth/screens/login_screen.dart';
import 'package:weardo_outfit_builder/features/auth/screens/register_screen.dart';
import 'package:weardo_outfit_builder/features/splash/splash_screen.dart';
import 'package:weardo_outfit_builder/features/catalog/screens/catalog_screen.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/screens/builder_screen.dart';
import 'package:weardo_outfit_builder/features/catalog/screens/add_clothing_screen.dart';
import 'package:weardo_outfit_builder/features/profile/screens/profile_screen.dart';
import 'package:weardo_outfit_builder/widgets/nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );
  runApp(WeardoApp());
}

class WeardoApp extends StatefulWidget {
  const WeardoApp({super.key});

  @override
  State<WeardoApp> createState() => _WeardoAppState();
}

class _WeardoAppState extends State<WeardoApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: _authProvider,
      redirect: (context, state) {
        final isLoggedIn = _authProvider.currentUser != null;
        final location = state.matchedLocation;
        final isAuthRoute = location == '/login' || location == '/register' || location == '/splash';

        if (isLoggedIn && isAuthRoute) return '/catalog';
        if (!isLoggedIn && !isAuthRoute) return '/login';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/catalog', builder: (context, state) => const CatalogScreen())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/builder', builder: (context, state) => const BuilderScreen())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())],
            ),
          ],
        ),
        GoRoute(path: '/add-clothes', builder: (context, state) => const AddClothesScreen()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => SavedOutfitsProvider()),
        ChangeNotifierProvider(create: (_) => BuilderProvider()),
      ],
      child: MaterialApp.router(
        title: 'Weardo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.white,
            brightness: Brightness.light,
            primary: const Color(0xFF1C1C1C),
            onPrimary: const Color(0xFFFFFFFF),
            surface: const Color(0xFFFFFFFF),
            onSurface: const Color(0xFF1C1C1C),
          ),
          scaffoldBackgroundColor: const Color(0xFFFFFFFF),
          textTheme: GoogleFonts.jetBrainsMonoTextTheme().apply(
            bodyColor: const Color(0xFF1C1C1C),
            displayColor: const Color(0xFF1C1C1C),
          ),
        ),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
