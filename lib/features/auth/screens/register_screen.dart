import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/auth/providers/auth_provider.dart';
import 'package:weardo_outfit_builder/widgets/button.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    void showError(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 120,
            maxWidth: 480,
          ),
          height: double.infinity,
          child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 196, 24, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Column(
                spacing: 48,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/images/weardo_wordmark_logo.svg',
                    height: 48,
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
                      const SizedBox(height: 20),
                      TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),

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
                      const SizedBox(height: 20),
                      TextField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Repeat Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Column(
                children: [
                  PrimaryButton(
                    label: 'Create Account',
                    onPressed: () async {
                      if (_passwordController.text != _confirmController.text) {
                        showError('Passwords do not match');
                        return;
                      }
                      String? error = await authProvider.register(
                        _emailController.text.trim(),
                        _usernameController.text.trim(),
                        _passwordController.text.trim(),
                      );
                      if (error == null) {
                        if (context.mounted) context.go('/catalog');
                      } else {
                        showError(error);
                      }
                    },
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
