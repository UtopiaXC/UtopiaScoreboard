import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';

/// Dialog for adding a new player to the game.
class AddPlayerDialog extends StatefulWidget {
  const AddPlayerDialog({super.key});

  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  final _nameCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A202C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 400,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('添加玩家',
                  style: GoogleFonts.notoSansSc(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              _field(_nameCtrl, '名字', autofocus: true),
              const SizedBox(height: 14),
              _field(_scoreCtrl, '初始分数',
                  keyboard: TextInputType.number),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('取消',
                      style: GoogleFonts.notoSansSc(color: Colors.white54)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text('添加',
                      style: GoogleFonts.notoSansSc(
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool autofocus = false, TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      keyboardType: keyboard,
      style: GoogleFonts.notoSansSc(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSansSc(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF667EEA)),
        ),
      ),
    );
  }

  void _onAdd() {
    final name = _nameCtrl.text;
    final score = int.tryParse(_scoreCtrl.text) ?? 0;
    if (name.isNotEmpty) {
      final game = Provider.of<GameProvider>(context, listen: false);
      final screenSize = MediaQuery.of(context).size;
      const double cardWidth = 240.0;
      const double cardHeight = 100.0;

      Offset bestPos = const Offset(50, 50);
      double bestMinDist = -1;

      for (int attempt = 0; attempt < 50; attempt++) {
        double testX = 20.0 +
            (attempt % 5) * ((screenSize.width - cardWidth - 40) / 4);
        double testY = 50.0 +
            (attempt ~/ 5) *
                ((screenSize.height - cardHeight - 100) / 9);
        testX = testX.clamp(10, screenSize.width - cardWidth - 10);
        testY = testY.clamp(10, screenSize.height - cardHeight - 70);

        double minDist = double.infinity;
        for (var p in game.players) {
          final dx = testX - p.position.dx;
          final dy = testY - p.position.dy;
          final d = dx * dx + dy * dy;
          if (d < minDist) minDist = d;
        }
        if (game.players.isEmpty || minDist > bestMinDist) {
          bestMinDist = minDist;
          bestPos = Offset(testX, testY);
        }
      }
      game.addPlayer(name, score, position: bestPos);
      Navigator.pop(context);
    }
  }
}

