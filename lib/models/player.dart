import 'package:flutter/material.dart';

class Player {
  String id;
  String name;
  int score;
  int initialScore;
  Offset position;
  Offset? landscapePosition;
  Color color;
  int currentRoundChange;
  double scale;

  Player({
    required this.id,
    required this.name,
    this.score = 0,
    this.initialScore = 0,
    this.position = const Offset(100, 100),
    this.landscapePosition,
    this.color = Colors.blue,
    this.currentRoundChange = 0,
    this.scale = 1.0,
  });

  int get totalScore => score + currentRoundChange;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'initialScore': initialScore,
      'positionX': position.dx,
      'positionY': position.dy,
      'landscapePositionX': landscapePosition?.dx,
      'landscapePositionY': landscapePosition?.dy,
      'colorValue': color.toARGB32(),
      'currentRoundChange': currentRoundChange,
      'scale': scale,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      score: json['score'] as int? ?? 0,
      initialScore: json['initialScore'] as int? ?? 0,
      position: Offset(
        (json['positionX'] as num?)?.toDouble() ?? 100,
        (json['positionY'] as num?)?.toDouble() ?? 100,
      ),
      landscapePosition: json['landscapePositionX'] != null
          ? Offset(
              (json['landscapePositionX'] as num).toDouble(),
              (json['landscapePositionY'] as num).toDouble(),
            )
          : null,
      color: Color(json['colorValue'] as int? ?? 0xFF2196F3),
      currentRoundChange: json['currentRoundChange'] as int? ?? 0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
