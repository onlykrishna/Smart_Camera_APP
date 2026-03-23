// lib/app/modules/camera/camera_view.dart
//
// FIXES:
//  1. Filtered overlay uses SizedBox.expand + fit:BoxFit.cover — fills screen
//  2. Removed AnimatedSwitcher+ValueKey (caused layout reset every frame)
//  3. When Original selected: previewBytes=null → raw CameraPreview visible only
//  4. Raw CameraPreview hidden behind overlay when filter active (no bleed-through)

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/ai_filter_model.dart';
import 'camera_controller.dart';

class CameraView extends GetView<CameraViewController> {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (!controller.hasPermission.value) {
          return _PermissionDenied(onRetry: controller.requestPermissionsAndInit);
        }
        if (!controller.isInitialized.value) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        return _CameraBody(controller: controller);
      }),
    );
  }
}

// ── Camera Body ───────────────────────────────────────────────────────────────

class _CameraBody extends StatelessWidget {
  final CameraViewController controller;
  const _CameraBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _PreviewStack(controller: controller)),
        _BottomPanel(controller: controller),
      ],
    );
  }
}

// ── Preview Stack ─────────────────────────────────────────────────────────────
// Always renders both layers; the filtered overlay covers the raw preview
// completely when active, so there is zero bleed-through.

class _PreviewStack extends StatelessWidget {
  final CameraViewController controller;
  const _PreviewStack({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [

        // ── Layer 1: Raw CameraPreview ────────────────────────────────────────
        // Always present — native AF/AE/zoom work through this layer.
        // Hidden behind the filtered overlay when a filter is active.
        _buildRawPreview(context),

        // ── Layer 2: Filtered frame overlay ──────────────────────────────────
        // Replaces the raw preview when previewBytes is non-null.
        // Uses gaplessPlayback:true to avoid white flicker between frames.
        Obx(() {
          final bytes = controller.previewBytes.value;
          if (bytes == null) return const SizedBox.shrink();
          // SizedBox.expand ensures the image truly fills the Stack cell.
          return SizedBox.expand(
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
        }),

        // ── Layer 3: Rule-of-thirds grid ──────────────────────────────────────
        Obx(() => controller.showGrid.value
            ? const _GridOverlay()
            : const SizedBox.shrink()),

        // ── Layer 4: Top controls ─────────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: _TopBar(controller: controller),
        ),

        // ── Layer 5: Zoom badge ───────────────────────────────────────────────
        Positioned(
          top: 80, right: 16,
          child: _ZoomBadge(controller: controller),
        ),

        // ── Layer 6: Live filter pill (bottom-center of preview) ─────────────
        Obx(() {
          final f = controller.selectedFilter.value;
          if (f.type == FilterType.none) return const SizedBox.shrink();
          return Positioned(
            bottom: 14, left: 0, right: 0,
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: f.gradientColors.last.withOpacity(0.8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing live dot
                    _LiveDot(color: f.gradientColors.last),
                    const SizedBox(width: 8),
                    Text(
                      '${f.name}  ·  LIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRawPreview(BuildContext context) {
    final ctrl = controller.cameraCtrl!;
    final prev = ctrl.value.previewSize;
    return GestureDetector(
      onTapUp: (d) => controller.setFocusPoint(
          d.localPosition, MediaQuery.of(context).size),
      onScaleUpdate: (d) =>
          controller.setZoom(controller.zoomLevel.value * d.scale),
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            // previewSize is landscape (width > height on Android),
            // swap width/height so FittedBox.cover fills portrait correctly.
            width:  prev != null ? prev.height : 1,
            height: prev != null ? prev.width  : 1,
            child:  CameraPreview(ctrl),
          ),
        ),
      ),
    );
  }
}

// ── Animated live dot ─────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  final Color color;
  const _LiveDot({required this.color});
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _anim.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.4 + 0.6 * _anim.value),
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final CameraViewController controller;
  const _TopBar({required this.controller});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _IconBtn(icon: Icons.arrow_back_ios_new, onTap: Get.back),
            const Text('Smart Camera AI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            Obx(() => _IconBtn(
                icon: controller.flashIcon, onTap: controller.cycleFlash)),
          ],
        ),
      ),
    );
  }
}

