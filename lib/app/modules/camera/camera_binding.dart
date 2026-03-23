// lib/app/modules/camera/camera_binding.dart
import 'package:get/get.dart';
import 'camera_controller.dart';

class CameraBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CameraViewController>(() => CameraViewController());
  }
}
