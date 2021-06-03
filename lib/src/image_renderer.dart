import 'dart:ui';
import 'package:flutter/painting.dart';
import 'package:vector_tile/vector_tile.dart';

import 'constants.dart';
import 'logger.dart';
import 'renderer.dart';
import 'themes/theme.dart';

class ImageRenderer {
  final Logger logger;
  final Theme theme;
  final int scale;

  ImageRenderer({required this.theme, required this.scale, Logger? logger})
      : this.logger = logger ?? Logger.noop() {
    assert(scale >= 1 && scale <= 4);
  }

  /// renders the given tile to an image
  ///
  /// [zoom] the current zoom level, which is used to filter theme layers
  ///        via `minzoom` and `maxzoom`. Value if provided must be >= 0 and <= 24
  Future<Image> render(VectorTile tile, {required double zoom}) {
    final recorder = PictureRecorder();
    int size = scale * tileSize;
    final canvas =
        Canvas(recorder, Rect.fromLTRB(0, 0, size.toDouble(), size.toDouble()));
    canvas.scale(scale.toDouble(), scale.toDouble());
    Renderer(theme: theme, logger: logger)
        .render(canvas, tile, zoomScaleFactor: 1.0, zoom: zoom);
    return recorder.endRecording().toImage(size, size);
  }
}
