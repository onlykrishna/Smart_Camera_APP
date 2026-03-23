// lib/app/data/services/filter_service.dart
//
// The FilterService owns all image-processing logic.
// It applies pixel-level operations using the `image` package and
// exposes a single applyFilter() entry-point consumed by FilterController.
//
// Filter pipeline:
//   Raw bytes → img.Image → pixel transform → PNG encode → Uint8List

// lib/app/data/services/filter_service.dart
//
// ALL filter processing runs inside a Dart isolate via Flutter's compute().
// This keeps the UI thread free — no jank, no ANR on heavy images.
//
// image package v4 API notes:
//   • p.r / p.g / p.b return `num`. Always call .toInt() / .toDouble().
//   • img.encodePng() is slow on large images; use encodeJpg() instead.

import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // compute()
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import '../models/ai_filter_model.dart';

// ── Top-level functions required by compute() ─────────────────────────────────

Uint8List _isolateApplyFilter(Map<String, dynamic> args) {
  final bytes      = args['bytes']  as Uint8List;
  final filterName = args['filter'] as String;
  final filterType = FilterType.values.firstWhere(
        (e) => e.name == filterName,
    orElse: () => FilterType.none,
  );
  return _runFilter(bytes, filterType);
}

Uint8List _isolateGenerateThumbnail(Map<String, dynamic> args) {
  final bytes      = args['bytes']  as Uint8List;
  final filterName = args['filter'] as String;
  final size       = args['size']   as int;
  final filterType = FilterType.values.firstWhere(
        (e) => e.name == filterName,
    orElse: () => FilterType.none,
  );
  final src   = img.decodeImage(bytes);
  if (src == null) return bytes;
  final thumb      = img.copyResizeCropSquare(src, size: size);
  final thumbBytes = Uint8List.fromList(img.encodeJpg(thumb, quality: 85));
  return _runFilter(thumbBytes, filterType);
}

/// Pure dispatcher — safe to run in any isolate.
Uint8List _runFilter(Uint8List imageBytes, FilterType filterType) {
  final src = img.decodeImage(imageBytes);
  if (src == null) return imageBytes;

  img.Image result;
  switch (filterType) {
    case FilterType.none:          result = src;               break;
    case FilterType.grayscale:     result = _grayscale(src);   break;
    case FilterType.vintage:       result = _vintage(src);     break;
    case FilterType.sepia:         result = _sepia(src);       break;
    case FilterType.edgeDetection: result = _edgeDetection(src); break;
    case FilterType.cartoon:       result = _cartoon(src);     break;
    case FilterType.sketch:        result = _sketch(src);      break;
    case FilterType.warmth:        result = _warmth(src);      break;
    case FilterType.cool:          result = _cool(src);        break;
    case FilterType.faceDetection: result = src;               break;
  }
  // JPEG is ~10x faster to encode than PNG for large images.
  return Uint8List.fromList(img.encodeJpg(result, quality: 92));
}

// ── Pure filter functions ─────────────────────────────────────────────────────

img.Image _grayscale(img.Image src) {
  final out = img.Image(width: src.width, height: src.height);
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final p   = src.getPixel(x, y);
      final lum = (0.299 * p.r.toDouble() +
          0.587 * p.g.toDouble() +
          0.114 * p.b.toDouble()).round().clamp(0, 255);
      out.setPixelRgba(x, y, lum, lum, lum, p.a.toInt());
    }
  }
  return out;
}

img.Image _vintage(img.Image src) {
  final out = img.Image(width: src.width, height: src.height);
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      int r = (p.r.toInt() * 1.1 + 20).round().clamp(0, 255);
      int g = (p.g.toInt() * 0.95 + 10).round().clamp(0, 255);
      int b = (p.b.toInt() * 0.80).round().clamp(0, 255);
      final lum = (0.299 * r + 0.587 * g + 0.114 * b).round();
      r = (r * 0.7 + lum * 0.3).round().clamp(0, 255);
      g = (g * 0.7 + lum * 0.3).round().clamp(0, 255);
      b = (b * 0.7 + lum * 0.3).round().clamp(0, 255);
      out.setPixelRgba(x, y, r, g, b, p.a.toInt());
    }
  }
  return out;
}

