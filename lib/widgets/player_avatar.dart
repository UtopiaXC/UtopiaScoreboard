import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/player.dart';
import 'dart:math';

class PlayerAvatar extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final bool isDragging;
  final VoidCallback? onMenuTap;
  final GlobalKey? menuButtonKey;

  const PlayerAvatar({
    super.key,
    required this.player,
    this.isSelected = false,
    this.isDragging = false,
    this.onMenuTap,
    this.menuButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    const double avatarSize = 80.0;
    const double cardWidth = 240.0;
    const double cardHeight = 100.0;

    return Transform.scale(
      scale: player.scale,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            // Info Background (Right side) - now 10% opacity
            Positioned(
              left: 40,
              right: 0,
              top: 15,
              bottom: 15,
              child: Container(
                padding: const EdgeInsets.only(
                    left: 50, right: 8, top: 4, bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '玩家：${player.name}',
                            style: GoogleFonts.notoSansSc(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '积分：${player.totalScore}',
                                  style: GoogleFonts.notoSansSc(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (player.currentRoundChange != 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  player.currentRoundChange > 0
                                      ? '+${player.currentRoundChange}'
                                      : '${player.currentRoundChange}',
                                  style: GoogleFonts.outfit(
                                    color: player.currentRoundChange > 0
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 3-dot menu button
                    if (onMenuTap != null)
                      GestureDetector(
                        key: menuButtonKey,
                        onTap: onMenuTap,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Avatar (Left side)
            Positioned(
              left: 0,
              top: 10,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.yellowAccent.withValues(alpha: 0.6),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    painter: AbstractWavePainter(color: player.color),
                    size: Size(avatarSize, avatarSize),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AbstractWavePainter extends CustomPainter {
  final Color color;

  AbstractWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = color;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final random = Random(color.toARGB32());

    for (int i = 0; i < 5; i++) {
      Path path = Path();

      final hsl = HSLColor.fromColor(color);
      final newHue = (hsl.hue + (random.nextDouble() * 60 - 30)) % 360;
      final newLightness =
          (hsl.lightness + (random.nextDouble() * 0.4 - 0.2)).clamp(0.2, 0.8);

      paint.color = HSLColor.fromAHSL(
              1.0, newHue, hsl.saturation, newLightness.toDouble())
          .toColor();

      double startY = size.height * random.nextDouble();
      path.moveTo(0, startY);

      double cp1x = size.width * (0.2 + random.nextDouble() * 0.3);
      double cp1y = size.height * random.nextDouble();
      double cp2x = size.width * (0.5 + random.nextDouble() * 0.3);
      double cp2y = size.height * random.nextDouble();
      double endY = size.height * random.nextDouble();

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, size.width, endY);

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
