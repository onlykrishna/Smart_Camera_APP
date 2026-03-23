// lib/app/data/services/face_detection_service.dart
//
// Wraps Google ML Kit Face Detection.
// Returns a list of FaceResult objects that the UI overlays as bounding boxes.
//
// IMPORTANT: Never process every camera frame.
// Always gate with _isProcessing to skip frames while one is in-flight.

import 'dart:io';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceResult {
  final double left;
  final double top;
  final double width;
  final double height;
  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;

  const FaceResult({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
  });

  /// Label shown inside the bounding box overlay.
  String get label {
    final parts = <String>[];
    if (smilingProbability != null && smilingProbability! > 0.7) {
      parts.add('😊 Smiling');
    }
    if (leftEyeOpenProbability != null && leftEyeOpenProbability! < 0.3) {
      parts.add('Left eye closed');
    }
    if (rightEyeOpenProbability != null && rightEyeOpenProbability! < 0.3) {
      parts.add('Right eye closed');
    }
    return parts.isEmpty ? 'Face detected' : parts.join(' · ');
  }
}

class FaceDetectionService extends GetxService {
  late final FaceDetector _detector;
  bool _isProcessing = false;

  @override
  void onInit() {
    super.onInit();
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,   // smile + eye open probability
        enableLandmarks: true,        // facial landmark points
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.1,
      ),
    );
  }

  @override
  void onClose() {
    _detector.close();
    super.onClose();
  }

  /// Detects faces in the image at [imagePath].
  /// Returns an empty list if detection is already in-progress (frame skip).
  Future<List<FaceResult>> detectFaces(String imagePath) async {
    // ─── Frame skip gate ───────────────────────────────────────────────────
    if (_isProcessing) return [];
    _isProcessing = true;

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _detector.processImage(inputImage);

      return faces.map((face) {
        final box = face.boundingBox;
        return FaceResult(
          left:   box.left,
          top:    box.top,
          width:  box.width,
          height: box.height,
          smilingProbability:        face.smilingProbability,
          leftEyeOpenProbability:    face.leftEyeOpenProbability,
          rightEyeOpenProbability:   face.rightEyeOpenProbability,
        );
      }).toList();
    } catch (e) {
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  /// Detects faces directly from a File.
  Future<List<FaceResult>> detectFacesFromFile(File file) {
    return detectFaces(file.path);
  }

  int get processingGateHits => _isProcessing ? 1 : 0;
}
