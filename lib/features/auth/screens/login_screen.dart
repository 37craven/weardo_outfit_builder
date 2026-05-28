import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/auth/providers/auth_provider.dart';
import 'package:weardo_outfit_builder/features/auth/widgets/wordmark_logo.dart';
import 'package:weardo_outfit_builder/widgets/button.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenHeight < 650;

    void showError(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  SizedBox(height: isSmall ? 24 : screenHeight * 0.1),
                  const WordmarkLogo(),
                  SizedBox(height: isSmall ? 32 : screenHeight * 0.06),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(controller: _usernameOrEmailController, decoration: const InputDecoration(labelText: 'Username or Email')),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      PrimaryButton(
                        label: 'Login',
                        isLoading: _isLoading,
                        onPressed: () async {
                          setState(() => _isLoading = true);
                          final error = await authProvider.login(
                            _usernameOrEmailController.text.trim(),
                            _passwordController.text.trim(),
                          );
                          if (error == null) {
                            if (context.mounted) context.go('/catalog');
                            return;
                          }
                          setState(() => _isLoading = false);
                          showError(error);
                        },
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text("Don't have an account? Register"),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 16 : 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
