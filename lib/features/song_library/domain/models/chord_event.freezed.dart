// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chord_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ChordEvent _$ChordEventFromJson(Map<String, dynamic> json) {
  return _ChordEvent.fromJson(json);
}

/// @nodoc
mixin _$ChordEvent {
  String get chord => throw _privateConstructorUsedError;
  int? get position => throw _privateConstructorUsedError;

  /// Serializes this ChordEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChordEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChordEventCopyWith<ChordEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChordEventCopyWith<$Res> {
  factory $ChordEventCopyWith(
    ChordEvent value,
    $Res Function(ChordEvent) then,
  ) = _$ChordEventCopyWithImpl<$Res, ChordEvent>;
  @useResult
  $Res call({String chord, int? position});
}

/// @nodoc
class _$ChordEventCopyWithImpl<$Res, $Val extends ChordEvent>
    implements $ChordEventCopyWith<$Res> {
  _$ChordEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChordEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? chord = null, Object? position = freezed}) {
    return _then(
      _value.copyWith(
            chord: null == chord
                ? _value.chord
                : chord // ignore: cast_nullable_to_non_nullable
                      as String,
            position: freezed == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChordEventImplCopyWith<$Res>
    implements $ChordEventCopyWith<$Res> {
  factory _$$ChordEventImplCopyWith(
    _$ChordEventImpl value,
    $Res Function(_$ChordEventImpl) then,
  ) = __$$ChordEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String chord, int? position});
}

/// @nodoc
class __$$ChordEventImplCopyWithImpl<$Res>
    extends _$ChordEventCopyWithImpl<$Res, _$ChordEventImpl>
    implements _$$ChordEventImplCopyWith<$Res> {
  __$$ChordEventImplCopyWithImpl(
    _$ChordEventImpl _value,
    $Res Function(_$ChordEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChordEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? chord = null, Object? position = freezed}) {
    return _then(
      _$ChordEventImpl(
        chord: null == chord
            ? _value.chord
            : chord // ignore: cast_nullable_to_non_nullable
                  as String,
        position: freezed == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChordEventImpl implements _ChordEvent {
  const _$ChordEventImpl({required this.chord, this.position});

  factory _$ChordEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChordEventImplFromJson(json);

  @override
  final String chord;
  @override
  final int? position;

  @override
  String toString() {
    return 'ChordEvent(chord: $chord, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChordEventImpl &&
            (identical(other.chord, chord) || other.chord == chord) &&
            (identical(other.position, position) ||
                other.position == position));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, chord, position);

  /// Create a copy of ChordEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChordEventImplCopyWith<_$ChordEventImpl> get copyWith =>
      __$$ChordEventImplCopyWithImpl<_$ChordEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChordEventImplToJson(this);
  }
}

abstract class _ChordEvent implements ChordEvent {
  const factory _ChordEvent({
    required final String chord,
    final int? position,
  }) = _$ChordEventImpl;

  factory _ChordEvent.fromJson(Map<String, dynamic> json) =
      _$ChordEventImpl.fromJson;

  @override
  String get chord;
  @override
  int? get position;

  /// Create a copy of ChordEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChordEventImplCopyWith<_$ChordEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
