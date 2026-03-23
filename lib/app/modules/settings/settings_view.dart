// lib/app/modules/settings/settings_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/settings_service.dart';

class SettingsView extends GetView<SettingsService> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [

          // ── Camera ──────────────────────────────────────────────────────────
          _SectionHeader('Camera'),

          Obx(() => _ToggleTile(
            icon: Icons.save_alt_rounded,
            title: 'Auto-Save to Gallery',
            subtitle: 'Automatically save every filtered photo when FilterView opens',
            value: controller.autoSave.value,
            onChanged: controller.setAutoSave,
          )),

          Obx(() => _ToggleTile(
            icon: Icons.grid_on_rounded,
            title: 'Show Rule-of-Thirds Grid',
            subtitle: 'Overlay composition guide lines on the live camera preview',
            value: controller.showGrid.value,
            onChanged: controller.setShowGrid,
          )),

          Obx(() => _ToggleTile(
            icon: Icons.hd_rounded,
            title: 'High Quality Capture',
            subtitle: 'Use maximum sensor resolution when taking photos',
            value: controller.highQuality.value,
            onChanged: controller.setHighQuality,
          )),

          const SizedBox(height: 20),

          // ── AI & Filters ─────────────────────────────────────────────────────
          _SectionHeader('AI & Filters'),

          Obx(() => _ToggleTile(
            icon: Icons.face_retouching_natural_rounded,
            title: 'Show Face Labels',
            subtitle: 'Show smile / eye-open probability text on face detection overlays',
            value: controller.showFaceLabels.value,
            onChanged: controller.setShowFaceLabels,
          )),

          const SizedBox(height: 20),

          // ── Accessibility ────────────────────────────────────────────────────
          _SectionHeader('Accessibility'),

          Obx(() => _ToggleTile(
            icon: Icons.vibration_rounded,
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on shutter press, filter selection and save',
            value: controller.enableHaptics.value,
            onChanged: controller.setEnableHaptics,
          )),

          // No footer text — removed as requested
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF42A5F5),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Toggle Tile ───────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? const Color(0xFF42A5F5).withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: SwitchListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: value
                ? const Color(0xFF1565C0).withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: value ? const Color(0xFF42A5F5) : Colors.white38,
              size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: value ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF42A5F5),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF1565C0).withOpacity(0.4);
          }
          return Colors.white12;
        }),
      ),
    );
  }
}