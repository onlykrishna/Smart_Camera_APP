import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/bindings/initial_binding.dart';
import 'app/data/services/gallery_service.dart';
import 'app/routes/app_pages.dart';
import 'app/data/services/settings_service.dart';
import 'app/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() => SettingsService().init());
  await Get.putAsync(() => GalleryService().init());
  runApp(const SmartCameraApp());
}

class SmartCameraApp extends StatelessWidget {
  const SmartCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart Camera AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.HOME,
      getPages: AppPages.routes,
    );
  }
}
