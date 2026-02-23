import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/update_util.dart';

/// About screen showing app info, developer links, and licenses.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _version = info.version);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Fallback: try platform default
      try {
        await launchUrl(uri);
      } catch (_) {
        // Could not launch
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A202C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('关于',
            style: GoogleFonts.notoSansSc(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          const SizedBox(height: 24),
          // App icon — use the actual launcher icon
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/ic_ios.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Utopia Scoreboard',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Version $_version',
              style: GoogleFonts.notoSansSc(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 36),
          // Info cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  _buildTapItem(
                    '开发者',
                    'UtopiaXC',
                    Icons.person_outline,
                    () => _launchUrl('https://github.com/UtopiaXC'),
                  ),
                  _divider(),
                  _buildTapItem(
                    'GitHub',
                    'UtopiaXC/UtopiaScoreboard',
                    Icons.code,
                    () => _launchUrl(
                        'https://github.com/UtopiaXC/UtopiaScoreboard'),
                  ),
                  _divider(),
                  _buildTapItem(
                    '检查更新',
                    '从 GitHub 检查最新版本',
                    Icons.system_update_outlined,
                    () => UpdateUtil.checkAndShow(context, isManualCheck: true),
                  ),
                  _divider(),
                  _buildTapItem(
                    '开源许可证',
                    null,
                    Icons.description_outlined,
                    () {
                      showLicensePage(
                        context: context,
                        applicationName: 'Utopia Scoreboard',
                        applicationVersion: _version,
                        applicationIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/ic_ios.png',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapItem(
      String title, String? subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.5), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.notoSansSc(
                          color: Colors.white, fontSize: 15)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: GoogleFonts.notoSansSc(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.white.withOpacity(0.3), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      color: Colors.white.withOpacity(0.06),
      height: 1,
      indent: 52,
    );
  }
}

