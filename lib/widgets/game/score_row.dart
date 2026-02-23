import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';

/// Inline score adjustment row shown when a player is selected.
class ScoreRow extends StatelessWidget {
  final GameProvider game;
  final Player selectedPlayer;
  final Size screenSize;

  const ScoreRow({
    super.key,
    required this.game,
    required this.selectedPlayer,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: screenSize.width - 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedPlayer.name,
              style: GoogleFonts.notoSansSc(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            _SignToggle(game: game),
            const SizedBox(width: 6),
            ...game.scoreSteps.map((step) => _ScoreStepButton(
                  game: game,
                  step: step,
                )),
          ],
        ),
      ),
    );
  }
}

class _SignToggle extends StatelessWidget {
  final GameProvider game;
  const _SignToggle({required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => game.toggleSign(),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: (game.isNegative ? Colors.redAccent : Colors.greenAccent)
              .withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          game.isNegative ? Icons.remove : Icons.add,
          color: game.isNegative ? Colors.redAccent : Colors.greenAccent,
          size: 18,
        ),
      ),
    );
  }
}

class _ScoreStepButton extends StatelessWidget {
  final GameProvider game;
  final int step;
  const _ScoreStepButton({required this.game, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        onPressed: () => game.applyScoreChange(step),
        style: ElevatedButton.styleFrom(
          backgroundColor: game.isNegative
              ? Colors.red.withOpacity(0.65)
              : Colors.green.withOpacity(0.65),
          foregroundColor: Colors.white,
          minimumSize: const Size(34, 30),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text('$step', style: GoogleFonts.outfit(fontSize: 13)),
      ),
    );
  }
}

