// lib/app/bindings/initial_binding.dart

import 'package:get/get.dart';
import '../data/services/settings_service.dart';
import '../data/services/filter_service.dart';
import '../data/services/gallery_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FilterService>(() => FilterService(), fenix: true);
    Get.lazyPut<GalleryService>(() => GalleryService(), fenix: true);
  }
}
