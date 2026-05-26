import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/auth/providers/auth_provider.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/widgets/button.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
          padding: const EdgeInsets.fromLTRB(24, 128, 24, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Column(
                spacing: 128,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _WordmarkLogo(),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                      const SizedBox(height: 5),
                      TextButton(
                        onPressed: () =>
                            showError('Reset link would be sent (feature coming)'),
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                ],
              ),


              Column(
                children: [
                  PrimaryButton(
                    label: 'Login',
                    onPressed: () async {
                      String? error = await authProvider.login(
                        _emailController.text.trim(),
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
                    onPressed: () => context.go('/register'),
                    child: const Text("Don't have an account? Register"),
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

class _WordmarkLogo extends StatefulWidget {
  const _WordmarkLogo();

  @override
  State<_WordmarkLogo> createState() => _WordmarkLogoState();
}

class _WordmarkLogoState extends State<_WordmarkLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _flickerOpacity = 1.0;
  double _snapAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _scheduleFlicker();
    _scheduleSnap();
  }

  void _scheduleFlicker() {
    Future.delayed(Duration(milliseconds: 200 + math.Random().nextInt(2800)), () {
      if (!mounted) return;
      setState(() {
        _flickerOpacity = math.Random().nextDouble() * 0.4;
      });
      Future.delayed(Duration(milliseconds: 40 + math.Random().nextInt(120)), () {
        if (!mounted) return;
        setState(() => _flickerOpacity = 1.0);
        _scheduleFlicker();
      });
    });
  }

  void _scheduleSnap() {
    Future.delayed(Duration(milliseconds: 2000 + math.Random().nextInt(4000)), () {
      if (!mounted) return;
      setState(() {
        _snapAngle = (math.Random().nextDouble() - 0.5) * math.pi;
      });
      _scheduleSnap();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * 2 * math.pi;
        final wobbleX = math.sin(angle * 0.7) * 0.15;
        final wobbleZ = math.cos(angle * 0.5) * 0.05;

        return Opacity(
          opacity: _flickerOpacity,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle + _snapAngle)
              ..rotateX(wobbleX)
              ..rotateZ(wobbleZ),
            child: SvgPicture.asset(
              'assets/images/weardo_wordmark_logo.svg',
              height: 48,
            ),
          ),
        );
      },
    );
  }
}
