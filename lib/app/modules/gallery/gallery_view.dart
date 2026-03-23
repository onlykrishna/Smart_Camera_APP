// lib/app/modules/gallery/gallery_view.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/ai_filter_model.dart';
import '../../data/services/gallery_service.dart';

class GalleryController extends GetxController {
  final _gallery = Get.find<GalleryService>();

  final images      = <CapturedImageModel>[].obs;
  final searchQuery = ''.obs;
  final isDeleting  = false.obs;

  List<CapturedImageModel> get filteredImages {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) return images;
    return images
        .where((img) => img.filterName.toLowerCase().contains(q))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadImages();
  }

  void loadImages() {
    images.assignAll(_gallery.loadSavedImages());
  }

  Future<void> deleteImage(CapturedImageModel model) async {
    await _gallery.deleteImage(model);
    images.remove(model);
  }

  Future<void> clearAll() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Clear All', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Delete all saved photos? This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _gallery.clearAll();
      images.clear();
    }
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class GalleryView extends GetView<GalleryController> {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Gallery',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            onPressed: controller.clearAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by filter name…',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Grid
          Expanded(
            child: Obx(() {
              final imgs = controller.filteredImages;
              if (imgs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          color: Colors.white24, size: 64),
                      SizedBox(height: 12),
                      Text('No photos yet',
                          style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: imgs.length,
                itemBuilder: (_, i) => _GalleryItem(
                  model: imgs[i],
                  onDelete: () => controller.deleteImage(imgs[i]),
                  onTap: () => _showDetail(context, imgs[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, CapturedImageModel model) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(model.path), fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _DetailRow(label: 'Filter', value: model.filterName),
                  _DetailRow(
                      label: 'Captured',
                      value: _fmtDate(model.capturedAt)),
                  if (model.detectedFaces != null)
                    _DetailRow(
                        label: 'Faces',
                        value: '${model.detectedFaces}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}

class _GalleryItem extends StatelessWidget {
  final CapturedImageModel model;
  final VoidCallback        onDelete;
  final VoidCallback        onTap;

  const _GalleryItem({
    required this.model,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _confirmDelete(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(model.path), fit: BoxFit.cover),
          ),
          // Filter badge
          Positioned(
            bottom: 4, left: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                model.filterName,
                style: const TextStyle(
                    color: Colors.white, fontSize: 8),
              ),
            ),
          ),
          // Face icon
          if (model.detectedFaces != null)
            const Positioned(
              top: 4, right: 4,
              child: Icon(Icons.face, color: Colors.purpleAccent, size: 14),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Photo',
            style: TextStyle(color: Colors.white)),
        content: const Text('Remove this photo?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
