import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  double _uiScale = 1.0;
  bool _initialized = false;

  double get uiScale => _uiScale;
  bool get initialized => _initialized;

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
}
