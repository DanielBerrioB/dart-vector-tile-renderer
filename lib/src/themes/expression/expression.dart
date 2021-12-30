export 'expression_parser.dart';

import 'package:vector_tile/vector_tile.dart';

import '../../logger.dart';

class EvaluationContext {
  final List<Map<String, VectorTileValue>> Function() _properties;
  final Logger logger;

  EvaluationContext(this._properties, this.logger);

  getProperty(String name) {
    final properties = _properties();
    for (final property in properties) {
      final value = property[name];
      if (value != null) {
        return value.dartStringValue ??
            value.dartIntValue?.toInt() ??
            value.dartDoubleValue ??
            value.dartBoolValue;
      }
    }
  }
}

abstract class Expression {
  evaluate(EvaluationContext context);
}

class UnsupportedExpression extends Expression {
  final dynamic _json;

  UnsupportedExpression(this._json);

  get json => _json;

  @override
  evaluate(EvaluationContext context) => null;
}

class NotNullExpression extends Expression {
  final Expression _delegate;

  NotNullExpression(this._delegate);

  @override
  evaluate(EvaluationContext context) => _delegate.evaluate(context) != null;
}

class NotExpression extends Expression {
  final Expression _delegate;

  NotExpression(this._delegate);

  @override
  evaluate(EvaluationContext context) {
    final operand = _delegate.evaluate(context);
    if (operand is bool) {
      return !operand;
    }
    context.logger.warn(() => 'NotExpression expected bool but got $operand');
    return null;
  }
}
