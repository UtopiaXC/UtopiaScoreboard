import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';
import '../../widgets/player_avatar.dart';
import 'edit_player_sheet.dart';
import 'transfer_dialog.dart';

/// A draggable, tappable player card on the game board.
class PlayerItem extends StatefulWidget {
  final Player player;
  final Size screenSize;
  final double totalScale;
  const PlayerItem({super.key, required this.player, required this.screenSize, this.totalScale = 1.0});

  @override
  State<PlayerItem> createState() => _PlayerItemState();
}

class _PlayerItemState extends State<PlayerItem> {
  double _baseScale = 1.0;
  final GlobalKey _menuButtonKey = GlobalKey();

  void _showPlayerMenu() {
    final renderBox =
        _menuButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final buttonPos = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPos.dx + buttonSize.width,
        buttonPos.dy,
        buttonPos.dx + buttonSize.width + 1,
        buttonPos.dy + buttonSize.height,
      ),
      color: const Color(0xFF2D3748),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            const Icon(Icons.edit, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Text('编辑', style: GoogleFonts.notoSansSc(color: Colors.white)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            const SizedBox(width: 10),
            Text('删除玩家',
                style: GoogleFonts.notoSansSc(color: Colors.redAccent)),
          ]),
        ),
      ],
    ).then((value) {
      if (!mounted) return;
      if (value == 'edit') {
        _showEditSheet();
      } else if (value == 'delete') {
        _confirmDelete();
      }
    });
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPlayerSheet(player: widget.player),
    );
  }

  void _confirmDelete() {
    final game = Provider.of<GameProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A202C),
        title: Text('删除玩家', style: GoogleFonts.notoSansSc(color: Colors.white)),
        content: Text('确定要删除 ${widget.player.name} 吗？',
            style: GoogleFonts.notoSansSc(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消',
                style: GoogleFonts.notoSansSc(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              game.removePlayer(widget.player.id);
              Navigator.pop(ctx);
            },
            child: Text('删除',
                style: GoogleFonts.notoSansSc(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context, listen: false);
    final orientation = MediaQuery.of(context).orientation;
    final screenSize = widget.screenSize;

    const double baseCardWidth = 240.0;
    const double baseCardHeight = 100.0;
    final double currentCardWidth = baseCardWidth * widget.player.scale;
    final double currentCardHeight = baseCardHeight * widget.player.scale;

    final originalPosition = orientation == Orientation.portrait
        ? widget.player.position
        : (widget.player.landscapePosition ?? widget.player.position);

    return GestureDetector(
      onScaleStart: (details) {
        _baseScale = widget.player.scale;
      },
      onScaleUpdate: (details) {
        if (details.pointerCount >= 2) {
          game.updatePlayerScale(widget.player.id, _baseScale * details.scale);
        }
      },
      child: Draggable<Player>(
        data: widget.player,
        dragAnchorStrategy: (Draggable<Object> draggable, BuildContext context, Offset position) {
          final RenderBox renderObject = context.findRenderObject() as RenderBox;
          return renderObject.globalToLocal(position) * widget.totalScale;
        },
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: widget.totalScale,
            alignment: Alignment.topLeft,
            child: PlayerAvatar(player: widget.player, isDragging: true),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: PlayerAvatar(player: widget.player),
        ),
        onDragStarted: () => game.clearTransferFlag(),
        onDragEnd: (details) {
          if (game.transferTriggered) {
            game.updatePlayerPosition(
                widget.player.id, originalPosition, orientation);
            game.clearTransferFlag();
            return;
          }
          double newX = details.offset.dx / widget.totalScale;
          double newY = details.offset.dy / widget.totalScale;
          newX = newX.clamp(0, screenSize.width - currentCardWidth);
          newY = newY.clamp(0, screenSize.height - currentCardHeight - 10);
          game.updatePlayerPosition(
              widget.player.id, Offset(newX, newY), orientation);
        },
        child: DragTarget<Player>(
          onWillAcceptWithDetails: (data) => data.data.id != widget.player.id,
          onAcceptWithDetails: (data) {
            game.clearTransferFlag();
            game.setTransferTriggered();
            showDialog(
              context: context,
              builder: (context) => TransferDialog(
                source: data.data,
                target: widget.player,
                game: game,
              ),
            );
          },
          builder: (context, candidateData, rejectedData) {
            final isHighlighted = candidateData.isNotEmpty;
            return GestureDetector(
              onTap: () {
                if (game.selectedPlayerId == widget.player.id) {
                  game.selectPlayer(null);
                } else {
                  game.selectPlayer(widget.player.id);
                }
              },
              onLongPress: () => _showEditSheet(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: isHighlighted
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      )
                    : null,
                child: PlayerAvatar(
                  player: widget.player,
                  isSelected: game.selectedPlayerId == widget.player.id,
                  menuButtonKey: _menuButtonKey,
                  onMenuTap: () => _showPlayerMenu(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
