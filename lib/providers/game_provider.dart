import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/game_data.dart';
import '../models/round_record.dart';
import '../utils/game_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:wakelock_plus/wakelock_plus.dart';

class GameProvider extends ChangeNotifier {
  GameData? _gameData;
  String? _selectedPlayerId;
  bool _isNegative = false;
  bool _transferTriggered = false;

  List<ScoreTransfer> _currentRoundTransfers = [];
  List<ScoreEdit> _currentRoundEdits = [];
  List<PlayerChangeEvent> _currentRoundPlayerChanges = [];

  GameData? get gameData => _gameData;
  List<Player> get players => _gameData?.players ?? [];
  String? get selectedPlayerId => _selectedPlayerId;
  bool get isNegative => _isNegative;
  List<int> get scoreSteps =>
      _gameData?.scoreSteps ?? [1, 2, 4, 8, 16, 32, 64, 128];
  bool get isScreenAlwaysOn => _gameData?.isScreenAlwaysOn ?? true;
  bool get quickNextRound => _gameData?.quickNextRound ?? false;
  bool get isZeroSum => _gameData?.isZeroSum ?? false;
  int get currentRound => _gameData?.currentRound ?? 1;
  List<RoundRecord> get roundHistory => _gameData?.roundHistory ?? [];
  BackgroundConfig get backgroundConfig =>
      _gameData?.backgroundConfig ?? BackgroundConfig();
  String get gameName => _gameData?.name ?? '';
  bool get transferTriggered => _transferTriggered;
  void clearTransferFlag() => _transferTriggered = false;
  void setTransferTriggered() => _transferTriggered = true;

  Player? get selectedPlayer {
    if (_selectedPlayerId == null) return null;
    try {
      return players.firstWhere((p) => p.id == _selectedPlayerId);
    } catch (e) {
      return null;
    }
  }