img.Image _sepia(img.Image src) {
  final out = img.Image(width: src.width, height: src.height);
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final p  = src.getPixel(x, y);
      final r  = p.r.toDouble();
      final g  = p.g.toDouble();
      final b  = p.b.toDouble();
      out.setPixelRgba(x, y,
        (r * 0.393 + g * 0.769 + b * 0.189).round().clamp(0, 255),
        (r * 0.349 + g * 0.686 + b * 0.168).round().clamp(0, 255),
        (r * 0.272 + g * 0.534 + b * 0.131).round().clamp(0, 255),
        p.a.toInt(),
      );
    }
  }
  return out;
}

img.Image _edgeDetection(img.Image src) {
  final gray = _grayscale(src);
  final out  = img.Image(width: src.width, height: src.height);
  const kx = [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]];
  const ky = [[-1, -2, -1], [0, 0, 0], [1, 2, 1]];

  for (int y = 1; y < src.height - 1; y++) {
    for (int x = 1; x < src.width - 1; x++) {
      double gx = 0, gy = 0;
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final px = gray.getPixel(x + dx, y + dy).r.toDouble();
          gx += px * kx[dy + 1][dx + 1];
          gy += px * ky[dy + 1][dx + 1];
        }
      }
      final mag = (gx.abs() + gy.abs()).clamp(0.0, 255.0).round();
      out.setPixelRgba(x, y, mag, mag, mag, 255);
    }
  }
  return out;
}

img.Image _cartoon(img.Image src) {
  final smooth    = img.gaussianBlur(src, radius: 3);
  const step      = 255 ~/ 4;
  final quantized = img.Image(width: src.width, height: src.height);

  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final p = smooth.getPixel(x, y);
      quantized.setPixelRgba(x, y,
        ((p.r.toInt() ~/ step) * step).clamp(0, 255),
        ((p.g.toInt() ~/ step) * step).clamp(0, 255),
        ((p.b.toInt() ~/ step) * step).clamp(0, 255),
        p.a.toInt(),
      );
    }
  }

  final edges = _edgeDetection(src);
  final out   = img.Image(width: src.width, height: src.height);
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      if (edges.getPixel(x, y).r.toDouble() > 80) {
        out.setPixelRgba(x, y, 0, 0, 0, 255);
      } else {
        final c = quantized.getPixel(x, y);
        out.setPixelRgba(x, y, c.r.toInt(), c.g.toInt(), c.b.toInt(), 255);
      }
    }
  }
  return out;
}

img.Image _sketch(img.Image src) {
  final edges = _edgeDetection(src);
  final out   = img.Image(width: src.width, height: src.height);
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final v = (255 - edges.getPixel(x, y).r.toInt()).clamp(0, 255);
      out.setPixelRgba(x, y, v, v, v, 255);
    }
  }
  return out;
}

img.Image _warmth(img.Image src) {
  final out = img.Image(width: src.width, height: src.height);
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      out.setPixelRgba(x, y,
        (p.r.toInt() + 30).clamp(0, 255),
        (p.g.toInt() + 10).clamp(0, 255),
        (p.b.toInt() - 20).clamp(0, 255),
        p.a.toInt(),
      );
    }
  }
  return out;
}

img.Image _cool(img.Image src) {
  final out = img.Image(width: src.width, height: src.height);
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      out.setPixelRgba(x, y,
        (p.r.toInt() - 20).clamp(0, 255),
        (p.g.toInt() + 5).clamp(0, 255),
        (p.b.toInt() + 30).clamp(0, 255),
        p.a.toInt(),
      );
    }
  }
  return out;
}

// ── Service ───────────────────────────────────────────────────────────────────

class FilterService extends GetxService {
  /// Applies [filterType] off the UI thread via compute().
  Future<Uint8List> applyFilter(
      Uint8List imageBytes,
      FilterType filterType,
      ) {
    return compute(_isolateApplyFilter, {
      'bytes':  imageBytes,
      'filter': filterType.name,
    });
  }

  /// Generates a [size]×[size] thumbnail with [filterType] applied, off-thread.
  Future<Uint8List> generateThumbnail(
      Uint8List imageBytes,
      FilterType filterType, {
        int size = 80,
      }) {
    return compute(_isolateGenerateThumbnail, {
      'bytes':  imageBytes,
      'filter': filterType.name,
      'size':   size,
    });
  }
}