// lib/app/data/services/gallery_service.dart
//
// Handles saving captured/filtered images to device gallery and
// persisting gallery metadata via SharedPreferences.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_filter_model.dart';

class GalleryService extends GetxService {
  static const _galleryKey = 'smart_camera_gallery';

  late SharedPreferences _prefs;

  Future<GalleryService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  /// Saves [imageBytes] to the device photo gallery and records metadata.
  Future<CapturedImageModel?> saveToGallery(
    Uint8List imageBytes,
    FilterType filter,
    String filterName, {
    int? detectedFaces,
  }) async {
    try {
      // Write to app documents first, then use gal to save to gallery
      final dir  = await getApplicationDocumentsDirectory();
      final name = 'smart_cam_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(imageBytes);

      // Save to device gallery
// Save to device gallery
      await GallerySaver.saveImage(file.path);

      final model = CapturedImageModel(
        path:          file.path,
        appliedFilter: filter,
        filterName:    filterName,
        capturedAt:    DateTime.now(),
        detectedFaces: detectedFaces,
      );

      await _persistImage(model);
      return model;
    } catch (e) {
      return null;
    }
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  List<CapturedImageModel> loadSavedImages() {
    final raw = _prefs.getStringList(_galleryKey) ?? [];
    return raw
        .map((s) {
          try {
            return CapturedImageModel.fromMap(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<CapturedImageModel>()
        .toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteImage(CapturedImageModel model) async {
    // Remove file
    try {
      final file = File(model.path);
      if (await file.exists()) await file.delete();
    } catch (_) {}

    // Remove from prefs
    final raw = _prefs.getStringList(_galleryKey) ?? [];
    raw.removeWhere((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return m['path'] == model.path;
      } catch (_) {
        return false;
      }
    });
    await _prefs.setStringList(_galleryKey, raw);
  }

  Future<void> clearAll() async {
    final images = loadSavedImages();
    for (final img in images) {
      try {
        final file = File(img.path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    await _prefs.remove(_galleryKey);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _persistImage(CapturedImageModel model) async {
    final raw = _prefs.getStringList(_galleryKey) ?? [];
    raw.insert(0, jsonEncode(model.toMap()));
    // Cap at 100 entries
    if (raw.length > 100) raw.removeLast();
    await _prefs.setStringList(_galleryKey, raw);
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Map<String, int> filterUsageStats() {
    final images  = loadSavedImages();
    final stats   = <String, int>{};
    for (final img in images) {
      stats[img.filterName] = (stats[img.filterName] ?? 0) + 1;
    }
    return stats;
  }
}
