import 'dart:ui';

import 'package:vector_tile/vector_tile.dart';

import 'features/feature_renderer.dart';
import 'logger.dart';

class Context {
  final Logger logger;
  final Canvas canvas;
  final FeatureDispatcher featureRenderer;
  final VectorTile tile;

  Context(this.logger, this.canvas, this.featureRenderer, this.tile);
}
