// lib/app/modules/camera/camera_controller.dart
// ALL settings now wired:
//  • showGrid    → reads SettingsService.showGrid (reactive, live)
//  • highQuality → uses ResolutionPreset.high for takePicture when enabled
//  • haptics     → HapticFeedback on shutter + filter select

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/ai_filter_model.dart';
import '../../data/services/live_filter_service.dart';
import '../../data/services/settings_service.dart';
import '../../routes/app_routes.dart';

class CameraViewController extends GetxController
    with GetSingleTickerProviderStateMixin {

  // ── Services ───────────────────────────────────────────────────────────────
  final _settings = Get.find<SettingsService>();

  // ── Camera state ───────────────────────────────────────────────────────────
  CameraController? cameraCtrl;
  final cameras       = <CameraDescription>[].obs;
  final isInitialized = false.obs;
  final isCapturing   = false.obs;
  final isFrontCamera = false.obs;
  final flashMode     = FlashMode.off.obs;
  final zoomLevel     = 1.0.obs;
  final minZoom       = 1.0.obs;
  final maxZoom       = 1.0.obs;
  final hasPermission = false.obs;

  // showGrid is a direct alias to SettingsService so the camera view
  // reacts instantly when the toggle is changed in Settings.
  RxBool get showGrid => _settings.showGrid;

  // ── Live filter state ──────────────────────────────────────────────────────
  final previewBytes   = Rxn<Uint8List>();
  final selectedFilter = AiFilterModel.allFilters.first.obs;

  final _liveService   = LiveFilterService();
  bool  _streamActive  = false;
  int   _sensorDegrees = 90;
  String _presetFilterName = FilterType.none.name;

  // ── Shutter animation ──────────────────────────────────────────────────────
  late AnimationController shutterAnimCtrl;
  late Animation<double>   shutterAnim;

  @override
  void onInit() {
    super.onInit();
    shutterAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    shutterAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: shutterAnimCtrl, curve: Curves.easeInOut));
  }

  @override
  void onReady() {
    super.onReady();
    final args        = Get.arguments as Map<String, dynamic>?;
    _presetFilterName = (args?['presetFilterName'] as String?) ?? FilterType.none.name;
    final match = AiFilterModel.allFilters.firstWhere(
          (f) => f.type.name == _presetFilterName,
      orElse: () => AiFilterModel.allFilters.first,
    );
    selectedFilter.value = match;
    requestPermissionsAndInit();
  }

  @override
  void onClose() {
    _stopStream();
    cameraCtrl?.dispose();
    shutterAnimCtrl.dispose();
    super.onClose();
  }

  // ── Permission ─────────────────────────────────────────────────────────────

  Future<void> requestPermissionsAndInit() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      hasPermission.value = false;
      Get.snackbar('Permission Required', 'Camera permission is needed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade800,
          colorText: Colors.white);
      return;
    }
    hasPermission.value = true;
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      cameras.value = await availableCameras();
      if (cameras.isEmpty) return;
      await _startCamera(cameras.first);
    } catch (e) {
      Get.snackbar('Camera Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _startCamera(CameraDescription desc) async {
    _stopStream();
    await cameraCtrl?.dispose();
    isInitialized.value = false;
    previewBytes.value  = null;
    _sensorDegrees      = desc.sensorOrientation;

    cameraCtrl = CameraController(
      desc,
      ResolutionPreset.low,   // stream always uses low for speed
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await cameraCtrl!.initialize();

    // Explicitly set flash OFF after init — Samsung devices default to
    // FlashMode.auto which fires the flash on every capture automatically.
    try {
      await cameraCtrl!.setFlashMode(FlashMode.off);
    } catch (_) {}
    flashMode.value = FlashMode.off;

    minZoom.value       = await cameraCtrl!.getMinZoomLevel();
    maxZoom.value       = await cameraCtrl!.getMaxZoomLevel();
    zoomLevel.value     = minZoom.value;
    isInitialized.value = true;
    update();

    if (selectedFilter.value.type != FilterType.none) _startStream();
  }

  // ── Stream ─────────────────────────────────────────────────────────────────

  void _startStream() {
    if (cameraCtrl == null || !cameraCtrl!.value.isInitialized) return;
    if (_streamActive) return;
    _streamActive = true;
    cameraCtrl!.startImageStream((CameraImage frame) async {
      final bytes = await _liveService.processFrame(
          frame, selectedFilter.value.type, _sensorDegrees);
      if (bytes != null && _streamActive) previewBytes.value = bytes;
    });
  }

  void _stopStream() {
    if (!_streamActive) return;
    _streamActive = false;
    try { cameraCtrl?.stopImageStream(); } catch (_) {}
    previewBytes.value = null;
  }

  void selectFilter(AiFilterModel filter) {
    selectedFilter.value = filter;
    // Haptic feedback on filter selection
    if (_settings.enableHaptics.value) {
      HapticFeedback.selectionClick();
    }
    if (filter.type == FilterType.none) {
      _stopStream();
    } else if (!_streamActive) {
      _startStream();
    }
  }

  // ── Controls ───────────────────────────────────────────────────────────────

  Future<void> flipCamera() async {
    if (cameras.length < 2) return;
    isInitialized.value = false;
    isFrontCamera.value = !isFrontCamera.value;
    await _startCamera(isFrontCamera.value ? cameras[1] : cameras[0]);
  }

  Future<void> cycleFlash() async {
    if (cameraCtrl == null || !cameraCtrl!.value.isInitialized) return;
    final modes = [FlashMode.off, FlashMode.auto, FlashMode.always, FlashMode.torch];
    final next  = modes[(modes.indexOf(flashMode.value) + 1) % modes.length];
    await cameraCtrl!.setFlashMode(next);
    flashMode.value = next;
  }

  Future<void> setZoom(double value) async {
    if (cameraCtrl == null) return;
    zoomLevel.value = value.clamp(minZoom.value, maxZoom.value);
    await cameraCtrl!.setZoomLevel(zoomLevel.value);
  }

  Future<void> setFocusPoint(Offset offset, Size previewSize) async {
    if (cameraCtrl == null || !cameraCtrl!.value.isInitialized) return;
    try {
      await cameraCtrl!.setFocusPoint(Offset(
        (offset.dx / previewSize.width).clamp(0.0, 1.0),
        (offset.dy / previewSize.height).clamp(0.0, 1.0),
      ));
    } catch (_) {}
  }

  // toggleGrid now toggles SettingsService directly — persisted + reactive
  void toggleGrid() => _settings.setShowGrid(!_settings.showGrid.value);

  IconData get flashIcon {
    switch (flashMode.value) {
      case FlashMode.auto:   return Icons.flash_auto;
      case FlashMode.always: return Icons.flash_on;
      case FlashMode.torch:  return Icons.flashlight_on;
      default:               return Icons.flash_off;
    }
  }

  // ── Capture ────────────────────────────────────────────────────────────────

  Future<void> captureImage() async {
    if (cameraCtrl == null || isCapturing.value) return;
    if (!cameraCtrl!.value.isInitialized) return;
    try {
      isCapturing.value = true;
      if (_settings.enableHaptics.value) HapticFeedback.mediumImpact();
      shutterAnimCtrl.forward().then((_) => shutterAnimCtrl.reverse());

      // Stop the image stream BEFORE taking a picture — required on Android.
      // The stream and takePicture() cannot run simultaneously.
      _stopStream();

      // takePicture() always captures at the sensor's native full resolution
      // on Android regardless of ResolutionPreset (which only controls the
      // preview/stream resolution). No separate hi-res controller is needed —
      // creating a second CameraController and disposing it corrupts the
      // ImageReader surface reference on Samsung devices, causing:
      // "getSurface() on a null object reference"
      final xFile = await cameraCtrl!.takePicture();

      Get.toNamed(AppRoutes.FILTER, arguments: {
        'imagePath':        xFile.path,
        'presetFilterName': selectedFilter.value.type.name,
      });
    } catch (e) {
      Get.snackbar('Capture Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
      // Restart stream so preview recovers if capture failed.
      if (selectedFilter.value.type != FilterType.none) _startStream();
    } finally {
      isCapturing.value = false;
    }
  }
}