// lib/app/modules/gallery/gallery_binding.dart
import 'package:get/get.dart';
import 'gallery_view.dart'; // GalleryController lives in gallery_view.dart

class GalleryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GalleryController>(() => GalleryController());
  }
}
