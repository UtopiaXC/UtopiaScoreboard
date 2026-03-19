import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  double _uiScale = 1.0;
  bool _initialized = false;
  List<int> _globalScoreSteps = [1, 2, 4, 8, 16, 32, 64, 128];

  double get uiScale => _uiScale;
  bool get initialized => _initialized;
  List<int> get globalScoreSteps => _globalScoreSteps;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('uiScale')) {
      _uiScale = prefs.getDouble('uiScale') ?? 1.0;
      _initialized = true;
    } else {
      _uiScale = 1.0;
      _initialized = false;
    }
    final stepsJson = prefs.getString('global_score_steps');
    if (stepsJson != null) {
      _globalScoreSteps = (jsonDecode(stepsJson) as List<dynamic>).cast<int>();
    }
    notifyListeners();
  }

  Future<void> initializeUiScale(double scale) async {
    if (_initialized) return;
    _uiScale = scale.clamp(0.5, 3.0);
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('uiScale', _uiScale);
    notifyListeners();
  }

  Future<void> setUiScale(double scale) async {
    _uiScale = scale.clamp(0.5, 3.0);
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('uiScale', _uiScale);
    notifyListeners();
  }

  Future<void> setGlobalScoreSteps(List<int> steps) async {
    _globalScoreSteps = steps;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_score_steps', jsonEncode(_globalScoreSteps));
    notifyListeners();
  }

  /// Reload global score steps from SharedPreferences (call after ScoreStepsEditor saves)
  Future<void> reloadGlobalScoreSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final stepsJson = prefs.getString('global_score_steps');
    if (stepsJson != null) {
      _globalScoreSteps = (jsonDecode(stepsJson) as List<dynamic>).cast<int>();
    } else {
      _globalScoreSteps = [1, 2, 4, 8, 16, 32, 64, 128];
    }
    notifyListeners();
  }
}
