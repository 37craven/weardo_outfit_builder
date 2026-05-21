import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final TextEditingController emailController = TextEditingController();
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();

    void showError(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Create Account', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 20),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 16),
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 16),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 16),
            TextField(controller: confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text != confirmController.text) {
                  showError('Passwords do not match');
                  return;
                }
                String? error = await authProvider.register(
                  emailController.text.trim(),
                  usernameController.text.trim(),
                  passwordController.text.trim(),
                );
                if (error == null) {
                  if (context.mounted) context.go('/home');
                } else {
                  showError(error);
                }
              },
              child: const Text('Create Account'),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}