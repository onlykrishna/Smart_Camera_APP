// lib/app/data/services/live_filter_service.dart
//
// KEY FIXES:
//  1. Android sensor delivers YUV frames in LANDSCAPE orientation.
//     We rotate 90° CW after conversion so the preview fills portrait correctly.
//  2. Plane row-stride is respected in YUV conversion (was causing pixel shift).
//  3. BGRA path also rotates when sensorOrientation != 0.

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/ai_filter_model.dart';

const int _bgra8888Code = 3;

// ── Isolate entry point ───────────────────────────────────────────────────────

Uint8List _processFrameIsolate(Map<String, dynamic> args) {
  final planes            = args['planes']         as List<Map<String, dynamic>>;
  final width             = args['width']          as int;
  final height            = args['height']         as int;
  final format            = args['format']         as int;
  final filterName        = args['filter']         as String;
  final sensorOrientation = args['sensorOrientation'] as int; // 0/90/180/270

  img.Image? src;

  if (format == _bgra8888Code) {
    // iOS / emulator — BGRA packed
    final bytes = planes[0]['bytes'] as Uint8List;
    src = img.Image.fromBytes(
      width:  width,
      height: height,
      bytes:  bytes.buffer,
      order:  img.ChannelOrder.bgra,
    );
  } else {
    // Android physical device — YUV420 planar
    src = _convertYuv420(planes, width, height);
  }

  if (src == null) return Uint8List(0);

  // ── Rotate to match portrait display ──────────────────────────────────────
  // Android sensors output landscape frames; sensorOrientation tells us
  // how many degrees to rotate to get upright portrait.
  if (sensorOrientation == 90) {
    src = img.copyRotate(src, angle: 90);
  } else if (sensorOrientation == 270) {
    src = img.copyRotate(src, angle: -90);
  } else if (sensorOrientation == 180) {
    src = img.copyRotate(src, angle: 180);
  }

  // ── Apply filter ──────────────────────────────────────────────────────────
  final filterType = FilterType.values.firstWhere(
        (e) => e.name == filterName,
    orElse: () => FilterType.none,
  );
  final filtered = _applyLiveFilter(src!, filterType);

  return Uint8List.fromList(img.encodeJpg(filtered, quality: 65));
}

// ── YUV420 → RGB (row-stride aware) ──────────────────────────────────────────

img.Image _convertYuv420(
    List<Map<String, dynamic>> planes, int width, int height) {
  final out = img.Image(width: width, height: height);

  final yBytes  = planes[0]['bytes']      as Uint8List;
  final uBytes  = planes[1]['bytes']      as Uint8List;
  final vBytes  = planes[2]['bytes']      as Uint8List;
  final yStride = planes[0]['rowStride']  as int;
  final uvRowStride   = planes[1]['rowStride']   as int;
  final uvPixelStride = planes[1]['pixelStride'] as int;

  for (int row = 0; row < height; row++) {
    for (int col = 0; col < width; col++) {
      // Y index respects row stride (may differ from width on some devices)
      final yIndex  = row * yStride + col;
      final uvIndex = (row ~/ 2) * uvRowStride + (col ~/ 2) * uvPixelStride;

      if (yIndex >= yBytes.length ||
          uvIndex >= uBytes.length ||
          uvIndex >= vBytes.length) continue;

      final yp = yBytes[yIndex].toDouble();
      final up = uBytes[uvIndex].toDouble();
      final vp = vBytes[uvIndex].toDouble();

      // BT.601 limited-range YCbCr → RGB
      final r = (yp + 1.370705 * (vp - 128)).round().clamp(0, 255);
      final g = (yp - 0.337633 * (up - 128) - 0.698001 * (vp - 128))
          .round().clamp(0, 255);
      final b = (yp + 1.732446 * (up - 128)).round().clamp(0, 255);

      out.setPixelRgba(col, row, r, g, b, 255);
    }
  }
  return out;
}

// ── Filter dispatcher ─────────────────────────────────────────────────────────

img.Image _applyLiveFilter(img.Image src, FilterType type) {
  switch (type) {
    case FilterType.grayscale:     return _grayscale(src);
    case FilterType.sepia:         return _sepia(src);
    case FilterType.vintage:       return _vintage(src);
    case FilterType.edgeDetection: return _edgeDetection(src);
    case FilterType.cartoon:       return _cartoon(src);
    case FilterType.sketch:        return _sketch(src);
    case FilterType.warmth:        return _warmth(src);
    case FilterType.cool:          return _cool(src);
    default:                       return src;
  }
}

img.Image _grayscale(img.Image s) {
  final o = img.Image(width: s.width, height: s.height);
  for (int y = 0; y < s.height; y++)
    for (int x = 0; x < s.width; x++) {
      final p = s.getPixel(x, y);
      final l = (0.299*p.r.toDouble()+0.587*p.g.toDouble()+0.114*p.b.toDouble()).round().clamp(0,255);
      o.setPixelRgba(x, y, l, l, l, 255);
    }
  return o;
}

