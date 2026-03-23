// lib/app/data/services/settings_service.dart

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends GetxService {
  late SharedPreferences _prefs;

  // Reactive settings
  final autoSave        = true.obs;
  final showGrid        = false.obs;
  final enableHaptics   = true.obs;
  final defaultFilter   = 'none'.obs;
  final highQuality     = true.obs;
  final showFaceLabels  = true.obs;

  Future<SettingsService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
    return this;
  }

  void _load() {
    autoSave.value       = _prefs.getBool('auto_save')       ?? true;
    showGrid.value       = _prefs.getBool('show_grid')       ?? false;
    enableHaptics.value  = _prefs.getBool('enable_haptics')  ?? true;
    defaultFilter.value  = _prefs.getString('default_filter') ?? 'none';
    highQuality.value    = _prefs.getBool('high_quality')    ?? true;
    showFaceLabels.value = _prefs.getBool('show_face_labels') ?? true;
  }

  Future<void> setAutoSave(bool v) async {
    autoSave.value = v;
    await _prefs.setBool('auto_save', v);
  }

  Future<void> setShowGrid(bool v) async {
    showGrid.value = v;
    await _prefs.setBool('show_grid', v);
  }

  Future<void> setEnableHaptics(bool v) async {
    enableHaptics.value = v;
    await _prefs.setBool('enable_haptics', v);
  }

  Future<void> setHighQuality(bool v) async {
    highQuality.value = v;
    await _prefs.setBool('high_quality', v);
  }

  Future<void> setShowFaceLabels(bool v) async {
    showFaceLabels.value = v;
    await _prefs.setBool('show_face_labels', v);
  }
}
