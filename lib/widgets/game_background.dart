import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/game_data.dart';

/// Monet-inspired color palettes for table backgrounds
class MonetPalettes {
  static const List<MonetPalette> palettes = [
    // 0: Classic Green (Sage / Mahjong table)
    MonetPalette(
      name: '经典绿',
      centerColor: Color(0xFF8FB3A3),
      edgeColor: Color(0xFF4A6B5D),
    ),
    // 1: Warm Terracotta
    MonetPalette(
      name: '暖赤陶',
      centerColor: Color(0xFFC4967A),
      edgeColor: Color(0xFF8B5E3C),
    ),
    // 2: Ocean Blue
    MonetPalette(
      name: '海洋蓝',
      centerColor: Color(0xFF7BA7C9),
      edgeColor: Color(0xFF3A5F7F),
    ),
    // 3: Lavender
    MonetPalette(
      name: '薰衣草',
      centerColor: Color(0xFFB8A9D4),
      edgeColor: Color(0xFF6B5B8A),
    ),
    // 4: Sunset Rose
    MonetPalette(
      name: '落日玫瑰',
      centerColor: Color(0xFFD4A0A0),
      edgeColor: Color(0xFF8A5050),
    ),
    // 5: Golden Wheat
    MonetPalette(
      name: '金色麦田',
      centerColor: Color(0xFFD4C49A),
      edgeColor: Color(0xFF8A7A4A),
    ),
    // 6: Deep Night
    MonetPalette(
      name: '深邃夜色',
      centerColor: Color(0xFF4A5568),
      edgeColor: Color(0xFF1A202C),
    ),
    // 7: Cherry Blossom
    MonetPalette(
      name: '樱花',
      centerColor: Color(0xFFEEC4D0),
      edgeColor: Color(0xFF9E6B7B),
    ),
  ];
}

class MonetPalette {
  final String name;
  final Color centerColor;
  final Color edgeColor;

  const MonetPalette({
    required this.name,
    required this.centerColor,
    required this.edgeColor,
  });
}

/// Universal background widget that supports multiple background types
class GameBackground extends StatelessWidget {
  final BackgroundConfig config;

  const GameBackground({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    switch (config.type) {
      case BackgroundType.monet:
        return _MonetBackground(paletteIndex: config.monetPaletteIndex);
      case BackgroundType.solidColor:
        return _SolidColorBackground(
          color: Color(config.solidColorValue ?? 0xFF2D3748),
        );
      case BackgroundType.image:
        // Future: image background
        return _MonetBackground(paletteIndex: config.monetPaletteIndex);
    }
  }
}

class _MonetBackground extends StatelessWidget {
  final int paletteIndex;

  const _MonetBackground({required this.paletteIndex});

  @override
  Widget build(BuildContext context) {
    final palette = MonetPalettes
        .palettes[paletteIndex.clamp(0, MonetPalettes.palettes.length - 1)];

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.3,
              colors: [palette.centerColor, palette.edgeColor],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: FeltTexturePainter(),
          ),
        ),
      ],
    );
  }
}

class _SolidColorBackground extends StatelessWidget {
  final Color color;

  const _SolidColorBackground({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            HSLColor.fromColor(color)
                .withLightness(
                    (HSLColor.fromColor(color).lightness + 0.1).clamp(0, 1))
                .toColor(),
            color,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class FeltTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);

    final int count = (size.width * size.height / 12).round();

    final pointsBlack = <Offset>[];
    final pointsWhite = <Offset>[];

    for (int i = 0; i < count; i++) {
      if (i % 2 == 0) {
        pointsBlack.add(Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ));
      } else {
        pointsWhite.add(Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ));
      }
    }

    final paintBlack = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final paintWhite = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPoints(ui.PointMode.points, pointsBlack, paintBlack);
    canvas.drawPoints(ui.PointMode.points, pointsWhite, paintWhite);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
