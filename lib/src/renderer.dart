import 'dart:ui';

import 'package:dart_vector_tile_renderer/renderer.dart';

import 'package:vector_tile/vector_tile.dart';

import 'features/feature_renderer.dart';
import 'logger.dart';

class Renderer {
  final Theme theme;
  final LayerFilter layerFilter;
  final Logger logger;
  final FeatureDispatcher featureRenderer;

  Renderer({required this.theme, required this.layerFilter, Logger? logger})
      : this.logger = logger ?? Logger.noop(),
        featureRenderer = FeatureDispatcher(logger ?? Logger.noop());

  void render(Canvas canvas, VectorTile tile) {
    _filteredLayers(tile).forEach((layer) {
      _renderLayer(canvas, layer);
    });
  }

  void _renderLayer(Canvas canvas, VectorTileLayer layer) {
    logger.log(() => 'rendering layer ${layer.name}');
    layer.features.forEach((feature) {
      featureRenderer.render(canvas, theme, layer, feature);
    });
  }

  Iterable<VectorTileLayer> _filteredLayers(VectorTile tile) =>
      tile.layers.where((layer) {
        final matches = layerFilter.matches(layer);
        if (!matches) {
          logger.log(() => 'skipping layer ${layer.name}');
        }
        return matches;
      });
}