// ── Zoom Badge ────────────────────────────────────────────────────────────────

class _ZoomBadge extends StatelessWidget {
  final CameraViewController controller;
  const _ZoomBadge({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.maxZoom.value <= 1.01) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          '${controller.zoomLevel.value.toStringAsFixed(1)}×',
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    });
  }
}

// ── Bottom Panel ──────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final CameraViewController controller;
  const _BottomPanel({required this.controller});
  @override
  Widget build(BuildContext context) {
    final bp = MediaQuery.of(context).padding.bottom;
    return Container(
      color: const Color(0xFF0D0D0D),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Filter name label
          Obx(() {
            final f = controller.selectedFilter.value;
            return Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (f.type != FilterType.none)
                    Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: f.gradientColors),
                      ),
                    ),
                  Text(
                    f.type == FilterType.none ? 'Original' : f.name,
                    style: TextStyle(
                      color: f.type == FilterType.none
                          ? Colors.white38
                          : f.gradientColors.last,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Filter strip
          SizedBox(height: 82, child: _FilterStrip(controller: controller)),

          // Zoom slider
          Obx(() {
            if (controller.maxZoom.value <= 1.01) return const SizedBox(height: 8);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.zoom_out, color: Colors.white38, size: 16),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        overlayColor: Colors.white24,
                      ),
                      child: Slider(
                        value: controller.zoomLevel.value
                            .clamp(controller.minZoom.value,
                            controller.maxZoom.value),
                        min: controller.minZoom.value,
                        max: controller.maxZoom.value,
                        onChanged: controller.setZoom,
                      ),
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: Colors.white38, size: 16),
                ],
              ),
            );
          }),

          // Shutter row
          Padding(
            padding: EdgeInsets.fromLTRB(40, 10, 40, bp > 0 ? bp : 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _IconBtn(
                    icon: Icons.photo_library_outlined,
                    onTap: () => Get.toNamed('/gallery')),
                AnimatedBuilder(
                  animation: controller.shutterAnim,
                  builder: (_, __) => Transform.scale(
                    scale: controller.shutterAnim.value,
                    child: GestureDetector(
                      onTap: controller.captureImage,
                      child: Obx(() => Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: controller.isCapturing.value
                              ? Colors.grey.shade700
                              : Colors.white.withOpacity(0.12),
                        ),
                        child: controller.isCapturing.value
                            ? const Center(
                            child: SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ))
                            : const SizedBox.shrink(),
                      )),
                    ),
                  ),
                ),
                _IconBtn(
                    icon: Icons.flip_camera_ios_outlined,
                    onTap: controller.flipCamera),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Strip ──────────────────────────────────────────────────────────────

class _FilterStrip extends StatelessWidget {
  final CameraViewController controller;
  const _FilterStrip({required this.controller});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: AiFilterModel.allFilters.length,
      itemBuilder: (_, i) {
        final filter = AiFilterModel.allFilters[i];
        return Obx(() {
          final isSelected =
              controller.selectedFilter.value.type == filter.type;
          return GestureDetector(
            onTap: () => controller.selectFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 62,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? filter.gradientColors.last
                      : Colors.white12,
                  width: isSelected ? 2 : 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? filter.gradientColors
                      : [
                    filter.gradientColors.first.withOpacity(0.35),
                    filter.gradientColors.last.withOpacity(0.35),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(filter.icon,
                      color: Colors.white
                          .withOpacity(isSelected ? 1.0 : 0.55),
                      size: 22),
                  const SizedBox(height: 4),
                  Text(filter.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 9,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

// ── Grid Overlay ──────────────────────────────────────────────────────────────

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.25)..strokeWidth = 0.6;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(size.width*i/3, 0),
          Offset(size.width*i/3, size.height), p);
      canvas.drawLine(Offset(0, size.height*i/3),
          Offset(size.width, size.height*i/3), p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white12),
      ),
      child: Icon(icon, color: Colors.white, size: 21),
    ),
  );
}

class _PermissionDenied extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionDenied({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.no_photography, color: Colors.white54, size: 64),
      const SizedBox(height: 16),
      const Text('Camera permission required',
          style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Grant Permission'),
      ),
    ]),
  );
}