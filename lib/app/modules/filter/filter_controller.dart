// lib/app/modules/filter/filter_controller.dart
// ALL settings wired:
//  • autoSave        → saves automatically when FilterView opens (after capture)
//  • showFaceLabels  → passed to FaceOverlayPainter
//  • haptics         → on save

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/models/ai_filter_model.dart';
import '../../data/services/filter_service.dart';
import '../../data/services/face_detection_service.dart';
import '../../data/services/gallery_service.dart';
import '../../data/services/settings_service.dart';

class FilterController extends GetxController {
  final _filterService  = Get.find<FilterService>();
  final _galleryService = Get.find<GalleryService>();
  final _settings       = Get.find<SettingsService>();

  late String    imagePath;
  Uint8List?     rawImageBytes;

  final filteredBytes  = Rxn<Uint8List>();
  final selectedFilter = AiFilterModel.allFilters.first.obs;
  final isProcessing   = false.obs;
  final isSaving       = false.obs;
  final faceResults    = <FaceResult>[].obs;
  final imageSize      = Rxn<Size>();
  final thumbnails     = <FilterType, Uint8List>{}.obs;

  // Expose showFaceLabels reactively so FilterView can pass to painter
  RxBool get showFaceLabels => _settings.showFaceLabels;

  bool _filterBusy   = false;
  final autoSaved    = false.obs;  // Rx so the Save button reacts live
  AiFilterModel? _pendingFilter;

  @override
  void onInit() {
    super.onInit();
    final args       = Get.arguments as Map<String, dynamic>?;
    imagePath        = args?['imagePath'] ?? '';
    final presetName = args?['presetFilterName'] as String?;
    if (presetName != null && presetName.isNotEmpty) {
      selectedFilter.value = AiFilterModel.allFilters.firstWhere(
            (f) => f.type.name == presetName,
        orElse: () => AiFilterModel.allFilters.first,
      );
    }
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      rawImageBytes       = await File(imagePath).readAsBytes();
      filteredBytes.value = rawImageBytes;
      await _doApply(selectedFilter.value);
      _generateThumbnails();

      // Auto-save fires ONCE on load when the setting is ON.
      // _autoSaved flag prevents saveToGallery() from saving again manually.
      if ((_settings.autoSave.value)) {
        await _autoSave();
        autoSaved.value = true;
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not load image: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _autoSave() async {
    final bytes = filteredBytes.value;
    if (bytes == null) return;
    await _galleryService.saveToGallery(
      bytes,
      selectedFilter.value.type,
      selectedFilter.value.name,
      detectedFaces: faceResults.isEmpty ? null : faceResults.length,
    );
    if (_settings.enableHaptics.value) HapticFeedback.lightImpact();
  }

  Future<void> _generateThumbnails() async {
    if (rawImageBytes == null) return;
    for (final filter in AiFilterModel.allFilters) {
      try {
        thumbnails[filter.type] = await _filterService.generateThumbnail(
            rawImageBytes!, filter.type);
      } catch (_) {}
    }
  }

  Future<void> applyFilter(AiFilterModel filter) async {
    if (rawImageBytes == null) return;
    // Reset auto-saved flag when user manually changes filter —
    // they may want to save this new version.
    if (filter.type != selectedFilter.value.type) autoSaved.value = false;
    if (_filterBusy) {
      _pendingFilter       = filter;
      selectedFilter.value = filter;
      return;
    }
    await _doApply(filter);
    if (_pendingFilter != null &&
        _pendingFilter!.type != selectedFilter.value.type) {
      final next = _pendingFilter!;
      _pendingFilter = null;
      await _doApply(next);
    }
  }

  Future<void> _doApply(AiFilterModel filter) async {
    _filterBusy          = true;
    isProcessing.value   = true;
    selectedFilter.value = filter;
    faceResults.clear();
    try {
      if (filter.type == FilterType.faceDetection) {
        await _runFaceDetection();
        filteredBytes.value = rawImageBytes;
      } else {
        filteredBytes.value = await _filterService.applyFilter(
            rawImageBytes!, filter.type);
      }
    } catch (e) {
      Get.snackbar('Filter Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isProcessing.value = false;
      _filterBusy        = false;
    }
  }

  Future<void> _runFaceDetection() async {
    try {
      final svc   = FaceDetectionService();
      final faces = await svc.detectFaces(imagePath);
      faceResults.assignAll(faces);
      if (faces.isNotEmpty) {
        final decoded = await decodeImageFromList(rawImageBytes!);
        imageSize.value =
            Size(decoded.width.toDouble(), decoded.height.toDouble());
      }
    } catch (_) { faceResults.clear(); }
  }

  Future<void> saveToGallery() async {
    final bytes = filteredBytes.value;
    if (bytes == null || isSaving.value) return;

    // If autoSave already saved this exact filter result, don't save again.
    if (autoSaved.value) {
      Get.snackbar(
        '✓ Already Saved',
        'This photo was auto-saved. Change the filter to save a new version.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1565C0),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    isSaving.value = true;
    try {
      final model = await _galleryService.saveToGallery(
        bytes,
        selectedFilter.value.type,
        selectedFilter.value.name,
        detectedFaces: faceResults.isEmpty ? null : faceResults.length,
      );
      if (model != null) {
        autoSaved.value = true; // mark saved so next tap doesn't duplicate
        if (_settings.enableHaptics.value) HapticFeedback.mediumImpact();
        Get.snackbar('✓ Saved', 'Photo saved to SmartCamera AI album',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF1B5E20),
            colorText: Colors.white,
            duration: const Duration(seconds: 2));
      }
    } finally {
      isSaving.value = false;
    }
  }

  void resetFilter() => applyFilter(AiFilterModel.allFilters.first);
}