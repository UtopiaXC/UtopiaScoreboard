import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/download_helper.dart';
import '../utils/update_util.dart';
import 'score_steps_editor.dart';
import 'about_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A202C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('设置',
            style: GoogleFonts.notoSansSc(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Score Steps
          _buildCard(
            icon: Icons.tune,
            title: '分数控制',
            subtitle: '自定义每次加减分的数量',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ScoreStepsEditor()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Export
          _buildCard(
            icon: Icons.upload_file,
            title: '导出数据',
            subtitle: '导出所有设置和游戏数据到文件',
            onTap: _exportData,
          ),
          const SizedBox(height: 12),

          // Import
          _buildCard(
            icon: Icons.download,
            title: '导入数据',
            subtitle: '从文件恢复设置和游戏数据',
            onTap: _importData,
          ),
          const SizedBox(height: 12),

          // Check for updates
          _buildCard(
            icon: Icons.system_update_outlined,
            title: '检查更新',
            subtitle: '从 GitHub 检查最新版本',
            onTap: () => UpdateUtil.checkAndShow(context, isManualCheck: true),
          ),
          const SizedBox(height: 12),

          // About
          _buildCard(
            icon: Icons.info_outline,
            title: '关于',
            subtitle: '开发者信息、版本号、开源许可',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: const Color(0xFF667EEA), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSansSc(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.notoSansSc(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.white.withOpacity(0.3),
                  size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final exportData = <String, dynamic>{};
      for (final key in allKeys) {
        exportData[key] = prefs.get(key);
      }
      final jsonStr = const JsonEncoder.withIndent('  ')
          .convert(exportData);

      // Save to file
      final now = DateTime.now();
      final fileName =
          'scoreboard_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';

      if (kIsWeb) {
        // Web: trigger browser download
        downloadFile(fileName, Uint8List.fromList(utf8.encode(jsonStr)));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已触发下载: $fileName',
                  style: GoogleFonts.notoSansSc(color: Colors.white)),
              backgroundColor: const Color(0xFF2D3748),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (_isDesktop) {
        final savedPath = await FilePicker.platform.saveFile(
          dialogTitle: '保存备份文件',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (savedPath == null) return;
        await File(savedPath).writeAsString(jsonStr);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已导出到: $savedPath',
                  style: GoogleFonts.notoSansSc(color: Colors.white)),
              backgroundColor: const Color(0xFF2D3748),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (_isMobile) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        await File(filePath).writeAsString(jsonStr);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            text: '游戏数据备份',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e',
                style: GoogleFonts.notoSansSc(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      final jsonStr = await file.readAsString();
      final importData =
          jsonDecode(jsonStr) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      for (final entry in importData.entries) {
        final value = entry.value;
        if (value is String) {
          await prefs.setString(entry.key, value);
        } else if (value is int) {
          await prefs.setInt(entry.key, value);
        } else if (value is double) {
          await prefs.setDouble(entry.key, value);
        } else if (value is bool) {
          await prefs.setBool(entry.key, value);
        } else if (value is List) {
          await prefs.setStringList(
              entry.key, value.cast<String>());
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入成功，请重启应用以应用更改',
                style: GoogleFonts.notoSansSc(color: Colors.white)),
            backgroundColor: Colors.greenAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e',
                style: GoogleFonts.notoSansSc(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
