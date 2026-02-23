/// Represents the data for a single round of scoring
class RoundRecord {
  final int roundNumber;
  final Map<String, RoundPlayerData> playerData; // keyed by player id
  final List<ScoreTransfer> transfers; // score transfers between players
  final List<ScoreEdit> edits; // manual score edits
  final List<PlayerChangeEvent> playerChanges; // player add/remove events
  final DateTime timestamp;

  RoundRecord({
    required this.roundNumber,
    required this.playerData,
    List<ScoreTransfer>? transfers,
    List<ScoreEdit>? edits,
    List<PlayerChangeEvent>? playerChanges,
    DateTime? timestamp,
  })  : transfers = transfers ?? [],
        edits = edits ?? [],
        playerChanges = playerChanges ?? [],
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'playerData': playerData.map((k, v) => MapEntry(k, v.toJson())),
      'transfers': transfers.map((t) => t.toJson()).toList(),
      'edits': edits.map((e) => e.toJson()).toList(),
      'playerChanges': playerChanges.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RoundRecord.fromJson(Map<String, dynamic> json) {
    return RoundRecord(
      roundNumber: json['roundNumber'] as int,
      playerData: (json['playerData'] as Map<String, dynamic>).map(
        (k, v) =>
            MapEntry(k, RoundPlayerData.fromJson(v as Map<String, dynamic>)),
      ),
      transfers: (json['transfers'] as List<dynamic>?)
              ?.map((t) => ScoreTransfer.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      edits: (json['edits'] as List<dynamic>?)
              ?.map((e) => ScoreEdit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      playerChanges: (json['playerChanges'] as List<dynamic>?)
              ?.map(
                  (e) => PlayerChangeEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class RoundPlayerData {
  final String playerName;
  final int scoreChange;
  final int totalScoreAfter;

  RoundPlayerData({
    required this.playerName,
    required this.scoreChange,
    required this.totalScoreAfter,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'scoreChange': scoreChange,
      'totalScoreAfter': totalScoreAfter,
    };
  }

  factory RoundPlayerData.fromJson(Map<String, dynamic> json) {
    return RoundPlayerData(
      playerName: json['playerName'] as String,
      scoreChange: json['scoreChange'] as int? ?? 0,
      totalScoreAfter: json['totalScoreAfter'] as int? ?? 0,
    );
  }
}

/// Represents a score transfer between two players
class ScoreTransfer {
  final String fromPlayerId;
  final String fromPlayerName;
  final String toPlayerId;
  final String toPlayerName;
  final int amount;
  final DateTime timestamp;

  ScoreTransfer({
    required this.fromPlayerId,
    required this.fromPlayerName,
    required this.toPlayerId,
    required this.toPlayerName,
    required this.amount,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'fromPlayerId': fromPlayerId,
      'fromPlayerName': fromPlayerName,
      'toPlayerId': toPlayerId,
      'toPlayerName': toPlayerName,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScoreTransfer.fromJson(Map<String, dynamic> json) {
    return ScoreTransfer(
      fromPlayerId: json['fromPlayerId'] as String,
      fromPlayerName: json['fromPlayerName'] as String,
      toPlayerId: json['toPlayerId'] as String,
      toPlayerName: json['toPlayerName'] as String,
      amount: json['amount'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Represents a manual score edit
class ScoreEdit {
  final String playerId;
  final String playerName;
  final int scoreBefore;
  final int scoreAfter;
  final DateTime timestamp;

  ScoreEdit({
    required this.playerId,
    required this.playerName,
    required this.scoreBefore,
    required this.scoreAfter,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  int get difference => scoreAfter - scoreBefore;

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'scoreBefore': scoreBefore,
      'scoreAfter': scoreAfter,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScoreEdit.fromJson(Map<String, dynamic> json) {
    return ScoreEdit(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      scoreBefore: json['scoreBefore'] as int,
      scoreAfter: json['scoreAfter'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Represents a player being added or removed during a round
enum PlayerChangeType { added, removed }

class PlayerChangeEvent {
  final PlayerChangeType type;
  final String playerId;
  final String playerName;
  final DateTime timestamp;

  PlayerChangeEvent({
    required this.type,
    required this.playerId,
    required this.playerName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type == PlayerChangeType.added ? 'added' : 'removed',
      'playerId': playerId,
      'playerName': playerName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PlayerChangeEvent.fromJson(Map<String, dynamic> json) {
    return PlayerChangeEvent(
      type: json['type'] == 'added'
          ? PlayerChangeType.added
          : PlayerChangeType.removed,
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
