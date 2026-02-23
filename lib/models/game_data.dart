import 'player.dart';
import 'round_record.dart';

/// Represents a saved game session with all its data
class GameData {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;
  List<Player> players;
  List<RoundRecord> roundHistory;
  int currentRound;
  bool isScreenAlwaysOn;
  bool quickNextRound;
  bool isZeroSum;
  List<int> scoreSteps;
  BackgroundConfig backgroundConfig;

  // Per-game toolbar position
  double? toolbarPortraitX;
  double? toolbarPortraitY;
  double? toolbarLandscapeX;
  double? toolbarLandscapeY;

  GameData({
    required this.id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Player>? players,
    List<RoundRecord>? roundHistory,
    this.currentRound = 1,
    this.isScreenAlwaysOn = true,
    this.quickNextRound = false,
    this.isZeroSum = false,
    List<int>? scoreSteps,
    BackgroundConfig? backgroundConfig,
    this.toolbarPortraitX,
    this.toolbarPortraitY,
    this.toolbarLandscapeX,
    this.toolbarLandscapeY,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        players = players ?? [],
        roundHistory = roundHistory ?? [],
        scoreSteps = scoreSteps ?? [1, 2, 4, 8, 16, 32, 64, 128],
        backgroundConfig = backgroundConfig ?? BackgroundConfig();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'players': players.map((p) => p.toJson()).toList(),
      'roundHistory': roundHistory.map((r) => r.toJson()).toList(),
      'currentRound': currentRound,
      'isScreenAlwaysOn': isScreenAlwaysOn,
      'quickNextRound': quickNextRound,
      'isZeroSum': isZeroSum,
      'scoreSteps': scoreSteps,
      'backgroundConfig': backgroundConfig.toJson(),
      'toolbarPortraitX': toolbarPortraitX,
      'toolbarPortraitY': toolbarPortraitY,
      'toolbarLandscapeX': toolbarLandscapeX,
      'toolbarLandscapeY': toolbarLandscapeY,
    };
  }

  factory GameData.fromJson(Map<String, dynamic> json) {
    return GameData(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      players: (json['players'] as List<dynamic>?)
              ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      roundHistory: (json['roundHistory'] as List<dynamic>?)
              ?.map((r) => RoundRecord.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      currentRound: json['currentRound'] as int? ?? 1,
      isScreenAlwaysOn: json['isScreenAlwaysOn'] as bool? ?? true,
      quickNextRound: json['quickNextRound'] as bool? ?? false,
      isZeroSum: json['isZeroSum'] as bool? ?? false,
      scoreSteps: (json['scoreSteps'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 4, 8, 16, 32, 64, 128],
      backgroundConfig: json['backgroundConfig'] != null
          ? BackgroundConfig.fromJson(
              json['backgroundConfig'] as Map<String, dynamic>)
          : BackgroundConfig(),
      toolbarPortraitX: (json['toolbarPortraitX'] as num?)?.toDouble(),
      toolbarPortraitY: (json['toolbarPortraitY'] as num?)?.toDouble(),
      toolbarLandscapeX: (json['toolbarLandscapeX'] as num?)?.toDouble(),
      toolbarLandscapeY: (json['toolbarLandscapeY'] as num?)?.toDouble(),
    );
  }
}

enum BackgroundType {
  monet, // Monet-style color palette tablecloth
  solidColor, // Solid color
  image, // Custom image (future)
}

class BackgroundConfig {
  BackgroundType type;
  int? solidColorValue;
  String? imagePath;
  int monetPaletteIndex; // Index of the Monet color palette

  BackgroundConfig({
    this.type = BackgroundType.monet,
    this.solidColorValue,
    this.imagePath,
    this.monetPaletteIndex = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'solidColorValue': solidColorValue,
      'imagePath': imagePath,
      'monetPaletteIndex': monetPaletteIndex,
    };
  }

  factory BackgroundConfig.fromJson(Map<String, dynamic> json) {
    return BackgroundConfig(
      type: BackgroundType.values[json['type'] as int? ?? 0],
      solidColorValue: json['solidColorValue'] as int?,
      imagePath: json['imagePath'] as String?,
      monetPaletteIndex: json['monetPaletteIndex'] as int? ?? 0,
    );
  }
}
