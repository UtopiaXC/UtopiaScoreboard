import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/game_data.dart';
import '../providers/game_provider.dart';
import '../utils/game_storage.dart';
import '../utils/update_util.dart';
import '../widgets/game_background.dart';
import 'app_settings_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<GameSummary> _savedGames = [];
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    // Disable wakelock when on home screen
    WakelockPlus.disable();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadGames();
    // Auto-check for updates after a small delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          UpdateUtil.checkAndShow(context, isManualCheck: false);
        }
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadGames() async {
    final games = await GameStorage.getGamesList();
    games.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    setState(() {
      _savedGames = games;
      _isLoading = false;
    });
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
        } else {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('再按一次返回退出',
                  style: GoogleFonts.notoSansSc(color: Colors.white)),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF2D3748),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: GameBackground(
                config: BackgroundConfig(
                  type: BackgroundType.monet,
                  monetPaletteIndex: 6,
                ),
              ),
            ),
            // Content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Title
                      Text(
                        'Utopia Scoreboard',
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '桌游计分器',
                        style: GoogleFonts.notoSansSc(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // New Game Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: _HeroButton(
                          icon: Icons.add_rounded,
                          label: '新建游戏',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          onTap: () => _showNewGameSheet(context),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Saved Games List
                      if (!_isLoading && _savedGames.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            children: [
                              Text(
                                '继续游戏',
                                style: GoogleFonts.notoSansSc(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Render all cards inline (no nested ListView)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: _savedGames.map((game) {
                              return _SavedGameCard(
                                game: game,
                                onTap: () => _loadGame(game.id),
                                onEdit: () => _showEditGameSheet(context, game),
                                onDelete: () => _deleteGame(game.id),
                              );
                            }).toList(),
                          ),
                        ),
                      ] else if (!_isLoading) ...[
                        const SizedBox(height: 60),
                        Icon(Icons.sports_esports_outlined,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 16),
                        Text(
                          '还没有保存的游戏',
                          style: GoogleFonts.notoSansSc(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 16,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 60),
                        const CircularProgressIndicator(color: Colors.white54),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Bottom-right: rotate + settings buttons
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final orientation = MediaQuery.of(context).orientation;
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
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.30),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Icon(Icons.screen_rotation,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AppSettingsScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.30),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Icon(Icons.settings,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewGameSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewGameSheet(
        onGameCreated: () => _loadGames(),
      ),
    );
  }

  void _showEditGameSheet(BuildContext context, GameSummary game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditGameSheet(
        gameSummary: game,
        onSaved: () => _loadGames(),
      ),
    );
  }

  Future<void> _loadGame(String gameId) async {
    final provider = Provider.of<GameProvider>(context, listen: false);
    final success = await provider.loadGame(gameId);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    }
  }

  Future<void> _deleteGame(String gameId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A202C),
        title: Text('删除游戏', style: GoogleFonts.notoSansSc(color: Colors.white)),
        content: Text('确定要删除这个游戏记录吗？此操作无法撤销。',
            style: GoogleFonts.notoSansSc(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消',
                style: GoogleFonts.notoSansSc(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除',
                style: GoogleFonts.notoSansSc(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await GameStorage.deleteGame(gameId);
      _loadGames();
    }
  }
}

class _HeroButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _HeroButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: GoogleFonts.notoSansSc(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Saved game card with 3-dot menu (edit / delete)
class _SavedGameCard extends StatelessWidget {
  final GameSummary game;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SavedGameCard({
    required this.game,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeDiff = DateTime.now().difference(game.updatedAt);
    String timeText;
    if (timeDiff.inMinutes < 1) {
      timeText = '刚刚';
    } else if (timeDiff.inHours < 1) {
      timeText = '${timeDiff.inMinutes} 分钟前';
    } else if (timeDiff.inDays < 1) {
      timeText = '${timeDiff.inHours} 小时前';
    } else {
      timeText = '${timeDiff.inDays} 天前';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                // Game icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.casino_outlined,
                      color: Colors.white70, size: 24),
                ),
                const SizedBox(width: 16),
                // Game info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: GoogleFonts.notoSansSc(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${game.playerCount} 位玩家 · 第 ${game.currentRound} 回合 · $timeText',
                        style: GoogleFonts.notoSansSc(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // 3-dot menu button
                _SavedGameMenuButton(
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 3-dot menu for saved game card
class _SavedGameMenuButton extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SavedGameMenuButton({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final GlobalKey btnKey = GlobalKey();
    return IconButton(
      key: btnKey,
      icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.4)),
      onPressed: () {
        final renderBox =
            btnKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final pos = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            pos.dx,
            pos.dy + size.height,
            pos.dx + size.width,
            pos.dy + size.height + 1,
          ),
          color: const Color(0xFF2D3748),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          items: [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  Text('编辑',
                      style: GoogleFonts.notoSansSc(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Text('删除',
                      style: GoogleFonts.notoSansSc(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
        ).then((value) {
          if (value == 'edit') {
            onEdit();
          } else if (value == 'delete') {
            onDelete();
          }
        });
      },
    );
  }
}

class _NewGameSheet extends StatefulWidget {
  final VoidCallback onGameCreated;
  const _NewGameSheet({required this.onGameCreated});

  @override
  State<_NewGameSheet> createState() => _NewGameSheetState();
}

class _NewGameSheetState extends State<_NewGameSheet> {
  final _nameController = TextEditingController(
      text: DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now()));
  int _playerCount = 4;
  int _initialScore = 0;
  final _initialScoreController = TextEditingController(text: '0');
  bool _isScreenAlwaysOn = true;
  bool _quickNextRound = false;
  bool _isZeroSum = false;
  BackgroundType _backgroundType = BackgroundType.monet;
  int _monetPaletteIndex = 0;
  Color _solidColor = const Color(0xFF2D3748);

  @override
  void dispose() {
    _nameController.dispose();
    _initialScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A202C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '新建游戏',
            style: GoogleFonts.notoSansSc(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 24 + bottomInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game Name
                  _buildLabel('游戏名称'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.notoSansSc(color: Colors.white),
                    decoration: _inputDecoration('输入游戏名称'),
                  ),
                  const SizedBox(height: 20),

                  // Player Count
                  _buildLabel('初始玩家数'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.white70),
                        onPressed: _playerCount > 1
                            ? () => setState(() => _playerCount--)
                            : null,
                      ),
                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_playerCount',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.white70),
                        onPressed: _playerCount < 12
                            ? () => setState(() => _playerCount++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Initial Score
                  _buildLabel('初始分数'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _initialScoreController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.notoSansSc(color: Colors.white),
                    decoration: _inputDecoration('每位玩家的初始分数'),
                    onChanged: (v) {
                      _initialScore = int.tryParse(v) ?? 0;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Background
                  _buildLabel('背景'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildBackgroundTypeChip('莫奈桌布', BackgroundType.monet),
                      _buildBackgroundTypeChip(
                          '纯色桌布', BackgroundType.solidColor),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_backgroundType == BackgroundType.monet) ...[
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: MonetPalettes.palettes.length,
                        itemBuilder: (context, index) {
                          final palette = MonetPalettes.palettes[index];
                          final isSelected = _monetPaletteIndex == index;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _monetPaletteIndex = index),
                            child: Container(
                              width: 52,
                              height: 52,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.white, width: 2.5)
                                    : Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.15)),
                                gradient: RadialGradient(
                                  colors: [
                                    palette.centerColor,
                                    palette.edgeColor,
                                  ],
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  if (_backgroundType == BackgroundType.solidColor) ...[
                    SizedBox(
                      height: 60,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final c in [
                            const Color(0xFF2D3748),
                            const Color(0xFF1A365D),
                            const Color(0xFF22543D),
                            const Color(0xFF553C9A),
                            const Color(0xFF742A2A),
                            const Color(0xFF744210),
                            const Color(0xFF234E52),
                            const Color(0xFF3C366B),
                          ])
                            GestureDetector(
                              onTap: () => setState(() => _solidColor = c),
                              child: Container(
                                width: 52,
                                height: 52,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(14),
                                  border: _solidColor == c
                                      ? Border.all(
                                          color: Colors.white, width: 2.5)
                                      : Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.15)),
                                ),
                                child: _solidColor == c
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 20)
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  // Settings
                  _buildSwitchRow('屏幕常亮', _isScreenAlwaysOn, (v) {
                    setState(() => _isScreenAlwaysOn = v);
                  }),
                  const SizedBox(height: 12),
                  _buildSwitchRow('快速下一回合', _quickNextRound, (v) {
                    setState(() => _quickNextRound = v);
                  }),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '开启后，仅在当前回合无分数变化时弹窗确认',
                      style: GoogleFonts.notoSansSc(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchRow('零和博弈模式', _isZeroSum, (v) {
                    setState(() => _isZeroSum = v);
                  }),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '开启后，只能通过玩家间拖拽转移分数，不能单独加减',
                      style: GoogleFonts.notoSansSc(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Start Game Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '开始游戏',
                        style: GoogleFonts.notoSansSc(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.notoSansSc(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.notoSansSc(color: Colors.white.withValues(alpha: 0.3)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildBackgroundTypeChip(String label, BackgroundType type) {
    final isSelected = _backgroundType == type;
    return ChoiceChip(
      label: Text(label,
          style: GoogleFonts.notoSansSc(
            color: isSelected ? Colors.white : Colors.white70,
          )),
      selected: isSelected,
      selectedColor: const Color(0xFF667EEA),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      onSelected: (_) => setState(() => _backgroundType = type),
    );
  }

  Widget _buildSwitchRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansSc(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 15,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF667EEA),
        ),
      ],
    );
  }

  void _startGame() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final bgConfig = BackgroundConfig(
      type: _backgroundType,
      monetPaletteIndex: _monetPaletteIndex,
      solidColorValue: _solidColor.toARGB32(),
    );

    final provider = Provider.of<GameProvider>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;

    await provider.createGame(
      name: name,
      initialPlayerCount: _playerCount,
      backgroundConfig: bgConfig,
      isScreenAlwaysOn: _isScreenAlwaysOn,
      quickNextRound: _quickNextRound,
      isZeroSum: _isZeroSum,
      initialScore: _initialScore,
      screenSize: screenSize,
    );

    if (mounted) {
      Navigator.pop(context); // Close sheet
      widget.onGameCreated();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    }
  }
}

/// Edit Game Sheet - for editing saved game's name, background, settings
class _EditGameSheet extends StatefulWidget {
  final GameSummary gameSummary;
  final VoidCallback onSaved;

  const _EditGameSheet({
    required this.gameSummary,
    required this.onSaved,
  });

  @override
  State<_EditGameSheet> createState() => _EditGameSheetState();
}

class _EditGameSheetState extends State<_EditGameSheet> {
  late TextEditingController _nameController;
  GameData? _gameData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gameSummary.name);
    _loadGameData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    final data = await GameStorage.loadGame(widget.gameSummary.id);
    if (mounted) {
      setState(() {
        _gameData = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Color(0xFF1A202C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_gameData == null) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Color(0xFF1A202C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: Text('无法加载游戏数据',
              style: GoogleFonts.notoSansSc(color: Colors.white54)),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A202C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '编辑游戏',
            style: GoogleFonts.notoSansSc(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game name
                  Text('游戏名称',
                      style: GoogleFonts.notoSansSc(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.notoSansSc(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '游戏名称',
                      hintStyle: GoogleFonts.notoSansSc(
                          color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF667EEA)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Settings toggles
                  _buildEditSwitch('屏幕常亮', _gameData!.isScreenAlwaysOn, (v) {
                    setState(() => _gameData!.isScreenAlwaysOn = v);
                  }),
                  const SizedBox(height: 12),
                  _buildEditSwitch('快速下一回合', _gameData!.quickNextRound, (v) {
                    setState(() => _gameData!.quickNextRound = v);
                  }),
                  const SizedBox(height: 12),
                  _buildEditSwitch('零和博弈模式', _gameData!.isZeroSum, (v) {
                    setState(() => _gameData!.isZeroSum = v);
                  }),

                  const SizedBox(height: 20),

                  // Background
                  Text('背景',
                      style: GoogleFonts.notoSansSc(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _editBgChip('莫奈桌布', BackgroundType.monet),
                      _editBgChip('纯色桌布', BackgroundType.solidColor),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_gameData!.backgroundConfig.type == BackgroundType.monet)
                    _editMonetSelector(),
                  if (_gameData!.backgroundConfig.type ==
                      BackgroundType.solidColor)
                    _editSolidSelector(),

                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text('保存',
                          style: GoogleFonts.notoSansSc(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSwitch(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansSc(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 15,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF667EEA),
        ),
      ],
    );
  }

  Widget _editBgChip(String label, BackgroundType type) {
    final isSelected = _gameData!.backgroundConfig.type == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _gameData!.backgroundConfig = BackgroundConfig(
            type: type,
            monetPaletteIndex: _gameData!.backgroundConfig.monetPaletteIndex,
            solidColorValue:
                _gameData!.backgroundConfig.solidColorValue ?? 0xFF2D3748,
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF667EEA)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF667EEA)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansSc(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _editMonetSelector() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: MonetPalettes.palettes.length,
        itemBuilder: (context, index) {
          final palette = MonetPalettes.palettes[index];
          final isSelected =
              _gameData!.backgroundConfig.monetPaletteIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _gameData!.backgroundConfig = BackgroundConfig(
                  type: BackgroundType.monet,
                  monetPaletteIndex: index,
                );
              });
            },
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2.5)
                    : Border.all(color: Colors.white.withValues(alpha: 0.15)),
                gradient: RadialGradient(
                  colors: [
                    palette.centerColor,
                    palette.edgeColor,
                  ],
                ),
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

  Widget _editSolidSelector() {
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
              _gameData!.backgroundConfig.solidColorValue == c.toARGB32();
          return GestureDetector(
            onTap: () {
              setState(() {
                _gameData!.backgroundConfig = BackgroundConfig(
                  type: BackgroundType.solidColor,
                  solidColorValue: c.toARGB32(),
                );
              });
            },
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2.5)
                    : Border.all(color: Colors.white.withValues(alpha: 0.15)),
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

  void _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty && _gameData != null) {
      _gameData!.name = name;
      await GameStorage.saveGame(_gameData!);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    }
  }
}