  void applyWakelock() {
    if (_gameData != null && _gameData!.isScreenAlwaysOn) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void disableWakelock() {
    WakelockPlus.disable();
  }

  Future<void> createGame({
    required String name,
    required int initialPlayerCount,
    required BackgroundConfig backgroundConfig,
    required bool isScreenAlwaysOn,
    required bool quickNextRound,
    bool isZeroSum = false,
    int initialScore = 0,
    Size? screenSize,
  }) async {
    final id = const Uuid().v4();
    _gameData = GameData(
      id: id,
      name: name,
      backgroundConfig: backgroundConfig,
      isScreenAlwaysOn: isScreenAlwaysOn,
      quickNextRound: quickNextRound,
      isZeroSum: isZeroSum,
    );

    _spreadPlayersEvenly(initialPlayerCount, screenSize, initialScore: initialScore);

    _currentRoundTransfers = [];
    _currentRoundEdits = [];
    _currentRoundPlayerChanges = [];
    await _saveGame();
    notifyListeners();
  }

  /// Generate spread layout positions for a given screen size
  List<Offset> _generateSpreadPositions(int count, Size screenSize) {
    const double cardWidth = 240.0;
    const double cardHeight = 100.0;
    const double margin = 20.0;
    const double topMargin = 50.0;
    const double bottomMargin = 80.0;

    final double areaW = screenSize.width - margin * 2;
    final double areaH = screenSize.height - topMargin - bottomMargin;

    final positions = <Offset>[];

    if (count <= 0) return positions;

    if (count == 1) {
      positions.add(Offset(
        margin + (areaW - cardWidth) / 2,
        topMargin + (areaH - cardHeight) / 2,
      ));
      return positions;
    }

    int cols = 1;
    int rows = 1;
    for (int c = 1; c <= count; c++) {
      int r = (count / c).ceil();
      double cellW = areaW / c;
      double cellH = areaH / r;
      if (cellW >= cardWidth + 10 && cellH >= cardHeight + 10) {
        cols = c;
        rows = r;
      }
    }

    final double cellW = areaW / cols;
    final double cellH = areaH / rows;

    for (int i = 0; i < count; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      double x = margin + col * cellW + (cellW - cardWidth) / 2;
      double y = topMargin + row * cellH + (cellH - cardHeight) / 2;
      x = x.clamp(margin, margin + areaW - cardWidth);
      y = y.clamp(topMargin, topMargin + areaH - cardHeight);
      positions.add(Offset(x, y));
    }
    return positions;
  }

  void _spreadPlayersEvenly(int count, Size? screenSize, {int initialScore = 0}) {
    if (count <= 0) return;
    final size = screenSize ?? const Size(800, 600);
    final positions = _generateSpreadPositions(count, size);

    for (int i = 0; i < count; i++) {
      final pos = i < positions.length ? positions[i] : Offset(50.0 + i * 20, 50.0 + i * 20);
      _addPlayerInternal('玩家 ${i + 1}', initialScore, position: pos);
    }
  }

  Future<bool> loadGame(String gameId) async {
    final data = await GameStorage.loadGame(gameId);
    if (data == null) return false;
    _gameData = data;
    _selectedPlayerId = null;
    _isNegative = false;
    _currentRoundTransfers = [];
    _currentRoundEdits = [];
    _currentRoundPlayerChanges = [];
    notifyListeners();
    return true;
  }

  void _addPlayerInternal(String name, int initialScore,
      {Offset? position}) {
    if (_gameData == null) return;
    final id = const Uuid().v4();
    final random = Random();
    final hue = random.nextDouble() * 360;
    final saturation = 0.6 + random.nextDouble() * 0.4;
    final value = 0.7 + random.nextDouble() * 0.3;
    final color = HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();

    _gameData!.players.add(Player(
      id: id,
      name: name,
      score: initialScore,
      initialScore: initialScore,
      position: position ??
          Offset(100.0 * (_gameData!.players.length + 1), 100.0),
      landscapePosition: position ??
          Offset(100.0 * (_gameData!.players.length + 1), 100.0),
      color: color,
    ));
  }

  void addPlayer(String name, int initialScore, {Offset? position}) {
    _addPlayerInternal(name, initialScore, position: position);
    // Track the event
    final addedPlayer = _gameData!.players.last;
    _currentRoundPlayerChanges.add(PlayerChangeEvent(
      type: PlayerChangeType.added,
      playerId: addedPlayer.id,
      playerName: addedPlayer.name,
    ));
    _saveGame();
    notifyListeners();
  }

  void removePlayer(String id) {
    if (_gameData == null) return;
    final player = _gameData!.players.where((p) => p.id == id).firstOrNull;
    if (player != null) {
      _currentRoundPlayerChanges.add(PlayerChangeEvent(
        type: PlayerChangeType.removed,
        playerId: player.id,
        playerName: player.name,
      ));
    }
    _gameData!.players.removeWhere((p) => p.id == id);
    if (_selectedPlayerId == id) {
      _selectedPlayerId = null;
    }
    _saveGame();
    notifyListeners();
  }

  void selectPlayer(String? id) {
    _selectedPlayerId = id;
    notifyListeners();
  }

  void updatePlayerPosition(
      String id, Offset newPosition, Orientation orientation) {
    if (_gameData == null) return;
    final index = _gameData!.players.indexWhere((p) => p.id == id);
    if (index != -1) {
      if (orientation == Orientation.portrait) {
        _gameData!.players[index].position = newPosition;
      } else {
        _gameData!.players[index].landscapePosition = newPosition;
      }
      _saveGame();
      notifyListeners();
    }
  }

  void updatePlayerScale(String id, double newScale) {
    if (_gameData == null) return;
    final index = _gameData!.players.indexWhere((p) => p.id == id);
    if (index != -1) {
      _gameData!.players[index].scale = newScale.clamp(0.5, 2.0);
      notifyListeners();
    }
  }

  void updatePlayerScore(String id, int change) {
    if (_gameData == null) return;
    final index = _gameData!.players.indexWhere((p) => p.id == id);
    if (index != -1) {
      _gameData!.players[index].currentRoundChange += change;
      notifyListeners();
    }
  }

  void updatePlayerName(String id, String newName) {
    if (_gameData == null) return;
    final index = _gameData!.players.indexWhere((p) => p.id == id);
    if (index != -1) {
      _gameData!.players[index].name = newName;
      _saveGame();
      notifyListeners();
    }
  }

  void updatePlayerBaseScore(String id, int newScore) {
    if (_gameData == null) return;
    final index = _gameData!.players.indexWhere((p) => p.id == id);
    if (index != -1) {
      final oldScore = _gameData!.players[index].score;
      if (oldScore != newScore) {
        _currentRoundEdits.add(ScoreEdit(
          playerId: id,
          playerName: _gameData!.players[index].name,
          scoreBefore: oldScore,
          scoreAfter: newScore,
        ));
      }
      _gameData!.players[index].score = newScore;
      _saveGame();
      notifyListeners();
    }
  }

  void toggleSign() {
    _isNegative = !_isNegative;
    notifyListeners();
  }

  void applyScoreChange(int amount) {
    if (_selectedPlayerId != null) {
      int finalAmount = _isNegative ? -amount : amount;
      updatePlayerScore(_selectedPlayerId!, finalAmount);
    }
  }

  void transferScore(String fromId, String toId, int amount) {
    if (_gameData == null || amount <= 0) return;
    final fromIndex = _gameData!.players.indexWhere((p) => p.id == fromId);
    final toIndex = _gameData!.players.indexWhere((p) => p.id == toId);
    if (fromIndex != -1 && toIndex != -1) {
      _gameData!.players[fromIndex].currentRoundChange -= amount;
      _gameData!.players[toIndex].currentRoundChange += amount;
      _transferTriggered = true;

      _currentRoundTransfers.add(ScoreTransfer(
        fromPlayerId: fromId,
        fromPlayerName: _gameData!.players[fromIndex].name,
        toPlayerId: toId,
        toPlayerName: _gameData!.players[toIndex].name,
        amount: amount,
      ));
      notifyListeners();
    }
  }

  bool get hasCurrentRoundChanges {
    return players.any((p) => p.currentRoundChange != 0);
  }

  void finishRound() {
    if (_gameData == null) return;
    final playerData = <String, RoundPlayerData>{};
    for (var player in _gameData!.players) {
      playerData[player.id] = RoundPlayerData(
        playerName: player.name,
        scoreChange: player.currentRoundChange,
        totalScoreAfter: player.totalScore,
      );
    }
    _gameData!.roundHistory.add(RoundRecord(
      roundNumber: _gameData!.currentRound,
      playerData: playerData,
      transfers: List.from(_currentRoundTransfers),
      edits: List.from(_currentRoundEdits),
      playerChanges: List.from(_currentRoundPlayerChanges),
    ));
    for (var player in _gameData!.players) {
      player.score += player.currentRoundChange;
      player.currentRoundChange = 0;
    }
    _gameData!.currentRound++;
    _selectedPlayerId = null;
    _isNegative = false;
    _currentRoundTransfers = [];
    _currentRoundEdits = [];
    _currentRoundPlayerChanges = [];
    _saveGame();
    notifyListeners();
  }

  /// Clamp all players to screen bounds for a given orientation
  void clampAllPlayers(Size screenSize, Orientation orientation) {
    if (_gameData == null) return;
    const double cardWidth = 240.0;
    const double cardHeight = 100.0;
    bool changed = false;

    for (var player in _gameData!.players) {
      final maxX = (screenSize.width - cardWidth * player.scale).clamp(0.0, double.infinity);
      final maxY = (screenSize.height - cardHeight * player.scale - 10).clamp(0.0, double.infinity);

      if (orientation == Orientation.portrait) {
        final pos = player.position;
        final clamped = Offset(
          pos.dx.clamp(0, maxX),
          pos.dy.clamp(0, maxY),
        );
        if (pos != clamped) {
          player.position = clamped;
          changed = true;
        }
      } else {
        final pos = player.landscapePosition ?? player.position;
        final clamped = Offset(
          pos.dx.clamp(0, maxX),
          pos.dy.clamp(0, maxY),
        );
        if (pos != clamped) {
          player.landscapePosition = clamped;
          changed = true;
        }
      }
    }
    if (changed) {
      _saveGame();
      notifyListeners();
    }
  }

  /// Generate default landscape layout if missing
  void ensureLandscapeLayout(Size landscapeSize) {
    if (_gameData == null) return;
    bool anyMissing = false;
    for (var player in _gameData!.players) {
      if (player.landscapePosition == null) {
        anyMissing = true;
        break;
      }
    }
    if (anyMissing) {
      final positions = _generateSpreadPositions(_gameData!.players.length, landscapeSize);
      for (int i = 0; i < _gameData!.players.length; i++) {
        if (_gameData!.players[i].landscapePosition == null) {
          _gameData!.players[i].landscapePosition =
              i < positions.length ? positions[i] : const Offset(50, 50);
        }
      }
      _saveGame();
      notifyListeners();
    }
  }

  /// Reset player position to center of screen, with slight offset if center is occupied
  void resetPlayerPosition(String playerId, Size screenSize, Orientation orientation) {
    if (_gameData == null) return;
    const double cardWidth = 240.0;
    const double cardHeight = 100.0;
    final index = _gameData!.players.indexWhere((p) => p.id == playerId);
    if (index == -1) return;

    double centerX = (screenSize.width - cardWidth) / 2;
    double centerY = (screenSize.height - cardHeight) / 2;

    // Check if any other player is near center, add offset
    for (var p in _gameData!.players) {
      if (p.id == playerId) continue;
      final pos = orientation == Orientation.portrait
          ? p.position
          : (p.landscapePosition ?? p.position);
      final dx = (pos.dx - centerX).abs();
      final dy = (pos.dy - centerY).abs();
      if (dx < 30 && dy < 30) {
        centerX += 30;
        centerY += 20;
      }
    }

    final maxX = (screenSize.width - cardWidth).clamp(0.0, double.infinity);
    final maxY = (screenSize.height - cardHeight - 10).clamp(0.0, double.infinity);
    centerX = centerX.clamp(0, maxX);
    centerY = centerY.clamp(0, maxY);

    if (orientation == Orientation.portrait) {
      _gameData!.players[index].position = Offset(centerX, centerY);
    } else {
      _gameData!.players[index].landscapePosition = Offset(centerX, centerY);
    }
    _saveGame();
    notifyListeners();
  }

  void toggleScreenAlwaysOn(bool value) {
    if (_gameData == null) return;
    _gameData!.isScreenAlwaysOn = value;
    if (value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
    _saveGame();
    notifyListeners();
  }

  void setQuickNextRound(bool value) {
    if (_gameData == null) return;
    _gameData!.quickNextRound = value;
    _saveGame();
    notifyListeners();
  }

  void setZeroSum(bool value) {
    if (_gameData == null) return;
    _gameData!.isZeroSum = value;
    _saveGame();
    notifyListeners();
  }

  void updateBackgroundConfig(BackgroundConfig config) {
    if (_gameData == null) return;
    _gameData!.backgroundConfig = config;
    _saveGame();
    notifyListeners();
  }

  void updateGameName(String name) {
    if (_gameData == null) return;
    _gameData!.name = name;
    _saveGame();
    notifyListeners();
  }

  void updateScoreSteps(List<int> steps) {
    if (_gameData == null) return;
    _gameData!.scoreSteps = steps;
    _saveGame();
    notifyListeners();
  }

  Future<void> _saveGame() async {
    if (_gameData == null) return;
    await GameStorage.saveGame(_gameData!);
  }
}
