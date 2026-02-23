import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../screens/round_history_screen.dart';
import 'game/score_row.dart';
import 'game/player_list_sheet.dart';
import 'game/game_settings_sheet.dart';
import 'game/add_player_dialog.dart';

/// Unified draggable bottom toolbar with integrated score panel.
class ScoreControlPanel extends StatefulWidget {
  const ScoreControlPanel({super.key});

  @override
  State<ScoreControlPanel> createState() => _ScoreControlPanelState();
}

class _ScoreControlPanelState extends State<ScoreControlPanel> {
  bool _isExpanded = true;

  final GlobalKey _moreButtonKey = GlobalKey();

  /// Stores the toolbar position per orientation; null means default (bottom center)
  Offset? _portraitPosition;
  Offset? _landscapePosition;

  /// Track current orientation
  Orientation? _lastOrientation;

  double _estimatedToolbarWidth() {
    return _isExpanded ? 290 : 90;
  }

  Offset _getDefaultPosition(Size screenSize) {
    return Offset(
      (screenSize.width - _estimatedToolbarWidth()) / 2,
      screenSize.height - 56 - MediaQuery.of(context).padding.bottom - 12,
    );
  }

  Offset _getToolbarPosition(Size screenSize, Orientation orientation) {
    final pos = orientation == Orientation.portrait
        ? _portraitPosition
        : _landscapePosition;
    return pos ?? _getDefaultPosition(screenSize);
  }

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final px = prefs.getDouble('toolbar_portrait_x');
    final py = prefs.getDouble('toolbar_portrait_y');
    if (px != null && py != null) {
      _portraitPosition = Offset(px, py);
    }
    final lx = prefs.getDouble('toolbar_landscape_x');
    final ly = prefs.getDouble('toolbar_landscape_y');
    if (lx != null && ly != null) {
      _landscapePosition = Offset(lx, ly);
    }
    if (mounted) setState(() {});
  }

  Future<void> _savePosition(Offset pos, Orientation orientation) async {
    final prefs = await SharedPreferences.getInstance();
    if (orientation == Orientation.portrait) {
      await prefs.setDouble('toolbar_portrait_x', pos.dx);
      await prefs.setDouble('toolbar_portrait_y', pos.dy);
    } else {
      await prefs.setDouble('toolbar_landscape_x', pos.dx);
      await prefs.setDouble('toolbar_landscape_y', pos.dy);
    }
  }

  void _setToolbarPosition(Offset pos, Orientation orientation) {
    if (orientation == Orientation.portrait) {
      _portraitPosition = pos;
    } else {
      _landscapePosition = pos;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final selectedPlayer = game.selectedPlayer;
    final showScorePanel = selectedPlayer != null && !(game.isZeroSum);
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    _lastOrientation = orientation;

    // Clamp toolbar position to screen bounds
    var pos = _getToolbarPosition(screenSize, orientation);
    final toolbarW = _estimatedToolbarWidth();
    pos = Offset(
      pos.dx.clamp(0.0, screenSize.width - toolbarW),
      pos.dy.clamp(0.0, screenSize.height - 50),
    );

    // Determine if bar is in the upper or lower half
    final bool barInUpperHalf = pos.dy < screenSize.height / 2;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: _buildCombinedWidget(
        context, game, screenSize, showScorePanel, selectedPlayer, barInUpperHalf,
      ),
    );
  }

  Widget _buildCombinedWidget(BuildContext context, GameProvider game,
      Size screenSize, bool showScorePanel, Player? selectedPlayer, bool barInUpperHalf) {
    final scoreWidget = AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: barInUpperHalf ? Alignment.topCenter : Alignment.bottomCenter,
      child: showScorePanel && selectedPlayer != null
          ? Padding(
              padding: barInUpperHalf
                  ? const EdgeInsets.only(top: 4)
                  : const EdgeInsets.only(bottom: 4),
              child: ScoreRow(
                game: game,
                selectedPlayer: selectedPlayer,
                screenSize: screenSize,
              ),
            )
          : const SizedBox.shrink(),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: barInUpperHalf
          ? [_buildToolbar(context, game, screenSize), scoreWidget]
          : [scoreWidget, _buildToolbar(context, game, screenSize)],
    );
  }

  Widget _buildToolbar(BuildContext context, GameProvider game, Size screenSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              setState(() {
                final ss = MediaQuery.of(context).size;
                final orient = MediaQuery.of(context).orientation;
                final current = _getToolbarPosition(ss, orient);
                final tw = _estimatedToolbarWidth();
                double newX = current.dx + details.delta.dx;
                double newY = current.dy + details.delta.dy;
                newX = newX.clamp(0.0, ss.width - tw);
                newY = newY.clamp(0.0, ss.height - 50);
                final newPos = Offset(newX, newY);
                _setToolbarPosition(newPos, orient);
                _savePosition(newPos, orient);
              });
            },
            child: SizedBox(
              width: 24,
              height: 34,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dotRow(),
                    const SizedBox(height: 3),
                    _dotRow(),
                    const SizedBox(height: 3),
                    _dotRow(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _toolbarButton(
            icon: _isExpanded ? Icons.menu_open : Icons.menu,
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded) ...[
            const SizedBox(width: 6),
            _toolbarButton(
              icon: Icons.arrow_forward,
              color: Colors.greenAccent,
              onTap: () => _handleNextRound(context, game),
            ),
            const SizedBox(width: 6),
            _toolbarButton(
              icon: Icons.person_add,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddPlayerDialog(),
                );
              },
            ),
            const SizedBox(width: 6),
            _toolbarButton(
              icon: Icons.people_outline,
              onTap: () => _showPlayerList(context, game),
            ),
            const SizedBox(width: 6),
            _toolbarButton(
              icon: Icons.history,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RoundHistoryScreen()),
                );
              },
            ),
            const SizedBox(width: 6),
            _toolbarButton(
              icon: Icons.more_vert,
              key: _moreButtonKey,
              onTap: () => _showMoreMenu(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dotRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_dot(), const SizedBox(width: 3), _dot()],
    );
  }

  Widget _dot() {
    return Container(
      width: 4, height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    VoidCallback? onTap,
    Color color = Colors.white,
    Key? key,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 22),
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
            title: Text('确认', style: GoogleFonts.notoSansSc(color: Colors.white)),
            content: Text('当前回合没有分数变化，是否空过进入下一回合？',
                style: GoogleFonts.notoSansSc(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('取消', style: GoogleFonts.notoSansSc(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () { game.finishRound(); Navigator.pop(ctx); },
                child: Text('确认', style: GoogleFonts.notoSansSc(color: const Color(0xFF667EEA))),
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
          title: Text('结束回合', style: GoogleFonts.notoSansSc(color: Colors.white)),
          content: Text('确认结束当前回合并进入下一回合？',
              style: GoogleFonts.notoSansSc(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消', style: GoogleFonts.notoSansSc(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () { game.finishRound(); Navigator.pop(ctx); },
              child: Text('确认', style: GoogleFonts.notoSansSc(color: const Color(0xFF667EEA))),
            ),
          ],
        ),
      );
    }
  }

  void _showMoreMenu() {
    final renderBox =
        _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final buttonPos = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPos.dx, buttonPos.dy - 8,
        buttonPos.dx + buttonSize.width,
        buttonPos.dy + buttonSize.height,
      ),
      color: const Color(0xFF2D3748),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'settings',
          child: Row(children: [
            const Icon(Icons.settings, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Text('设置', style: GoogleFonts.notoSansSc(color: Colors.white)),
          ]),
        ),
      ],
    ).then((value) {
      if (!mounted) return;
      if (value == 'settings') {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const GameSettingsSheet(),
        );
      }
    });
  }

  void _showPlayerList(BuildContext context, GameProvider game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlayerListSheet(game: game),
    );
  }
}

