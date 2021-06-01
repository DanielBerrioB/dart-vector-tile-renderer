import 'package:vector_tile/vector_tile.dart';

abstract class LayerSelector {
  LayerSelector._();

  factory LayerSelector.none() = _NoneLayerSelector;
  factory LayerSelector.composite(List<LayerSelector> selectors) =
      _CompositeSelector;
  factory LayerSelector.any(List<LayerSelector> selectors) =
      _AnyCompositeSelector;
  factory LayerSelector.named(String name) = _NamedLayerSelector;
  factory LayerSelector.withProperty(String name,
      {required List<dynamic> values,
      required bool negated}) = _PropertyLayerSelector;
  factory LayerSelector.hasProperty(String name, {required bool negated}) =
      _HasPropertyLayerSelector;
  factory LayerSelector.comparingProperty(
          String name, ComparisonOperator op, num value) =
      _NumericComparisonLayerSelector;

  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers);

  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features);
}

enum ComparisonOperator {
  GREATER_THAN_OR_EQUAL_TO,
  LESS_THAN_OR_EQUAL_TO,
  GREATER_THAN,
  LESS_THAN
}

class _CompositeSelector extends LayerSelector {
  final List<LayerSelector> delegates;
  _CompositeSelector(this.delegates) : super._();

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) {
    Iterable<VectorTileLayer> result = tileLayers;
    delegates.forEach((delegate) {
      result = delegate.select(result);
    });
    return result;
  }

  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) {
    Iterable<VectorTileFeature> result = features;
    delegates.forEach((delegate) {
      result = delegate.features(result);
    });
    return result;
  }
}

class _AnyCompositeSelector extends LayerSelector {
  final List<LayerSelector> delegates;
  _AnyCompositeSelector(this.delegates) : super._();

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) {
    final Set<VectorTileLayer> selected = Set();
    for (final delegate in delegates) {
      selected.addAll(delegate.select(tileLayers));
    }
    return tileLayers.where((layer) => selected.contains(layer));
  }

  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) {
    final Set<VectorTileFeature> selected = Set();
    for (final delegate in delegates) {
      selected.addAll(delegate.features(features));
    }
    return features.where((layer) => selected.contains(layer));
  }
}

class _NamedLayerSelector extends LayerSelector {
  final String name;
  _NamedLayerSelector(this.name) : super._();

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) =>
      tileLayers.where((layer) => layer.name == name);

  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) =>
      features;
}

class _HasPropertyLayerSelector extends LayerSelector {
  final String name;
  final bool negated;
  _HasPropertyLayerSelector(this.name, {required this.negated}) : super._();

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) =>
      tileLayers;

  @override
  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) {
    return features.where((feature) {
      final properties = feature.decodeProperties();
      final hasProperty = properties.any((map) => map.keys.contains(name));
      return negated ? !hasProperty : hasProperty;
    });
  }
}

class _NumericComparisonLayerSelector extends LayerSelector {
  final String name;
  final ComparisonOperator op;
  final num value;
  _NumericComparisonLayerSelector(this.name, this.op, this.value) : super._() {
    if (name.startsWith('\$')) {
      throw Exception('Unsupported comparison property $name');
    }
  }

  @override
  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) {
    return features.where((feature) {
      final properties = feature.decodeProperties();
      return properties.any((map) => _matches(map[name]));
    });
  }

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) =>
      tileLayers;

  _matches(VectorTileValue? value) {
    final v = value?.dartIntValue?.toInt() ?? value?.dartDoubleValue;
    if (v == null) {
      return false;
    }
    switch (op) {
      case ComparisonOperator.GREATER_THAN_OR_EQUAL_TO:
        return v >= this.value;
      case ComparisonOperator.LESS_THAN_OR_EQUAL_TO:
        return v >= this.value;
      case ComparisonOperator.LESS_THAN:
        return v < this.value;
      case ComparisonOperator.GREATER_THAN:
        return v > this.value;
    }
  }
}

class _PropertyLayerSelector extends LayerSelector {
  final String name;
  final List<dynamic> values;
  final bool negated;
  _PropertyLayerSelector(this.name,
      {required this.values, required this.negated})
      : super._();

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) =>
      tileLayers;

  @override
  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) {
    return features.where((feature) {
      if (name == '\$type') {
        return _matchesType(feature);
      }
      final properties = feature.decodeProperties();
      return properties.any((map) => _matches(map[name]));
    });
  }

  bool _matchesType(VectorTileFeature feature) {
    final typeName = _typeName(feature.geometryType);
    return values.contains(typeName);
  }

  String _typeName(GeometryType? geometryType) {
    if (geometryType == null) {
      return '<none>';
    }
    switch (geometryType) {
      case GeometryType.Point:
        return 'Point';
      case GeometryType.LineString:
        return 'LineString';
      case GeometryType.Polygon:
        return 'Polygon';
      case GeometryType.MultiPoint:
        return 'MultiPoint';
      case GeometryType.MultiLineString:
        return 'MultiLineString';
      case GeometryType.MultiPolygon:
        return 'MultiPolygon';
    }
  }

  bool _matches(VectorTileValue? value) {
    if (value == null) {
      return negated ? true : false;
    }
    final v = value.dartStringValue ??
        value.dartIntValue?.toInt() ??
        value.dartDoubleValue ??
        value.dartBoolValue;
    final match = v == null ? false : values.contains(v);
    return negated ? !match : match;
  }
}

class _NoneLayerSelector extends LayerSelector {
  _NoneLayerSelector() : super._();

  @override
  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) =>
      [];

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) => [];
}
