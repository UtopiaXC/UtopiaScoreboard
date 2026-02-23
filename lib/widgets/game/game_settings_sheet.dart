import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/game_data.dart';
import '../../providers/game_provider.dart';

/// In-game settings bottom sheet (screen always on, quick round, zero-sum, background).
class GameSettingsSheet extends StatelessWidget {
  const GameSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A202C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _handle(),
            const SizedBox(height: 16),
            Center(
              child: Text('设置',
                  style: GoogleFonts.notoSansSc(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingSwitch(
                    label: '屏幕常亮',
                    icon: Icons.brightness_7_outlined,
                    value: game.isScreenAlwaysOn,
                    onChanged: (v) => game.toggleScreenAlwaysOn(v),
                  ),
                  const SizedBox(height: 12),
                  _SettingSwitch(
                    label: '快速下一回合',
                    icon: Icons.fast_forward_outlined,
                    value: game.quickNextRound,
                    onChanged: (v) => game.setQuickNextRound(v),
                  ),
                  const SizedBox(height: 4),
                  _subtitleText('开启后，仅在当前回合无分数变化时弹窗确认'),
                  const SizedBox(height: 12),
                  _SettingSwitch(
                    label: '零和博弈模式',
                    icon: Icons.swap_horiz,
                    value: game.isZeroSum,
                    onChanged: (v) => game.setZeroSum(v),
                  ),
                  const SizedBox(height: 4),
                  _subtitleText('开启后，只能通过玩家间拖拽转移分数'),
                  const SizedBox(height: 20),
                  _BackgroundSection(game: game),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('关闭', style: GoogleFonts.notoSansSc(fontSize: 16)),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  static Widget _handle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  static Widget _subtitleText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: GoogleFonts.notoSansSc(
          color: Colors.white.withOpacity(0.4),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: GoogleFonts.notoSansSc(
                  color: Colors.white.withOpacity(0.9), fontSize: 15)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF667EEA),
        ),
      ],
    );
  }
}

class _BackgroundSection extends StatelessWidget {
  final GameProvider game;
  const _BackgroundSection({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('背景',
            style: GoogleFonts.notoSansSc(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          _BackgroundTypeChip(
            label: '莫奈桌布',
            isSelected: game.backgroundConfig.type == BackgroundType.monet,
            onTap: () => game.updateBackgroundConfig(BackgroundConfig(
              type: BackgroundType.monet,
              monetPaletteIndex: game.backgroundConfig.monetPaletteIndex,
            )),
          ),
          _BackgroundTypeChip(
            label: '纯色桌布',
            isSelected: game.backgroundConfig.type == BackgroundType.solidColor,
            onTap: () => game.updateBackgroundConfig(BackgroundConfig(
              type: BackgroundType.solidColor,
              solidColorValue:
                  game.backgroundConfig.solidColorValue ?? 0xFF2D3748,
            )),
          ),
        ]),
        const SizedBox(height: 12),
        if (game.backgroundConfig.type == BackgroundType.monet)
          _MonetPaletteSelector(game: game),
        if (game.backgroundConfig.type == BackgroundType.solidColor)
          _SolidColorSelector(game: game),
      ],
    );
  }
}

class _BackgroundTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _BackgroundTypeChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF667EEA)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF667EEA)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(label,
            style: GoogleFonts.notoSansSc(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 13)),
      ),
    );
  }
}

class _MonetPaletteSelector extends StatelessWidget {
  final GameProvider game;
  const _MonetPaletteSelector({required this.game});

  static const List<Map<String, Color>> _monetPalettes = [
    {'center': Color(0xFF8FB3A3), 'edge': Color(0xFF4A6B5D)},
    {'center': Color(0xFFC4967A), 'edge': Color(0xFF8B5E3C)},
    {'center': Color(0xFF7BA7C9), 'edge': Color(0xFF3A5F7F)},
    {'center': Color(0xFFB8A9D4), 'edge': Color(0xFF6B5B8A)},
    {'center': Color(0xFFD4A0A0), 'edge': Color(0xFF8A5050)},
    {'center': Color(0xFFD4C49A), 'edge': Color(0xFF8A7A4A)},
    {'center': Color(0xFF4A5568), 'edge': Color(0xFF1A202C)},
    {'center': Color(0xFFEEC4D0), 'edge': Color(0xFF9E6B7B)},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _monetPalettes.length,
        itemBuilder: (context, index) {
          final palette = _monetPalettes[index];
          final isSelected =
              game.backgroundConfig.monetPaletteIndex == index;
          return GestureDetector(
            onTap: () => game.updateBackgroundConfig(
              BackgroundConfig(
                  type: BackgroundType.monet, monetPaletteIndex: index),
            ),
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2.5)
                    : Border.all(color: Colors.white.withOpacity(0.15)),
                gradient: RadialGradient(
                    colors: [palette['center']!, palette['edge']!]),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _SolidColorSelector extends StatelessWidget {
  final GameProvider game;
  const _SolidColorSelector({required this.game});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF2D3748),
      Color(0xFF1A365D),
      Color(0xFF22543D),
      Color(0xFF553C9A),
      Color(0xFF742A2A),
      Color(0xFF744210),
      Color(0xFF234E52),
      Color(0xFF3C366B),
    ];
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: colors.map((c) {
          final isSelected =
              game.backgroundConfig.solidColorValue == c.toARGB32();
          return GestureDetector(
            onTap: () => game.updateBackgroundConfig(
              BackgroundConfig(
                  type: BackgroundType.solidColor,
                  solidColorValue: c.toARGB32()),
            ),
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2.5)
                    : Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

