// lib/app/modules/home/home_view.dart
// FIX: "Try This Filter" now navigates to CAMERA and passes the filter
// as a named argument so CameraViewController pre-selects it.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/ai_filter_model.dart';
import '../../routes/app_routes.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0D0D1A),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroGradient(),
              title: const Text(
                'Smart Camera AI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Get.toNamed(AppRoutes.SETTINGS),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionTitle(title: 'Quick Launch'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuickCard(
                      icon: Icons.camera_alt_outlined,
                      label: 'Open Camera',
                      gradient: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      // No preset filter — open with Original selected
                      onTap: () => Get.toNamed(AppRoutes.CAMERA),
                    ),
                    const SizedBox(width: 12),
                    _QuickCard(
                      icon: Icons.photo_library_outlined,
                      label: 'My Gallery',
                      gradient: const [Color(0xFF4A148C), Color(0xFFCE93D8)],
                      onTap: () => Get.toNamed(AppRoutes.GALLERY),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                _SectionTitle(title: 'AI Filters'),
                const SizedBox(height: 4),
                const Text(
                  'Tap a filter to learn more',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 14),
                _FilterShowcase(),
                const SizedBox(height: 28),

                _SectionTitle(title: 'Your Stats'),
                const SizedBox(height: 12),
                Obx(() => _StatsGrid(
                  photosTaken: controller.totalPhotos.value,
                  filtersUsed: controller.distinctFiltersUsed.value,
                  favoriteFilter: controller.favoriteFilter.value,
                )),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.CAMERA),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Take Photo'),
      ),
    );
  }
}

// ── Hero Gradient ─────────────────────────────────────────────────────────────

class _HeroGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30, top: -30,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0).withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            left: -20, bottom: 20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4A148C).withOpacity(0.2),
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.auto_awesome, size: 48, color: Colors.white24),
          ),
        ],
      ),
    );
  }
}

// ── Quick Card ────────────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter Showcase Grid ──────────────────────────────────────────────────────

class _FilterShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final filters = AiFilterModel.allFilters.skip(1).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: filters.length,
      itemBuilder: (_, i) {
        final f = filters[i];
        return GestureDetector(
          onTap: () => _showFilterInfo(context, f),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: f.gradientColors,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(f.icon, color: Colors.white, size: 28),
                const SizedBox(height: 6),
                Text(f.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                if (f.requiresMLKit)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('ML Kit',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterInfo(BuildContext context, AiFilterModel f) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: f.gradientColors.last.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: f.gradientColors),
                shape: BoxShape.circle,
              ),
              child: Icon(f.icon, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(f.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(f.description,
                style: const TextStyle(color: Colors.white54)),
            if (f.requiresMLKit) ...[
              const SizedBox(height: 10),
              Chip(
                label: const Text('Powered by Google ML Kit'),
                avatar: const Icon(Icons.smart_toy, size: 14),
                backgroundColor: const Color(0xFF4A148C),
                labelStyle:
                const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              // FIX: pass the filter name as argument so CameraViewController
              // pre-selects it when the camera screen opens.
              onPressed: () {
                Get.back(); // close bottom sheet
                Get.toNamed(
                  AppRoutes.CAMERA,
                  arguments: {'presetFilterName': f.type.name},
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Try This Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: f.gradientColors.first,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final int photosTaken;
  final int filtersUsed;
  final String favoriteFilter;

  const _StatsGrid({
    required this.photosTaken,
    required this.filtersUsed,
    required this.favoriteFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
            value: '$photosTaken',
            label: 'Photos Taken',
            color: const Color(0xFF1565C0)),
        const SizedBox(width: 10),
        _StatCard(
            value: '$filtersUsed',
            label: 'Filters Used',
            color: const Color(0xFF4A148C)),
        const SizedBox(width: 10),
        _StatCard(
            value: favoriteFilter,
            label: 'Favourite',
            color: const Color(0xFF1B5E20)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3));
  }
}