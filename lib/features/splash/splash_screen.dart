import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const int baseCols = 11;
  static const int baseRows = 9;
  static const int paddingCols = 2;
  static const int paddingRows = 2;
  static const int totalCols = baseCols + paddingCols * 2;

  static const Set<int> _wIndices = {
    1 * 11 + 0,
    1 * 11 + 10,
    2 * 11 + 0,
    2 * 11 + 6,
    2 * 11 + 10,
    3 * 11 + 0,
    3 * 11 + 5,
    3 * 11 + 9,
    4 * 11 + 0,
    4 * 11 + 4,
    4 * 11 + 5,
    4 * 11 + 8,
    5 * 11 + 0,
    5 * 11 + 3,
    5 * 11 + 5,
    5 * 11 + 8,
    6 * 11 + 1,
    6 * 11 + 3,
    6 * 11 + 5,
    6 * 11 + 7,
    7 * 11 + 1,
    7 * 11 + 3,
    7 * 11 + 5,
    7 * 11 + 7,
    8 * 11 + 1,
    8 * 11 + 2,
    8 * 11 + 5,
    8 * 11 + 6,
  };

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/catalog');
      });
      return;
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.go('/login');
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cellSizeByWidth = size.width / totalCols;
    final cellSizeByHeight = size.height / (baseRows + paddingRows * 2);
    final cellSize = min(cellSizeByWidth, cellSizeByHeight);
    final totalRows = (size.height / cellSize).ceil();
    final startRow = (totalRows - baseRows) ~/ 2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: size,
            painter: _SplashPainter(
              progress: _controller.value,
              cellSize: cellSize,
              totalRows: totalRows,
              totalCols: totalCols,
              patternOffsetRow: startRow,
              patternOffsetCol: paddingCols,
              baseRows: baseRows,
              baseCols: baseCols,
              wIndices: _wIndices,
            ),
          );
        },
      ),
    );
  }
}

class _SplashPainter extends CustomPainter {
  final double progress;
  final double cellSize;
  final int totalRows;
  final int totalCols;
  final int patternOffsetRow;
  final int patternOffsetCol;
  final int baseRows;
  final int baseCols;
  final Set<int> wIndices;

  _SplashPainter({
    required this.progress,
    required this.cellSize,
    required this.totalRows,
    required this.totalCols,
    required this.patternOffsetRow,
    required this.patternOffsetCol,
    required this.baseRows,
    required this.baseCols,
    required this.wIndices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final xOffset = (size.width - cellSize * totalCols) / 2;

    final centerRow = (totalRows - 1) / 2.0;
    final maxRowDist = max(centerRow, totalRows - 1 - centerRow);

    for (int r = 0; r < totalRows; r++) {
      final rowDist = (r - centerRow).abs();
      final rowAdvance = maxRowDist > 0 ? (rowDist / maxRowDist) * 0.4 : 0.0;
      final effectiveT = (progress + rowAdvance).clamp(0.0, 1.0);

      for (int c = 0; c < totalCols; c++) {
        final isInPattern =
            r >= patternOffsetRow &&
            r < patternOffsetRow + baseRows &&
            c >= patternOffsetCol &&
            c < patternOffsetCol + baseCols;
        final isW =
            isInPattern &&
            wIndices.contains(
              (r - patternOffsetRow) * baseCols + (c - patternOffsetCol),
            );

        double opacity;
        if (isW) {
          opacity = 1.0;
        } else {
          final seed = isInPattern
              ? ((r * 1000 + c * 7) % 1000).toDouble()
              : ((r * 997 + c * 13 + 500) % 1000).toDouble();
          opacity = _xOpacity(effectiveT, seed);
        }

        if (opacity >= 0.005) {
          paint.color = Color.from(alpha: opacity, red: 0, green: 0, blue: 0);
          canvas.drawRect(
            Rect.fromLTWH(xOffset + c * cellSize, r * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  double _xOpacity(double t, double seed) {
    if (t >= 0.88) return 0.0;

    const flickerEnd = 0.55;
    final flickerT = (t / flickerEnd).clamp(0.0, 1.0);

    double signal = 0.0;
    signal += sin(t * 50.0 + seed * 6.28) * 0.35;
    signal += sin(t * 33.0 + seed * 4.13) * 0.25;
    signal += sin(t * 71.0 + seed * 1.57) * 0.20;
    signal += sin(t * 17.0 + seed * 9.81) * 0.10;
    signal += sin(t * (25.0 + seed * 0.5)) * 0.10;

    final threshold = -0.3 + flickerT * 1.5;
    final isOn = signal.abs() > threshold;

    if (!isOn) return 0.0;

    if (t > flickerEnd) {
      return 1.0 - ((t - flickerEnd) / (0.88 - flickerEnd));
    }

    return 1.0;
  }

  @override
  bool shouldRepaint(_SplashPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
