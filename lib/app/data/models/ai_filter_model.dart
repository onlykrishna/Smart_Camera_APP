// lib/app/data/models/ai_filter_model.dart

import 'package:flutter/material.dart';

enum FilterType {
  none,
  grayscale,
  vintage,
  edgeDetection,
  cartoon,
  sketch,
  faceDetection,
  warmth,
  cool,
  sepia,
}

class AiFilterModel {
  final FilterType type;
  final String name;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final bool requiresMLKit;

  const AiFilterModel({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.gradientColors,
    this.requiresMLKit = false,
  });

  static const List<AiFilterModel> allFilters = [
    AiFilterModel(
      type: FilterType.none,
      name: 'Original',
      description: 'No filter applied',
      icon: Icons.crop_original,
      gradientColors: [Color(0xFF2C2C2C), Color(0xFF4A4A4A)],
    ),
    AiFilterModel(
      type: FilterType.grayscale,
      name: 'Grayscale',
      description: 'Classic black & white',
      icon: Icons.filter_b_and_w,
      gradientColors: [Color(0xFF424242), Color(0xFF9E9E9E)],
    ),
    AiFilterModel(
      type: FilterType.vintage,
      name: 'Vintage',
      description: 'Warm retro tones',
      icon: Icons.photo_camera_back,
      gradientColors: [Color(0xFF8B4513), Color(0xFFDEB887)],
    ),
    AiFilterModel(
      type: FilterType.sepia,
      name: 'Sepia',
      description: 'Old photograph look',
      icon: Icons.history,
      gradientColors: [Color(0xFF704214), Color(0xFFC8A46E)],
    ),
    AiFilterModel(
      type: FilterType.edgeDetection,
      name: 'Edge Detect',
      description: 'AI-powered edge detection',
      icon: Icons.auto_awesome_mosaic,
      gradientColors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
    ),
    AiFilterModel(
      type: FilterType.cartoon,
      name: 'Cartoon',
      description: 'Cartoon-style rendering',
      icon: Icons.brush,
      gradientColors: [Color(0xFF880E4F), Color(0xFFE91E63)],
    ),
    AiFilterModel(
      type: FilterType.sketch,
      name: 'Sketch',
      description: 'Pencil sketch effect',
      icon: Icons.edit,
      gradientColors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
    ),
    AiFilterModel(
      type: FilterType.warmth,
      name: 'Warm',
      description: 'Golden hour warmth',
      icon: Icons.wb_sunny,
      gradientColors: [Color(0xFFE65100), Color(0xFFFFAB40)],
    ),
    AiFilterModel(
      type: FilterType.cool,
      name: 'Cool',
      description: 'Cold blue tones',
      icon: Icons.ac_unit,
      gradientColors: [Color(0xFF0D47A1), Color(0xFF29B6F6)],
    ),
    AiFilterModel(
      type: FilterType.faceDetection,
      name: 'Face AR',
      description: 'ML Kit face detection',
      icon: Icons.face_retouching_natural,
      gradientColors: [Color(0xFF4A148C), Color(0xFFCE93D8)],
      requiresMLKit: true,
    ),
  ];
}

class CapturedImageModel {
  final String path;
  final FilterType appliedFilter;
  final String filterName;
  final DateTime capturedAt;
  final int? detectedFaces;

  const CapturedImageModel({
    required this.path,
    required this.appliedFilter,
    required this.filterName,
    required this.capturedAt,
    this.detectedFaces,
  });

  Map<String, dynamic> toMap() => {
    'path': path,
    'filter': appliedFilter.name,
    'filterName': filterName,
    'capturedAt': capturedAt.toIso8601String(),
    'detectedFaces': detectedFaces,
  };

  factory CapturedImageModel.fromMap(Map<String, dynamic> map) =>
    CapturedImageModel(
      path: map['path'],
      appliedFilter: FilterType.values.firstWhere(
        (e) => e.name == map['filter'], orElse: () => FilterType.none),
      filterName: map['filterName'],
      capturedAt: DateTime.parse(map['capturedAt']),
      detectedFaces: map['detectedFaces'],
    );
}
