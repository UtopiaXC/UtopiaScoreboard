import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/update_util.dart';

/// Dialog shown when a new version is available.
class UpdateDialog extends StatelessWidget {
  final Map<String, dynamic> releaseData;

  const UpdateDialog({super.key, required this.releaseData});

  @override
  Widget build(BuildContext context) {
    final tagName = releaseData['tag_name'] as String;
    final body = (releaseData['body'] as String?) ?? '';
    final isPrerelease = releaseData['prerelease'] as bool? ?? false;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A202C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Color(0xFF667EEA), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '发现新版本',
              style: GoogleFonts.notoSansSc(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  tagName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPrerelease
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isPrerelease
                          ? Colors.orange.withOpacity(0.5)
                          : Colors.green.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    isPrerelease ? '测试版' : '正式版',
                    style: GoogleFonts.notoSansSc(
                      color: isPrerelease ? Colors.orange : Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '来源: GitHub',
              style: GoogleFonts.notoSansSc(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    body,
                    style: GoogleFonts.notoSansSc(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              Text('取消', style: GoogleFonts.notoSansSc(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () => _showIgnoreDialog(context, tagName),
          child: Text('忽略此版本',
              style: GoogleFonts.notoSansSc(color: Colors.white54)),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            UpdateUtil.performSmartDownload(context, releaseData);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF667EEA),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child:
              Text('下载更新', style: GoogleFonts.notoSansSc(color: Colors.white)),
        ),
      ],
    );
  }

  void _showIgnoreDialog(BuildContext context, String version) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A202C),
        title: Text('忽略此版本',
            style: GoogleFonts.notoSansSc(color: Colors.white)),
        content: Text('确定要忽略版本 $version 吗？下次检查更新时将不再提示此版本。',
            style: GoogleFonts.notoSansSc(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('取消',
                style: GoogleFonts.notoSansSc(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              UpdateUtil.setIgnoredVersion(version);
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text('确认',
                style: GoogleFonts.notoSansSc(
                    color: const Color(0xFF667EEA))),
          ),
        ],
      ),
    );
  }
}
