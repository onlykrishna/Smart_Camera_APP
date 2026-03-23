// lib/app/routes/app_pages.dart

import 'package:get/get.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/camera/camera_binding.dart';
import '../modules/camera/camera_view.dart';
import '../modules/filter/filter_binding.dart';
import '../modules/filter/filter_view.dart';
import '../modules/gallery/gallery_binding.dart';
import '../modules/gallery/gallery_view.dart';
import '../modules/settings/settings_binding.dart';
import '../modules/settings/settings_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.CAMERA,
      page: () => const CameraView(),
      binding: CameraBinding(),
    ),
    GetPage(
      name: AppRoutes.FILTER,
      page: () => const FilterView(),
      binding: FilterBinding(),
    ),
    GetPage(
      name: AppRoutes.GALLERY,
      page: () => const GalleryView(),
      binding: GalleryBinding(),
    ),
    GetPage(
      name: AppRoutes.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
  ];
}
