import 'package:flutter/foundation.dart';

@immutable
final class MorphId {
  const MorphId(this.value);

  final Object value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MorphId &&
            runtimeType == other.runtimeType &&
            value == other.value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => 'MorphId($value)';
}
