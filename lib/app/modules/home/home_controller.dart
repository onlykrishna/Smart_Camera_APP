// lib/app/modules/home/home_controller.dart

import 'package:get/get.dart';
import '../../data/services/gallery_service.dart';

class HomeController extends GetxController {
  final _gallery = Get.find<GalleryService>();

  final totalPhotos        = 0.obs;
  final distinctFiltersUsed = 0.obs;
  final favoriteFilter     = '—'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadStats();
  }

  @override
  void onReady() {
    super.onReady();
    _loadStats();
  }

  void _loadStats() {
    final images = _gallery.loadSavedImages();
    totalPhotos.value = images.length;

    final stats = _gallery.filterUsageStats();
    distinctFiltersUsed.value = stats.keys.length;

    if (stats.isNotEmpty) {
      final fav = stats.entries.reduce((a, b) => a.value > b.value ? a : b);
      favoriteFilter.value = fav.key;
    } else {
      favoriteFilter.value = '—';
    }
  }
}
