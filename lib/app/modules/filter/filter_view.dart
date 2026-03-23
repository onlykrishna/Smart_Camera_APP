// lib/app/modules/filter/filter_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/ai_filter_model.dart';
import '../../widgets/filter_chip_bar.dart';
import '../../widgets/face_overlay_painter.dart';
import 'filter_controller.dart';

class FilterView extends GetView<FilterController> {
  const FilterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ── Image Preview ──────────────────────────────────────────────────
          Expanded(child: _ImagePreview(controller: controller)),

          // ── Filter Strip ───────────────────────────────────────────────────
          _FilterStrip(controller: controller),

          // ── Action Bar ─────────────────────────────────────────────────────
          _ActionBar(controller: controller),
        ],
      ),
    );
  }
}

// ── Image Preview with face overlay ─────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  final FilterController controller;
  const _ImagePreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Filtered image
        Obx(() {
          final bytes = controller.filteredBytes.value;
          if (bytes == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          return Image.memory(bytes, fit: BoxFit.contain);
        }),

        // Processing overlay
        Obx(() => controller.isProcessing.value
            ? Container(
          color: Colors.black45,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Applying AI Filter…',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        )
            : const SizedBox.shrink()),

        // Face detection bounding box overlay
        Obx(() {
          final faces = controller.faceResults;
          final imgSize = controller.imageSize.value;
          if (faces.isEmpty || imgSize == null) return const SizedBox.shrink();

          return LayoutBuilder(builder: (context, constraints) {
            return Obx(() => CustomPaint(
              painter: FaceOverlayPainter(
                faces: faces,
                imageSize: imgSize,
                displaySize: Size(constraints.maxWidth, constraints.maxHeight),
                showLabels: controller.showFaceLabels.value,
              ),
            ));
          });
        }),

        // Top back button
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TopBtn(icon: Icons.arrow_back_ios_new, onTap: Get.back),
                  Obx(() => Text(
                    controller.selectedFilter.value.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                  _TopBtn(
                    icon: Icons.refresh,
                    onTap: controller.resetFilter,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Face count badge
        Obx(() {
          if (controller.faceResults.isEmpty) return const SizedBox.shrink();
          return Positioned(
            top: 80,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4A148C).withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.face, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${controller.faceResults.length} face(s)',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Filter Strip ─────────────────────────────────────────────────────────────

class _FilterStrip extends StatelessWidget {
  final FilterController controller;
  const _FilterStrip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FilterChipBar(
      filters: AiFilterModel.allFilters,
      selected: controller.selectedFilter,
      onSelect: controller.applyFilter,
      thumbnails: controller.thumbnails,
    );
  }
}

// ── Action Bar ───────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final FilterController controller;
  const _ActionBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Row(
          children: [
            // Discard
            Expanded(
              child: OutlinedButton.icon(
                onPressed: Get.back,
                icon: const Icon(Icons.close),
                label: const Text('Discard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Save
            Expanded(
              flex: 2,
              child: Obx(() {
                final saving   = controller.isSaving.value;
                final saved    = controller.autoSaved.value;
                return ElevatedButton.icon(
                  onPressed: saving ? null : controller.saveToGallery,
                  icon: saving
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : Icon(saved ? Icons.check_circle : Icons.save_alt),
                  label: Text(
                    saving ? 'Saving…'
                        : saved ? 'Saved ✓'
                        : 'Save to Gallery',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: saved
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _TopBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}