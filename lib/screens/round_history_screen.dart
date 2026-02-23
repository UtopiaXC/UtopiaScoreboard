import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import '../providers/game_provider.dart';
import '../models/round_record.dart';

class RoundHistoryScreen extends StatefulWidget {
  const RoundHistoryScreen({super.key});

  @override
  State<RoundHistoryScreen> createState() => _RoundHistoryScreenState();
}

class _RoundHistoryScreenState extends State<RoundHistoryScreen> {
  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.macOS ||
       defaultTargetPlatform == TargetPlatform.linux);

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
       defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final history = game.roundHistory;
    final players = game.players;

    final allPlayerIds = <String>{};
    for (var record in history) {
      allPlayerIds.addAll(record.playerData.keys);
    }
    for (var p in players) {
      allPlayerIds.add(p.id);
    }

    final playerNames = <String, String>{};
    for (var p in players) {
      playerNames[p.id] = p.name;
    }
    for (var record in history) {
      for (var entry in record.playerData.entries) {
        playerNames.putIfAbsent(entry.key, () => entry.value.playerName);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A202C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '游戏记录',
          style: GoogleFonts.notoSansSc(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: '导出',
              onPressed: () => _showExportOptions(
                  context, game, history, allPlayerIds.toList(), playerNames),
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history,
                      size: 64, color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 16),
                  Text(
                    '暂无回合记录',
                    style: GoogleFonts.notoSansSc(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '完成一个回合后，记录将显示在这里',
                    style: GoogleFonts.notoSansSc(
                      color: Colors.white.withOpacity(0.25),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummarySection(game),
                  const SizedBox(height: 24),
                  Text(
                    '回合详情',
                    style: GoogleFonts.notoSansSc(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildHistoryTable(
                        history, allPlayerIds.toList(), playerNames),
                  ),
                  const SizedBox(height: 24),
                  ...history.reversed
                      .map((record) => _buildRoundCard(record, playerNames)),
                ],
              ),
            ),
    );
  }

  // ─── Export Options ───

  void _showExportOptions(
    BuildContext context,
    GameProvider game,
    List<RoundRecord> history,
    List<String> playerIds,
    Map<String, String> playerNames,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A202C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('导出游戏记录',
                style: GoogleFonts.notoSansSc(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            _exportOption(
              icon: Icons.table_chart_outlined,
              title: '导出为表格 (CSV)',
              subtitle: _isMobile ? '通过分享发送 CSV 文件' : '可用 Excel 打开',
              onTap: () {
                Navigator.pop(ctx);
                _exportCsv(game, history, playerIds, playerNames);
              },
            ),
            const SizedBox(height: 10),
            _exportOption(
              icon: Icons.image_outlined,
              title: '导出为图片',
              subtitle: _isMobile ? '生成并分享精美数据图片' : '生成精美的游戏数据图片',
              onTap: () {
                Navigator.pop(ctx);
                _exportImage(game, history, playerIds, playerNames);
              },
            ),
            if (_isMobile) ...[
              const SizedBox(height: 10),
              _exportOption(
                icon: Icons.photo_library_outlined,
                title: '导出图片到相册',
                subtitle: '保存到系统相册',
                onTap: () {
                  Navigator.pop(ctx);
                  _exportImageToGallery(game, history, playerIds, playerNames);
                },
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _exportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF667EEA), size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.notoSansSc(color: Colors.white, fontSize: 15)),
                  Text(subtitle,
                      style: GoogleFonts.notoSansSc(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  // ─── CSV Export ───

  Future<void> _exportCsv(
    GameProvider game,
    List<RoundRecord> history,
    List<String> playerIds,
    Map<String, String> playerNames,
  ) async {
    try {
      final buf = StringBuffer();
      buf.write('回合');
      for (final id in playerIds) {
        final name = playerNames[id] ?? '未知';
        buf.write(',$name(变化),$name(总分)');
      }
      buf.writeln();

      for (final record in history) {
        buf.write('${record.roundNumber}');
        for (final id in playerIds) {
          final pd = record.playerData[id];
          if (pd != null) {
            buf.write(',${pd.scoreChange},${pd.totalScoreAfter}');
          } else {
            buf.write(',,');
          }
        }
        // Add player change info
        if (record.playerChanges.isNotEmpty) {
          final changes = record.playerChanges.map((e) {
            return e.type == PlayerChangeType.added
                ? '加入:${e.playerName}'
                : '离开:${e.playerName}';
          }).join('; ');
          buf.write(',$changes');
        }
        buf.writeln();
      }

      buf.write('当前');
      for (final id in playerIds) {
        final player = game.players.where((p) => p.id == id).firstOrNull;
        if (player != null) {
          buf.write(',${player.currentRoundChange},${player.totalScore}');
        } else {
          buf.write(',,');
        }
      }
      buf.writeln();

      final csvContent = buf.toString();
      final now = DateTime.now();
      final fileName =
          'scoreboard_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';

      if (_isDesktop) {
        final savedPath = await FilePicker.platform.saveFile(
          dialogTitle: '保存CSV文件',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );
        if (savedPath == null) return;
        await File(savedPath).writeAsString(csvContent);
        _showSuccess('已导出: $savedPath');
      } else if (_isMobile) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        await File(filePath).writeAsString(csvContent);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            text: '游戏记录 - ${game.gameName}',
          ),
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final savedPath = '${dir.path}/$fileName';
        await File(savedPath).writeAsString(csvContent);
        _showSuccess('已导出: $savedPath');
      }
    } catch (e) {
      _showError('导出失败: $e');
    }
  }

  // ─── Image Export (Custom Rendered) ───

  Future<Uint8List?> _generateExportImage(
    GameProvider game,
    List<RoundRecord> history,
    List<String> playerIds,
    Map<String, String> playerNames,
  ) async {
    const double imageWidth = 800;

    final widget = _ExportImageWidget(
      gameName: game.gameName,
      currentRound: game.currentRound,
      players: game.players,
      history: history,
      playerIds: playerIds,
      playerNames: playerNames,
    );

    final repaintBoundary = RenderRepaintBoundary();
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.topLeft,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: const BoxConstraints(
          minWidth: imageWidth,
          maxWidth: imageWidth,
          minHeight: 0,
          maxHeight: double.infinity,
        ),
        devicePixelRatio: 1.0,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final element = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: Colors.transparent,
            child: widget,
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(element);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    buildOwner.finalizeTree();

    return byteData?.buffer.asUint8List();
  }

  Future<void> _exportImage(
    GameProvider game,
    List<RoundRecord> history,
    List<String> playerIds,
    Map<String, String> playerNames,
  ) async {
    try {
      _showLoading();
      final bytes = await _generateExportImage(game, history, playerIds, playerNames);
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      if (bytes == null) {
        _showError('生成图片失败');
        return;
      }

      final now = DateTime.now();
      final fileName =
          'scoreboard_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.png';

      if (_isDesktop) {
        final savedPath = await FilePicker.platform.saveFile(
          dialogTitle: '保存PNG图片',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['png'],
        );
        if (savedPath == null) return;
        await File(savedPath).writeAsBytes(bytes);
        _showSuccess('已导出: $savedPath');
      } else if (_isMobile) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        await File(filePath).writeAsBytes(bytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath, mimeType: 'image/png')],
            text: '游戏记录 - ${game.gameName}',
          ),
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final savedPath = '${dir.path}/$fileName';
        await File(savedPath).writeAsBytes(bytes);
        _showSuccess('已导出: $savedPath');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route is! DialogRoute);
      }
      _showError('导出失败: $e');
    }
  }

  Future<void> _exportImageToGallery(
    GameProvider game,
    List<RoundRecord> history,
    List<String> playerIds,
    Map<String, String> playerNames,
  ) async {
    try {
      _showLoading();
      final bytes = await _generateExportImage(game, history, playerIds, playerNames);
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      if (bytes == null) {
        _showError('生成图片失败');
        return;
      }

      final now = DateTime.now();
      final fileName =
          'scoreboard_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.png';

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      await File(filePath).writeAsBytes(bytes);

      await Gal.putImage(filePath);
      _showSuccess('已保存到相册');
    } catch (e) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route is! DialogRoute);
      }
      _showError('保存到相册失败: $e');
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          color: Color(0xFF1A202C),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF667EEA)),
                SizedBox(height: 16),
                Text('正在生成图片...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.notoSansSc(color: Colors.white)),
        backgroundColor: const Color(0xFF2D3748),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.notoSansSc(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── UI Widgets ───

  Widget _buildSummarySection(GameProvider game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '当前状态',
          style: GoogleFonts.notoSansSc(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('当前回合', '${game.currentRound}',
                Icons.flag_outlined, const Color(0xFF667EEA)),
            const SizedBox(width: 12),
            _buildStatCard('玩家数', '${game.players.length}',
                Icons.people_outline, const Color(0xFF48BB78)),
            const SizedBox(width: 12),
            _buildStatCard('历史回合', '${game.roundHistory.length}',
                Icons.history, const Color(0xFFED8936)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.notoSansSc(
                color: Colors.white.withOpacity(0.5), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTable(List<RoundRecord> history,
      List<String> playerIds, Map<String, String> playerNames) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.05)),
      dataRowColor: WidgetStateProperty.all(Colors.transparent),
      border: TableBorder.all(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      columns: [
        DataColumn(
          label: Text('回合', style: GoogleFonts.notoSansSc(
              color: Colors.white70, fontWeight: FontWeight.w600)),
        ),
        ...playerIds.map((id) => DataColumn(
              label: Text(playerNames[id] ?? '未知',
                  style: GoogleFonts.notoSansSc(
                      color: Colors.white70, fontWeight: FontWeight.w600)),
            )),
      ],
      rows: history.map((record) {
        return DataRow(cells: [
          DataCell(Text('${record.roundNumber}',
              style: GoogleFonts.outfit(color: Colors.white70))),
          ...playerIds.map((id) {
            final pd = record.playerData[id];
            if (pd == null) {
              return DataCell(Text('-', style: GoogleFonts.outfit(color: Colors.white30)));
            }
            final change = pd.scoreChange;
            final changeStr = change > 0 ? '+$change' : (change < 0 ? '$change' : '0');
            final changeColor = change > 0
                ? Colors.greenAccent
                : (change < 0 ? Colors.redAccent : Colors.white30);
            return DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${pd.totalScoreAfter}',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                  Text(changeStr,
                      style: GoogleFonts.outfit(color: changeColor, fontSize: 11)),
                ],
              ),
            );
          }),
        ]);
      }).toList(),
    );
  }

  Widget _buildRoundCard(RoundRecord record, Map<String, String> playerNames) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '第 ${record.roundNumber} 回合',
                  style: GoogleFonts.notoSansSc(
                    color: const Color(0xFF667EEA), fontSize: 13, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(record.timestamp),
                style: GoogleFonts.notoSansSc(
                    color: Colors.white.withOpacity(0.3), fontSize: 12),
              ),
            ],
          ),
          // Player changes section
          if (record.playerChanges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.tealAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.tealAccent.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_alt_outlined,
                          color: Colors.tealAccent.withOpacity(0.7), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '玩家变更',
                        style: GoogleFonts.notoSansSc(
                          color: Colors.tealAccent.withOpacity(0.8),
                          fontSize: 12, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...record.playerChanges.map((event) {
                    final isAdded = event.type == PlayerChangeType.added;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAdded ? Icons.person_add : Icons.person_remove,
                            color: isAdded
                                ? Colors.greenAccent.withOpacity(0.7)
                                : Colors.redAccent.withOpacity(0.7),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${isAdded ? "加入" : "离开"}: ${event.playerName}',
                            style: GoogleFonts.notoSansSc(
                              color: Colors.white.withOpacity(0.6), fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12, runSpacing: 8,
            children: record.playerData.entries.map((entry) {
              final name = playerNames[entry.key] ?? entry.value.playerName;
              final change = entry.value.scoreChange;
              final changeStr = change > 0 ? '+$change' : (change < 0 ? '$change' : '±0');
              final changeColor = change > 0
                  ? Colors.greenAccent
                  : (change < 0 ? Colors.redAccent : Colors.white38);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: GoogleFonts.notoSansSc(color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(changeStr, style: GoogleFonts.outfit(
                        color: changeColor, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Text('→ ${entry.value.totalScoreAfter}',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
          if (record.transfers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.swap_horiz,
                          color: Colors.blueAccent.withOpacity(0.7), size: 16),
                      const SizedBox(width: 6),
                      Text('分数转移', style: GoogleFonts.notoSansSc(
                          color: Colors.blueAccent.withOpacity(0.8),
                          fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...record.transfers.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${t.fromPlayerName} → ${t.toPlayerName}: ${t.amount}',
                          style: GoogleFonts.notoSansSc(
                              color: Colors.white.withOpacity(0.6), fontSize: 12),
                        ),
                      )),
                ],
              ),
            ),
          ],
          if (record.edits.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit,
                          color: Colors.orangeAccent.withOpacity(0.7), size: 16),
                      const SizedBox(width: 6),
                      Text('手动编辑', style: GoogleFonts.notoSansSc(
                          color: Colors.orangeAccent.withOpacity(0.8),
                          fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...record.edits.map((e) {
                    final diff = e.difference;
                    final diffStr = diff > 0 ? '+$diff' : '$diff';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${e.playerName}: ${e.scoreBefore} → ${e.scoreAfter} ($diffStr)',
                        style: GoogleFonts.notoSansSc(
                            color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Custom Export Image Widget ───

class _ExportImageWidget extends StatelessWidget {
  final String gameName;
  final int currentRound;
  final List players;
  final List<RoundRecord> history;
  final List<String> playerIds;
  final Map<String, String> playerNames;

  const _ExportImageWidget({
    required this.gameName,
    required this.currentRound,
    required this.players,
    required this.history,
    required this.playerIds,
    required this.playerNames,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A202C), Color(0xFF0F1419)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildPlayerSummary(),
          const SizedBox(height: 24),
          _buildScoreTable(),
          const SizedBox(height: 24),
          ...history.map((r) => _buildRoundDetail(r)),
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gameName.isNotEmpty ? gameName : 'Utopia Scoreboard',
            style: const TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _headerChip('第 $currentRound 回合', Icons.flag_outlined),
              const SizedBox(width: 12),
              _headerChip('${players.length} 位玩家', Icons.people_outline),
              const SizedBox(width: 12),
              _headerChip('${history.length} 回合记录', Icons.history),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 14),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(
              color: Colors.white.withOpacity(0.9), fontSize: 12,
              decoration: TextDecoration.none)),
        ],
      ),
    );
  }

  Widget _buildPlayerSummary() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: playerIds.map((id) {
        final name = playerNames[id] ?? '未知';
        int latestScore = 0;
        for (final p in players) {
          if ((p as dynamic).id == id) {
            latestScore = (p as dynamic).totalScore as int;
            break;
          }
        }
        if (latestScore == 0 && history.isNotEmpty) {
          for (final record in history.reversed) {
            if (record.playerData.containsKey(id)) {
              latestScore = record.playerData[id]!.totalScoreAfter;
              break;
            }
          }
        }

        return Container(
          width: 170,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none)),
              const SizedBox(height: 6),
              Text('$latestScore', style: const TextStyle(
                  color: Color(0xFF667EEA), fontSize: 28, fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none)),
              const SizedBox(height: 2),
              Text('当前积分', style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 11,
                  decoration: TextDecoration.none)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoreTable() {
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('得分明细', style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 16,
                fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text('回合', style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 12,
                      fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
                ),
                ...playerIds.map((id) => Expanded(
                  child: Text(playerNames[id] ?? '?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12,
                          fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
                )),
              ],
            ),
          ),
          ...history.map((record) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.04))),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text('${record.roundNumber}', style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12,
                        decoration: TextDecoration.none)),
                  ),
                  ...playerIds.map((id) {
                    final pd = record.playerData[id];
                    if (pd == null) {
                      return Expanded(
                        child: Text('-', textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.2),
                                fontSize: 12, decoration: TextDecoration.none)),
                      );
                    }
                    final change = pd.scoreChange;
                    final changeStr = change > 0 ? '+$change' : '$change';
                    final changeColor = change > 0
                        ? Colors.greenAccent
                        : (change < 0 ? Colors.redAccent : Colors.white38);
                    return Expanded(
                      child: Column(
                        children: [
                          Text('${pd.totalScoreAfter}', textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 13, fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none)),
                          Text(changeStr, textAlign: TextAlign.center,
                              style: TextStyle(color: changeColor, fontSize: 10,
                                  decoration: TextDecoration.none)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRoundDetail(RoundRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('第 ${record.roundNumber} 回合',
                    style: const TextStyle(
                        color: Color(0xFF667EEA), fontSize: 11,
                        fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
              ),
              const Spacer(),
              Text(
                '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.white.withOpacity(0.3),
                    fontSize: 10, decoration: TextDecoration.none),
              ),
            ],
          ),
          // Player changes
          if (record.playerChanges.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...record.playerChanges.map((event) {
              final isAdded = event.type == PlayerChangeType.added;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAdded ? Icons.person_add : Icons.person_remove,
                      color: isAdded ? Colors.greenAccent.withOpacity(0.6) : Colors.redAccent.withOpacity(0.6),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text('${isAdded ? "加入" : "离开"}: ${event.playerName}',
                        style: TextStyle(color: Colors.white.withOpacity(0.5),
                            fontSize: 10, decoration: TextDecoration.none)),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 4,
            children: record.playerData.entries.map((entry) {
              final name = playerNames[entry.key] ?? entry.value.playerName;
              final change = entry.value.scoreChange;
              final changeStr = change > 0 ? '+$change' : (change < 0 ? '$change' : '±0');
              final changeColor = change > 0
                  ? Colors.greenAccent
                  : (change < 0 ? Colors.redAccent : Colors.white38);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: TextStyle(color: Colors.white.withOpacity(0.6),
                        fontSize: 11, decoration: TextDecoration.none)),
                    const SizedBox(width: 6),
                    Text(changeStr, style: TextStyle(color: changeColor,
                        fontSize: 12, fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none)),
                    const SizedBox(width: 4),
                    Text('→ ${entry.value.totalScoreAfter}',
                        style: TextStyle(color: Colors.white.withOpacity(0.3),
                            fontSize: 10, decoration: TextDecoration.none)),
                  ],
                ),
              );
            }).toList(),
          ),
          if (record.transfers.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...record.transfers.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '⇌ ${t.fromPlayerName} → ${t.toPlayerName}: ${t.amount}',
                    style: TextStyle(color: Colors.blueAccent.withOpacity(0.6),
                        fontSize: 10, decoration: TextDecoration.none),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Utopia Scoreboard · ${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} 导出',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 11,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
