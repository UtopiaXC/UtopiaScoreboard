import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'github_api.dart';

class UpdateUtil {
  /// Check for updates and show a dialog if a new version is available.
  static Future<void> checkAndShow(
    BuildContext context, {
    bool checkPreRelease = false,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          color: const Color(0xFF1A202C),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF667EEA)),
                const SizedBox(height: 16),
                Text('正在检查更新...',
                    style: GoogleFonts.notoSansSc(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final githubApi = GithubApi();
      Map<String, dynamic>? release;

      if (checkPreRelease) {
        release = await githubApi.getLatestPreRelease(context);
      } else {
        release = await githubApi.getLatestRelease(context);
      }

      if (context.mounted) {
        Navigator.pop(context); // close loading dialog
      }

      if (release == null) return;
      if (!context.mounted) return;

      final tagName = release['tag_name'] as String;
      final packageInfo = await PackageInfo.fromPlatform();
      final cleanRemote = _extractCoreVersion(tagName);
      final cleanLocal = _extractCoreVersion(packageInfo.version);
      
      if (cleanRemote == null || cleanLocal == null) {
        return;
      }

      if (_isNewerVersion(cleanRemote, cleanLocal)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('发现新版本 $tagName，即将前往下载',
                  style: GoogleFonts.notoSansSc(color: Colors.white)),
              backgroundColor: const Color(0xFF667EEA),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        final htmlUrl = release['html_url'] as String?;
        if (htmlUrl != null && context.mounted) {
          launchBrowser(htmlUrl, context);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('当前已是最新版本',
                  style: GoogleFonts.notoSansSc(color: Colors.white)),
              backgroundColor: const Color(0xFF2D3748),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loading dialog if still open
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A202C),
            title: Text('检查更新失败',
                style: GoogleFonts.notoSansSc(color: Colors.white)),
            content: Text(errorMessage,
                style: GoogleFonts.notoSansSc(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('确认',
                    style:
                        GoogleFonts.notoSansSc(color: const Color(0xFF667EEA))),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Extract the core version string like "1.2.3" from a tag like "v1.2.3-beta".
  static String? _extractCoreVersion(String input) {
    final regExp = RegExp(r'(\d+)\.(\d+)\.(\d+)');
    final match = regExp.firstMatch(input);
    if (match != null) {
      return match.group(0);
    }
    return null;
  }

  /// Compare version strings like "1.2.3" > "1.2.2"
  static bool _isNewerVersion(String remote, String local) {
    final rParts = remote.split('.').map(int.parse).toList();
    final lParts = local.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      if (rParts[i] > lParts[i]) return true;
      if (rParts[i] < lParts[i]) return false;
    }
    return false;
  }

  static Future<void> launchBrowser(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw '无法打开 $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开链接失败: $e',
                style: GoogleFonts.notoSansSc(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
