import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'control_panel.dart';

/// Floating score panel that appears above/below the [ControlPanel]
/// when a player is selected. Horizontally centered on the control panel.
///
/// This is a pure StatelessWidget — no measurement, no post-frame callbacks.
/// It estimates its own width from the score steps count to avoid any
/// fly-in animation or position jumps.
class ScorePanel extends StatelessWidget {
  const ScorePanel({super.key});

  static const double _gap = 8;
  static const double _panelHeight = 46;
  static const double _hMargin = 8;

  /// Estimate panel width from content.
  /// Each step button ≈ 42px, sign toggle ≈ 30px, player name ≈ 60px,
  /// plus padding (24) and spacing.
  static double _estimatePanelWidth(int stepCount, String playerName) {
    final nameWidth = (playerName.length * 10.0).clamp(30.0, 120.0);
    final buttonsWidth = stepCount * 42.0;
    const signToggle = 30.0;
    const spacing = 8.0 + 6.0; // gaps between name, sign, buttons
    const hPadding = 24.0;
    return nameWidth + signToggle + buttonsWidth + spacing + hPadding;
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final selected = game.selectedPlayer;
    if (selected == null || game.isZeroSum) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Read toolbar position (same source as ControlPanel)
    final defaultPos = Offset(
      (screenSize.width - ControlPanel.expandedWidth) / 2,
      screenSize.height - 56 - bottomPad - 12,
    );
    Offset barPos = game.getToolbarPosition(orientation) ?? defaultPos;
    barPos = Offset(
      barPos.dx.clamp(0.0, screenSize.width - ControlPanel.collapsedWidth),
      barPos.dy.clamp(0.0, screenSize.height - 50),
    );

    final bool barInUpperHalf = barPos.dy < screenSize.height / 2;

    // Vertical position
    double topPos;
    if (barInUpperHalf) {
      topPos = barPos.dy + ControlPanel.toolbarHeight + _gap;
    } else {
      topPos = barPos.dy - _panelHeight - _gap;
    }
    topPos = topPos.clamp(4.0, screenSize.height - _panelHeight - 4);

    // Horizontal: center on control panel center X
    final double controlCenterX = barPos.dx + ControlPanel.expandedWidth / 2;
    final double maxWidth = screenSize.width - _hMargin * 2;
    final double estimatedW = _estimatePanelWidth(
      game.scoreSteps.length,
      selected.name,
    ).clamp(0.0, maxWidth);

    double leftPos = controlCenterX - estimatedW / 2;
    leftPos = leftPos.clamp(_hMargin, screenSize.width - estimatedW - _hMargin);

    return Positioned(
      top: topPos,
      left: leftPos,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // absorb taps
        child: _ScorePanelContent(
          game: game,
          maxWidth: maxWidth,
        ),
      ),
    );
  }
}

class _ScorePanelContent extends StatelessWidget {
  final GameProvider game;
  final double maxWidth;

  const _ScorePanelContent({
    required this.game,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final selected = game.selectedPlayer!;
    final steps = game.scoreSteps;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
              selected.name,
              style: GoogleFonts.notoSansSc(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => game.toggleSign(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      (game.isNegative ? Colors.redAccent : Colors.greenAccent)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  game.isNegative ? Icons.remove : Icons.add,
                  color:
                      game.isNegative ? Colors.redAccent : Colors.greenAccent,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ...steps.map((step) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => game.applyScoreChange(step),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        constraints:
                            const BoxConstraints(minWidth: 34, minHeight: 30),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: game.isNegative
                              ? Colors.red.withValues(alpha: 0.65)
                              : Colors.green.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$step',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
