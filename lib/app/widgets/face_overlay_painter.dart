// lib/app/widgets/face_overlay_painter.dart
// FIX: showLabels parameter wired to SettingsService.showFaceLabels

import 'package:flutter/material.dart';
import '../data/services/face_detection_service.dart';

class FaceOverlayPainter extends CustomPainter {
  final List<FaceResult> faces;
  final Size imageSize;
  final Size displaySize;
  final bool showLabels;   // ← wired to SettingsService.showFaceLabels

  const FaceOverlayPainter({
    required this.faces,
    required this.imageSize,
    required this.displaySize,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = displaySize.width  / imageSize.width;
    final scaleY = displaySize.height / imageSize.height;

    final boxPaint = Paint()
      ..color = const Color(0xFFCE93D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final fillPaint = Paint()
      ..color = const Color(0xFF4A148C).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (final face in faces) {
      final rect = Rect.fromLTWH(
        face.left  * scaleX,
        face.top   * scaleY,
        face.width * scaleX,
        face.height * scaleY,
      );
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rRect, fillPaint);
      canvas.drawRRect(rRect, boxPaint);
      _drawCorners(canvas, rect, boxPaint..color = Colors.white);

      // Only draw label when setting is ON
      if (showLabels && face.label.isNotEmpty) {
        _drawLabel(canvas, face.label, rect);
      }
    }
  }

  void _drawCorners(Canvas canvas, Rect rect, Paint paint) {
    const len = 14.0;
    final corners = [
      [Offset(rect.left, rect.top + len), rect.topLeft, Offset(rect.left + len, rect.top)],
      [Offset(rect.right - len, rect.top), rect.topRight, Offset(rect.right, rect.top + len)],
      [Offset(rect.left, rect.bottom - len), rect.bottomLeft, Offset(rect.left + len, rect.bottom)],
      [Offset(rect.right - len, rect.bottom), rect.bottomRight, Offset(rect.right, rect.bottom - len)],
    ];
    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint..strokeWidth = 3..style = PaintingStyle.stroke);
    }
  }

  void _drawLabel(Canvas canvas, String label, Rect rect) {
    final span = TextSpan(
      text: label,
      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
    );
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout(maxWidth: rect.width);
    final bgRect = Rect.fromLTWH(rect.left, rect.top - 20, painter.width + 12, 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF4A148C).withOpacity(0.85),
    );
    painter.paint(canvas, Offset(rect.left + 6, rect.top - 18));
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter old) =>
      old.faces != faces || old.displaySize != displaySize || old.showLabels != showLabels;
}