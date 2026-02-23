import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';

/// Dialog for transferring scores between two players.
class TransferDialog extends StatelessWidget {
  final Player source;
  final Player target;
  final GameProvider game;

  const TransferDialog({
    super.key,
    required this.source,
    required this.target,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    int transferAmount = 0;
    bool reversed = false;

    return StatefulBuilder(
      builder: (ctx, setDialogState) {
        final from = reversed ? target : source;
        final to = reversed ? source : target;
        return Dialog(
          backgroundColor: const Color(0xFF1A202C),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              maxWidth: 400,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('分数转移',
                      style: GoogleFonts.notoSansSc(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _PlayerRow(
                    from: from,
                    to: to,
                    onReverse: () =>
                        setDialogState(() => reversed = !reversed),
                  ),
                  const SizedBox(height: 8),
                  Text('点击箭头可反向',
                      style: GoogleFonts.notoSansSc(
                          color: Colors.white30, fontSize: 11)),
                  const SizedBox(height: 16),
                  Text('转移分数',
                      style: GoogleFonts.notoSansSc(
                          color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text('$transferAmount',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: game.scoreSteps
                        .map((step) => ElevatedButton(
                              onPressed: () => setDialogState(
                                  () => transferAmount += step),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF667EEA).withOpacity(0.8),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(44, 34),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: Text('+$step',
                                  style: GoogleFonts.outfit(fontSize: 13)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        setDialogState(() => transferAmount = 0),
                    child: Text('重置',
                        style: GoogleFonts.notoSansSc(
                            color: Colors.white38, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('取消',
                            style: GoogleFonts.notoSansSc(
                                color: Colors.white54)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: transferAmount > 0
                            ? () {
                                game.transferScore(
                                    from.id, to.id, transferAmount);
                                Navigator.pop(ctx);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.grey.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text('确认转移',
                            style: GoogleFonts.notoSansSc(
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final Player from;
  final Player to;
  final VoidCallback onReverse;

  const _PlayerRow(
      {required this.from, required this.to, required this.onReverse});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _avatar(from),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onReverse,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_forward,
                color: Colors.greenAccent.withOpacity(0.8), size: 28),
          ),
        ),
        const SizedBox(width: 12),
        _avatar(to),
      ],
    );
  }

  Widget _avatar(Player p) {
    return Column(children: [
      CircleAvatar(
        backgroundColor: p.color,
        radius: 20,
        child: Text(p.name.isNotEmpty ? p.name[0] : '?',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      const SizedBox(height: 4),
      Text(p.name,
          style: GoogleFonts.notoSansSc(color: Colors.white70, fontSize: 12)),
    ]);
  }
}

