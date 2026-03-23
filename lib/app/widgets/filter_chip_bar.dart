// lib/app/widgets/filter_chip_bar.dart
// Used by FilterView only (CameraView has its own inline _FilterStrip).
// Shows real image thumbnails when available, gradient icon as fallback.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/ai_filter_model.dart';

class FilterChipBar extends StatelessWidget {
  final List<AiFilterModel>           filters;
  final Rx<AiFilterModel>             selected;
  final void Function(AiFilterModel)  onSelect;
  final RxMap<FilterType, Uint8List>? thumbnails;

  const FilterChipBar({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelect,
    this.thumbnails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      color: const Color(0xFF0D0D0D),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final filter = filters[i];
          return Obx(() {
            final isSelected = selected.value.type == filter.type;
            return GestureDetector(
              onTap: () => onSelect(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 64,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? filter.gradientColors.last
                        : Colors.white12,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildBg(filter, isSelected),
                      // Name label at bottom
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.45),
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            filter.name,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white60,
                              fontSize: 9,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildBg(AiFilterModel filter, bool isSelected) {
    // Real thumbnail takes priority
    final thumbBytes = thumbnails?[filter.type];
    if (thumbBytes != null) {
      return Image.memory(thumbBytes, fit: BoxFit.cover);
    }
    // Gradient + centered icon fallback
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? filter.gradientColors
              : [
            filter.gradientColors.first.withOpacity(0.4),
            filter.gradientColors.last.withOpacity(0.4),
          ],
        ),
      ),
      child: Icon(
        filter.icon,
        color: Colors.white.withOpacity(isSelected ? 1.0 : 0.6),
        size: 24,
      ),
    );
  }
}