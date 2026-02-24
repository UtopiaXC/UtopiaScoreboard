import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/control_panel.dart';
import '../widgets/score_panel.dart';
import '../widgets/game_background.dart';
import '../widgets/game/player_item.dart';
import 'home_screen.dart';

// Re-export extracted widgets so existing imports still work
export '../widgets/game/edit_player_sheet.dart' show EditPlayerSheet;
export '../widgets/game/add_player_dialog.dart' show AddPlayerDialog;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  Orientation? _lastOrientation;
  double? _lastTotalScale;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false).applyWakelock();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Called when screen size / orientation changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = Provider.of<GameProvider>(context, listen: false);
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final screenSize = MediaQuery.of(context).size;
      final orientation = MediaQuery.of(context).orientation;

      final autoScale = (screenSize.shortestSide / 360.0).clamp(1.0, 1.5);
      final totalScale = autoScale * settings.uiScale;
      final scaledSize = Size(
        screenSize.width / totalScale,
        screenSize.height / totalScale,
      );

      game.clampAllPlayers(scaledSize, orientation);
      if (orientation == Orientation.landscape) {
        game.ensureLandscapeLayout(scaledSize);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final unscaledSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    final autoScale = (unscaledSize.shortestSide / 360.0).clamp(1.0, 1.5);
    
    if (!settings.initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        settings.initializeUiScale(autoScale);
      });
    }

    final totalScale = settings.initialized ? settings.uiScale : autoScale;
    final scaledSize = Size(
      unscaledSize.width / totalScale,
      unscaledSize.height / totalScale,
    );

    // Clamp on every build if orientation or scale changed
    if (_lastOrientation != orientation || _lastTotalScale != totalScale) {
      _lastOrientation = orientation;
      _lastTotalScale = totalScale;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        game.clampAllPlayers(scaledSize, orientation);
        if (orientation == Orientation.landscape) {
          game.ensureLandscapeLayout(scaledSize);
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: GameBackground(config: game.backgroundConfig),
            ),
            // Tap on empty area to deselect
            Positioned.fill(
              child: GestureDetector(
                onTap: () => game.selectPlayer(null),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            // Scaled Game Content
            Positioned(
              left: 0,
              top: 0,
              width: scaledSize.width,
              height: scaledSize.height,
              child: Transform.scale(
                scale: totalScale,
                alignment: Alignment.topLeft,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(size: scaledSize),
                  child: Stack(
                    children: [
                      // Players
                      Consumer<GameProvider>(
                        builder: (context, game, child) {
                          return Stack(
                            children: game.players.map((player) {
                              final position = orientation == Orientation.portrait
                                  ? player.position
                                  : (player.landscapePosition ?? player.position);
                              return Positioned(
                                left: position.dx,
                                top: position.dy,
                                child: PlayerItem(
                                  player: player,
                                  screenSize: scaledSize,
                                  totalScale: totalScale,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      // Control Panel (toolbar)
                      const ControlPanel(),
                      // Score Panel (floating, positioned relative to toolbar)
                      const ScorePanel(),
                      // Top-left: back + rotate
                      _TopLeftButtons(orientation: orientation),
                      // Top-right: round display
                      _TopRightRound(game: game),
                    ],
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

class _TopLeftButtons extends StatelessWidget {
  final Orientation orientation;
  const _TopLeftButtons({required this.orientation});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          ),
          const SizedBox(width: 6),
          _circleButton(
            icon: Icons.screen_rotation,
            onTap: () async {
              if (orientation == Orientation.portrait) {
                await SystemChrome.setPreferredOrientations([
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
              } else {
                await SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                ]);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child:
              Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
        ),
      ),
    );
  }
}

class _TopRightRound extends StatelessWidget {
  final GameProvider game;
  const _TopRightRound({required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined,
                      color: Colors.white.withValues(alpha: 0.6), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '第 ${game.currentRound} 回合',
                    style: GoogleFonts.notoSansSc(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 18,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleNextRound(context, game),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.arrow_forward,
                      color: Colors.greenAccent, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNextRound(BuildContext context, GameProvider game) {
    if (game.quickNextRound) {
      if (!game.hasCurrentRoundChanges) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A202C),
            title:
                Text('确认', style: GoogleFonts.notoSansSc(color: Colors.white)),
            content: Text('当前回合没有分数变化，是否空过进入下一回合？',
                style: GoogleFonts.notoSansSc(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('取消',
                    style: GoogleFonts.notoSansSc(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () {
                  game.finishRound();
                  Navigator.pop(ctx);
                },
                child: Text('确认',
                    style:
                        GoogleFonts.notoSansSc(color: const Color(0xFF667EEA))),
              ),
            ],
          ),
        );
      } else {
        game.finishRound();
      }
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A202C),
          title:
              Text('结束回合', style: GoogleFonts.notoSansSc(color: Colors.white)),
          content: Text('确认结束当前回合并进入下一回合？',
              style: GoogleFonts.notoSansSc(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消',
                  style: GoogleFonts.notoSansSc(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                game.finishRound();
                Navigator.pop(ctx);
              },
              child: Text('确认',
                  style:
                      GoogleFonts.notoSansSc(color: const Color(0xFF667EEA))),
            ),
          ],
        ),
      );
    }
  }
}
