// lib/app/modules/filter/filter_binding.dart
import 'package:get/get.dart';
import 'filter_controller.dart';

class FilterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FilterController>(() => FilterController());
  }
}
