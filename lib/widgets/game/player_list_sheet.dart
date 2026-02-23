import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import 'add_player_dialog.dart';
import 'edit_player_sheet.dart';

/// Bottom sheet showing player list with edit/delete/reset actions.
class PlayerListSheet extends StatelessWidget {
  final GameProvider game;
  const PlayerListSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: screenSize.height * 0.6),
      decoration: const BoxDecoration(
        color: Color(0xFF1A202C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(),
          const SizedBox(height: 12),
          _header(context),
          const SizedBox(height: 8),
          Flexible(
            child: Consumer<GameProvider>(
              builder: (context, game, _) {
                if (game.players.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('暂无玩家',
                        style: GoogleFonts.notoSansSc(color: Colors.white38)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: game.players.length,
                  itemBuilder: (context, index) {
                    final player = game.players[index];
                    return _PlayerListItem(
                      player: player,
                      game: game,
                      screenSize: screenSize,
                      orientation: orientation,
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: bottomPad + 12),
        ],
      ),
    );
  }

  Widget _handle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text('玩家列表',
              style: GoogleFonts.notoSansSc(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF667EEA)),
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => const AddPlayerDialog(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlayerListItem extends StatelessWidget {
  final dynamic player;
  final GameProvider game;
  final Size screenSize;
  final Orientation orientation;

  const _PlayerListItem({
    required this.player,
    required this.game,
    required this.screenSize,
    required this.orientation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: player.color,
            radius: 16,
            child: Text(
              player.name.isNotEmpty ? player.name[0] : '?',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name,
                    style: GoogleFonts.notoSansSc(
                        color: Colors.white, fontSize: 14)),
                Text('分数: ${player.totalScore}',
                    style: GoogleFonts.outfit(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.my_location,
                color: Colors.white.withOpacity(0.5), size: 20),
            tooltip: '复位到中央',
            onPressed: () =>
                game.resetPlayerPosition(player.id, screenSize, orientation),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(Icons.edit,
                color: Colors.white.withOpacity(0.5), size: 20),
            tooltip: '编辑',
            onPressed: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => EditPlayerSheet(player: player),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 20),
            tooltip: '删除',
            onPressed: () => game.removePlayer(player.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

