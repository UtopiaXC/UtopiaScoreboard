import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';

/// Bottom sheet for editing a player's name and score.
class EditPlayerSheet extends StatefulWidget {
  final Player player;
  const EditPlayerSheet({super.key, required this.player});

  @override
  State<EditPlayerSheet> createState() => _EditPlayerSheetState();
}

class _EditPlayerSheetState extends State<EditPlayerSheet> {
  late TextEditingController _nameController;
  late TextEditingController _scoreController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player.name);
    _scoreController =
        TextEditingController(text: widget.player.score.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A202C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('编辑玩家',
                  style: GoogleFonts.notoSansSc(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildTextField(_nameController, '名字'),
              const SizedBox(height: 14),
              _buildTextField(_scoreController, '当前分数',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Provider.of<GameProvider>(context, listen: false)
                          .removePlayer(widget.player.id);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('删除玩家',
                        style: GoogleFonts.notoSansSc(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text;
                      final score = int.tryParse(_scoreController.text) ??
                          widget.player.score;
                      final provider =
                          Provider.of<GameProvider>(context, listen: false);
                      provider.updatePlayerName(widget.player.id, name);
                      provider.updatePlayerBaseScore(widget.player.id, score);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('保存',
                        style: GoogleFonts.notoSansSc(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      style: GoogleFonts.notoSansSc(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSansSc(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF667EEA)),
        ),
      ),
    );
  }
}
