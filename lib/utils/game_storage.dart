import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_data.dart';

/// Cross-platform game persistence using SharedPreferences
/// Works on mobile, desktop, and web
class GameStorage {
  static const String _gamesListKey = 'games_list';
  static const String _gameDataPrefix = 'game_data_';

  /// Get the list of all saved game IDs and names
  static Future<List<GameSummary>> getGamesList() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = prefs.getString(_gamesListKey);
    if (listJson == null) return [];

    final list = jsonDecode(listJson) as List<dynamic>;
    return list.map((e) => GameSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Save game data
  static Future<void> saveGame(GameData gameData) async {
    final prefs = await SharedPreferences.getInstance();

    // Update the game data
    gameData.updatedAt = DateTime.now();
    final gameJson = jsonEncode(gameData.toJson());
    await prefs.setString('$_gameDataPrefix${gameData.id}', gameJson);

    // Update the games list
    final games = await getGamesList();
    final existingIndex = games.indexWhere((g) => g.id == gameData.id);
    final summary = GameSummary(
      id: gameData.id,
      name: gameData.name,
      playerCount: gameData.players.length,
      currentRound: gameData.currentRound,
      createdAt: gameData.createdAt,
      updatedAt: gameData.updatedAt,
    );

    if (existingIndex != -1) {
      games[existingIndex] = summary;
    } else {
      games.add(summary);
    }

    final listJson = jsonEncode(games.map((g) => g.toJson()).toList());
    await prefs.setString(_gamesListKey, listJson);
  }

  /// Load a specific game by ID
  static Future<GameData?> loadGame(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final gameJson = prefs.getString('$_gameDataPrefix$gameId');
    if (gameJson == null) return null;

    return GameData.fromJson(jsonDecode(gameJson) as Map<String, dynamic>);
  }

  /// Delete a game
  static Future<void> deleteGame(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_gameDataPrefix$gameId');

    final games = await getGamesList();
    games.removeWhere((g) => g.id == gameId);
    final listJson = jsonEncode(games.map((g) => g.toJson()).toList());
    await prefs.setString(_gamesListKey, listJson);
  }
}

/// Summary of a game for listing purposes
class GameSummary {
  final String id;
  final String name;
  final int playerCount;
  final int currentRound;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameSummary({
    required this.id,
    required this.name,
    required this.playerCount,
    required this.currentRound,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'playerCount': playerCount,
      'currentRound': currentRound,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GameSummary.fromJson(Map<String, dynamic> json) {
    return GameSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      playerCount: json['playerCount'] as int? ?? 0,
      currentRound: json['currentRound'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
