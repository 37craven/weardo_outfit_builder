import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WordmarkLogo extends StatefulWidget {
  const WordmarkLogo({super.key});

  @override
  State<WordmarkLogo> createState() => _WordmarkLogoState();
}

class _WordmarkLogoState extends State<WordmarkLogo> with SingleTickerProviderStateMixin {
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
