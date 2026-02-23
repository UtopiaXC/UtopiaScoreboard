import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'github_api.dart';
import '../widgets/update/update_dialog.dart';

class UpdateUtil {
  static const String _ignoredVersionKey = 'ignored_update_version';
  static const String _autoCheckUpdateKey = 'auto_check_update';

  /// Check for updates and show a dialog if a new version is available.
  static Future<void> checkAndShow(
    BuildContext context, {
    bool isManualCheck = false,
    bool checkPreRelease = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // If not manual, respect auto-check setting
    if (!isManualCheck) {
      final autoCheck = prefs.getBool(_autoCheckUpdateKey) ?? true;
      if (!autoCheck) return;
    }

    final String? ignoredVersion = prefs.getString(_ignoredVersionKey);

    if (isManualCheck) {
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
    }

    try {
      final githubApi = GithubApi();
      Map<String, dynamic>? release;

      if (checkPreRelease) {
        release = await githubApi.getLatestPreRelease(context);
      } else {
        release = await githubApi.getLatestRelease(context);
      }

      if (isManualCheck && context.mounted) {
        Navigator.pop(context);
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
        if (!isManualCheck && ignoredVersion == tagName) {
          return;
        }

        showDialog(
          context: context,
          builder: (ctx) => UpdateDialog(releaseData: release!),
        );
      } else {
        if (isManualCheck && context.mounted) {
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
      if (isManualCheck && context.mounted) {
        Navigator.pop(context);
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A202C),
            title:
                Text('检查更新失败', style: GoogleFonts.notoSansSc(color: Colors.white)),
            content: Text(errorMessage,
                style: GoogleFonts.notoSansSc(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('确认',
                    style: GoogleFonts.notoSansSc(
                        color: const Color(0xFF667EEA))),
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

  /// Perform a smart download: match the current platform's asset, or fallback to browser.
  static Future<void> performSmartDownload(
    BuildContext context,
    Map<String, dynamic> releaseData,
  ) async {
    final List<dynamic> assets = releaseData['assets'] ?? [];
    final String htmlUrl = releaseData['html_url'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF667EEA)),
      ),
    );

    String? downloadUrl;

    try {
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          downloadUrl = _matchAndroid(assets);
        } else if (Platform.isWindows) {
          downloadUrl = _matchWindows(assets);
        } else if (Platform.isLinux) {
          downloadUrl = _matchLinux(assets);
        } else if (Platform.isMacOS) {
          downloadUrl = _matchMac(assets);
        } else if (Platform.isIOS) {
          downloadUrl = _matchIos(assets);
        }
      }
    } catch (e) {
      debugPrint('Smart download match failed: $e');
    }

    if (context.mounted) {
      Navigator.pop(context);
    }

    final String target = downloadUrl ?? htmlUrl;
    _launchBrowser(target, context);
  }

  static String? _matchAndroid(List<dynamic> assets) {
    final match = assets.cast<Map<String, dynamic>?>().firstWhere(
      (asset) {
        if (asset == null) return false;
        final name = asset['name'].toString().toLowerCase();
        return name.contains('android') && name.endsWith('.apk');
      },
      orElse: () => null,
    );
    return match?['browser_download_url'] as String?;
  }

  static String? _matchWindows(List<dynamic> assets) {
    var match = assets.cast<Map<String, dynamic>?>().firstWhere(
      (asset) {
        if (asset == null) return false;
        final name = asset['name'].toString().toLowerCase();
        return name.contains('windows') &&
            name.contains('setup') &&
            name.endsWith('.exe');
      },
      orElse: () => null,
    );

    match ??= assets.cast<Map<String, dynamic>?>().firstWhere(
      (asset) {
        if (asset == null) return false;
        final name = asset['name'].toString().toLowerCase();
        return name.contains('windows') && name.endsWith('.zip');
      },
      orElse: () => null,
    );

    return match?['browser_download_url'] as String?;
  }

  static String? _matchLinux(List<dynamic> assets) {
    var match = assets.cast<Map<String, dynamic>?>().firstWhere(
      (asset) {
        if (asset == null) return false;
        final name = asset['name'].toString().toLowerCase();
        return name.contains('linux') && name.endsWith('.appimage');
      },
      orElse: () => null,
    );
    match ??= assets.cast<Map<String, dynamic>?>().firstWhere(
      (asset) {
        if (asset == null) return false;
        final name = asset['name'].toString().toLowerCase();
        return name.contains('linux') && name.endsWith('.deb');
      },
      orElse: () => null,
    );
    return match?['browser_download_url'] as String?;
  }

  static String? _matchMac(List<dynamic> assets) {
    final match = assets.cast<Map<String, dynamic>?>().firstWhere(
      (asset) {
        if (asset == null) return false;
        final name = asset['name'].toString().toLowerCase();
        return name.contains('macos') && name.endsWith('.dmg');
      },
      orElse: () => null,
    );
    return match?['browser_download_url'] as String?;
  }

  static String? _matchIos(List<dynamic> assets) {
    final match = assets.cast<Map<String, dynamic>?>().firstWhere(
      (asset) {
        if (asset == null) return false;
        final name = asset['name'].toString().toLowerCase();
        return name.contains('ios') && name.endsWith('.ipa');
      },
      orElse: () => null,
    );
    return match?['browser_download_url'] as String?;
  }

  static Future<void> _launchBrowser(
      String url, BuildContext context) async {
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

  /// Set the ignored version in SharedPreferences.
  static Future<void> setIgnoredVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ignoredVersionKey, version);
  }

  /// Get/set auto check update setting.
  static Future<bool> getAutoCheckUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoCheckUpdateKey) ?? true;
  }

  static Future<void> setAutoCheckUpdate(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCheckUpdateKey, value);
  }
}