img.Image _sepia(img.Image s) {
  final o = img.Image(width: s.width, height: s.height);
  for (int y = 0; y < s.height; y++)
    for (int x = 0; x < s.width; x++) {
      final p = s.getPixel(x, y);
      final r=p.r.toDouble(); final g=p.g.toDouble(); final b=p.b.toDouble();
      o.setPixelRgba(x,y,(r*.393+g*.769+b*.189).round().clamp(0,255),
          (r*.349+g*.686+b*.168).round().clamp(0,255),
          (r*.272+g*.534+b*.131).round().clamp(0,255),255);
    }
  return o;
}

img.Image _vintage(img.Image s) {
  final o = img.Image(width: s.width, height: s.height);
  for (int y = 0; y < s.height; y++)
    for (int x = 0; x < s.width; x++) {
      final p = s.getPixel(x, y);
      int r=(p.r.toInt()*1.1+20).round().clamp(0,255);
      int g=(p.g.toInt()*.95+10).round().clamp(0,255);
      int b=(p.b.toInt()*.80).round().clamp(0,255);
      final l=(0.299*r+0.587*g+0.114*b).round();
      o.setPixelRgba(x,y,(r*.7+l*.3).round().clamp(0,255),
          (g*.7+l*.3).round().clamp(0,255),(b*.7+l*.3).round().clamp(0,255),255);
    }
  return o;
}

img.Image _edgeDetection(img.Image s) {
  final gray=_grayscale(s); final o=img.Image(width:s.width,height:s.height);
  const kx=[[-1,0,1],[-2,0,2],[-1,0,1]]; const ky=[[-1,-2,-1],[0,0,0],[1,2,1]];
  for(int y=1;y<s.height-1;y++) for(int x=1;x<s.width-1;x++){
    double gx=0,gy=0;
    for(int dy=-1;dy<=1;dy++) for(int dx=-1;dx<=1;dx++){
      final px=gray.getPixel(x+dx,y+dy).r.toDouble();
      gx+=px*kx[dy+1][dx+1]; gy+=px*ky[dy+1][dx+1];
    }
    final m=(gx.abs()+gy.abs()).clamp(0.0,255.0).round();
    o.setPixelRgba(x,y,m,m,m,255);
  }
  return o;
}

img.Image _cartoon(img.Image s) {
  final sm=img.gaussianBlur(s,radius:2); const step=255~/4;
  final q=img.Image(width:s.width,height:s.height);
  for(int y=0;y<s.height;y++) for(int x=0;x<s.width;x++){
    final p=sm.getPixel(x,y);
    q.setPixelRgba(x,y,((p.r.toInt()~/step)*step).clamp(0,255),
        ((p.g.toInt()~/step)*step).clamp(0,255),
        ((p.b.toInt()~/step)*step).clamp(0,255),255);
  }
  final e=_edgeDetection(s); final o=img.Image(width:s.width,height:s.height);
  for(int y=0;y<s.height;y++) for(int x=0;x<s.width;x++){
    if(e.getPixel(x,y).r.toDouble()>80){ o.setPixelRgba(x,y,0,0,0,255); }
    else{ final c=q.getPixel(x,y); o.setPixelRgba(x,y,c.r.toInt(),c.g.toInt(),c.b.toInt(),255); }
  }
  return o;
}

img.Image _sketch(img.Image s) {
  final e=_edgeDetection(s); final o=img.Image(width:s.width,height:s.height);
  for(int y=0;y<s.height;y++) for(int x=0;x<s.width;x++){
    final v=(255-e.getPixel(x,y).r.toInt()).clamp(0,255);
    o.setPixelRgba(x,y,v,v,v,255);
  }
  return o;
}

img.Image _warmth(img.Image s) {
  final o=img.Image(width:s.width,height:s.height);
  for(int y=0;y<s.height;y++) for(int x=0;x<s.width;x++){
    final p=s.getPixel(x,y);
    o.setPixelRgba(x,y,(p.r.toInt()+30).clamp(0,255),
        (p.g.toInt()+10).clamp(0,255),(p.b.toInt()-20).clamp(0,255),255);
  }
  return o;
}

img.Image _cool(img.Image s) {
  final o=img.Image(width:s.width,height:s.height);
  for(int y=0;y<s.height;y++) for(int x=0;x<s.width;x++){
    final p=s.getPixel(x,y);
    o.setPixelRgba(x,y,(p.r.toInt()-20).clamp(0,255),
        (p.g.toInt()+5).clamp(0,255),(p.b.toInt()+30).clamp(0,255),255);
  }
  return o;
}

// ── Service ───────────────────────────────────────────────────────────────────

class LiveFilterService {
  bool _isProcessing = false;

  Future<Uint8List?> processFrame(
      CameraImage frame,
      FilterType filterType,
      int sensorOrientation,
      ) async {
    if (_isProcessing) return null;
    _isProcessing = true;
    try {
      final planes = frame.planes.map((p) => {
        'bytes':       p.bytes,
        'rowStride':   p.bytesPerRow,
        'pixelStride': p.bytesPerPixel ?? 1,
      }).toList();

      final formatCode = frame.format.group == ImageFormatGroup.bgra8888
          ? _bgra8888Code : 0;

      final result = await compute(_processFrameIsolate, {
        'planes':             planes,
        'width':              frame.width,
        'height':             frame.height,
        'format':             formatCode,
        'filter':             filterType.name,
        'sensorOrientation':  sensorOrientation,
      });

      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    } finally {
      _isProcessing = false;
    }
  }
}