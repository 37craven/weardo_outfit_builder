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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

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
                  SizedBox(height: isSmall ? 24 : screenHeight * 0.06),
                  SvgPicture.asset(
                    'assets/images/weardo_wordmark_logo.svg',
                    height: 48,
                  ),
                  SizedBox(height: isSmall ? 24 : screenHeight * 0.04),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(labelText: 'Username'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter a username';
                            if (v.contains(' ')) return 'Username cannot contain spaces';
                            if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(v)) return 'Only letters, numbers, underscores, and hyphens';
                            if (v.length < 3) return 'Username must be at least 3 characters';
                            return null;
                          },
                        ),
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
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      PrimaryButton(
                        label: 'Create Account',
                        isLoading: _isLoading,
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          if (_passwordController.text != _confirmController.text) {
                            showError('Passwords do not match');
                            return;
                          }
                          setState(() => _isLoading = true);
                          final error = await authProvider.register(
                            _emailController.text.trim(),
                            _usernameController.text.trim(),
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
                        onPressed: () => context.go('/login'),
                        child: const Text('Back to Login'),
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
