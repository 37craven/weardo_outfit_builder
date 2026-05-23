import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/providers/auth_provider.dart';
import 'package:weardo_outfit_builder/providers/clothes_provider.dart';
import 'package:weardo_outfit_builder/providers/favorite_provider.dart';
import 'package:weardo_outfit_builder/screens/login_screen.dart';
import 'package:weardo_outfit_builder/screens/register_screen.dart';
import 'package:weardo_outfit_builder/screens/home_screen.dart';
import 'package:weardo_outfit_builder/screens/generate_outfit_screen.dart';
import 'package:weardo_outfit_builder/screens/clothes_screen.dart';
import 'package:weardo_outfit_builder/screens/add_clothes_screen.dart';
import 'package:weardo_outfit_builder/screens/profile_screen.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dhmtnjwtqqcrecqmxpfc.supabase.co',
    anonKey: 'sb_publishable_a2rTSMLcLOTnfb6opH-azQ_dTkrmq2Y',
  );
  runApp(WeardoApp());
}

class WeardoApp extends StatelessWidget {
  WeardoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClothesProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: MaterialApp.router(
        title: 'WEARDO',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple)),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  final GoRouter _router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.currentUser != null;
      final isLoginRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (isLoggedIn && isLoginRoute) return '/home';
      if (!isLoggedIn && !isLoginRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/generate', builder: (context, state) => const GenerateOutfitScreen()),
      GoRoute(path: '/clothes', builder: (context, state) => const ClothesScreen()),
      GoRoute(path: '/add-clothes', builder: (context, state) => const AddClothesScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    ],
  );
}