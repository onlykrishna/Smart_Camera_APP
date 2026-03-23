// lib/app/modules/settings/settings_binding.dart
import 'package:get/get.dart';
import '../../data/services/settings_service.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    // SettingsService is a singleton; no new put needed
    Get.find<SettingsService>();
  }
}
