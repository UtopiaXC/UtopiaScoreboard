import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Simple GitHub Release API client for checking updates.
class GithubApi {
  static const String _baseUrl =
      'https://api.github.com/repos/UtopiaXC/UtopiaScoreboard/releases';

  /// Get the latest stable release.
  Future<Map<String, dynamic>?> getLatestRelease(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('未找到发布版本');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('无法连接到 GitHub: $e');
    }
    return null;
  }

  /// Get the latest release (including pre-releases).
  Future<Map<String, dynamic>?> getLatestPreRelease(
      BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> releases =
            jsonDecode(response.body) as List<dynamic>;
        if (releases.isNotEmpty) {
          return releases.first as Map<String, dynamic>;
        } else {
          throw Exception('未找到发布版本');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('无法连接到 GitHub: $e');
    }
    return null;
  }
}
