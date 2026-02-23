import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../screens/round_history_screen.dart';
import 'game/player_list_sheet.dart';
import 'game/game_settings_sheet.dart';
import 'game/add_player_dialog.dart';

/// Draggable floating toolbar for game controls.
class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  /// Approximate rendered height of the toolbar.
  static const double toolbarHeight = 46;

  /// Estimated width when expanded / collapsed.
  static const double expandedWidth = 290;
  static const double collapsedWidth = 90;

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  bool _isExpanded = true;

  final GlobalKey _moreButtonKey = GlobalKey();

  double _toolbarWidth() =>
      _isExpanded ? ControlPanel.expandedWidth : ControlPanel.collapsedWidth;

  Offset _getDefaultPosition(Size screenSize) {
    return Offset(
      (screenSize.width - _toolbarWidth()) / 2,
      screenSize.height - 56 - MediaQuery.of(context).padding.bottom - 12,
    );
  }

  Offset _getToolbarPosition(
      GameProvider game, Size screenSize, Orientation orientation) {
    final pos = game.getToolbarPosition(orientation);
    return pos ?? _getDefaultPosition(screenSize);
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    var pos = _getToolbarPosition(game, screenSize, orientation);
    final tw = _toolbarWidth();
    pos = Offset(
      pos.dx.clamp(0.0, screenSize.width - tw),
      pos.dy.clamp(0.0, screenSize.height - 50),
    );

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // absorb taps
        child: _buildToolbar(context, game, screenSize, orientation),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, GameProvider game, Size screenSize,
      Orientation orientation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 2),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              setState(() {
                final ss = MediaQuery.of(context).size;
                final orient = MediaQuery.of(context).orientation;
                final current = _getToolbarPosition(game, ss, orient);
                final tw = _toolbarWidth();
                double newX = current.dx + details.delta.dx;
                double newY = current.dy + details.delta.dy;
                newX = newX.clamp(0.0, ss.width - tw);
                newY = newY.clamp(0.0, ss.height - 50);
                game.setToolbarPosition(Offset(newX, newY), orient);
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

  Widget _dotRow() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [_dot(), const SizedBox(width: 3), _dot()],
      );

  Widget _dot() => Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
      );

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

  void _showMoreMenu() {
    final renderBox =
        _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final buttonPos = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPos.dx,
        buttonPos.dy - 8,
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
