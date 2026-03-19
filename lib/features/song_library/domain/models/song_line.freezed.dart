// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'song_line.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SongLine {
  String get id => throw _privateConstructorUsedError;
  String get lyric => throw _privateConstructorUsedError;
  List<ChordEvent> get chords => throw _privateConstructorUsedError;

  /// Create a copy of SongLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SongLineCopyWith<SongLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongLineCopyWith<$Res> {
  factory $SongLineCopyWith(SongLine value, $Res Function(SongLine) then) =
      _$SongLineCopyWithImpl<$Res, SongLine>;
  @useResult
  $Res call({String id, String lyric, List<ChordEvent> chords});
}

/// @nodoc
class _$SongLineCopyWithImpl<$Res, $Val extends SongLine>
    implements $SongLineCopyWith<$Res> {
  _$SongLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SongLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? lyric = null, Object? chords = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            lyric: null == lyric
                ? _value.lyric
                : lyric // ignore: cast_nullable_to_non_nullable
                      as String,
            chords: null == chords
                ? _value.chords
                : chords // ignore: cast_nullable_to_non_nullable
                      as List<ChordEvent>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SongLineImplCopyWith<$Res>
    implements $SongLineCopyWith<$Res> {
  factory _$$SongLineImplCopyWith(
    _$SongLineImpl value,
    $Res Function(_$SongLineImpl) then,
  ) = __$$SongLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String lyric, List<ChordEvent> chords});
}

/// @nodoc
class __$$SongLineImplCopyWithImpl<$Res>
    extends _$SongLineCopyWithImpl<$Res, _$SongLineImpl>
    implements _$$SongLineImplCopyWith<$Res> {
  __$$SongLineImplCopyWithImpl(
    _$SongLineImpl _value,
    $Res Function(_$SongLineImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SongLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? lyric = null, Object? chords = null}) {
    return _then(
      _$SongLineImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        lyric: null == lyric
            ? _value.lyric
            : lyric // ignore: cast_nullable_to_non_nullable
                  as String,
        chords: null == chords
            ? _value._chords
            : chords // ignore: cast_nullable_to_non_nullable
                  as List<ChordEvent>,
      ),
    );
  }
}

/// @nodoc

class _$SongLineImpl extends _SongLine {
  const _$SongLineImpl({
    required this.id,
    required this.lyric,
    final List<ChordEvent> chords = const [],
  }) : _chords = chords,
       super._();

  @override
  final String id;
  @override
  final String lyric;
  final List<ChordEvent> _chords;
  @override
  @JsonKey()
  List<ChordEvent> get chords {
    if (_chords is EqualUnmodifiableListView) return _chords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chords);
  }

  @override
  String toString() {
    return 'SongLine(id: $id, lyric: $lyric, chords: $chords)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongLineImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lyric, lyric) || other.lyric == lyric) &&
            const DeepCollectionEquality().equals(other._chords, _chords));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    lyric,
    const DeepCollectionEquality().hash(_chords),
  );

  /// Create a copy of SongLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SongLineImplCopyWith<_$SongLineImpl> get copyWith =>
      __$$SongLineImplCopyWithImpl<_$SongLineImpl>(this, _$identity);
}

abstract class _SongLine extends SongLine {
  const factory _SongLine({
    required final String id,
    required final String lyric,
    final List<ChordEvent> chords,
  }) = _$SongLineImpl;
  const _SongLine._() : super._();

  @override
  String get id;
  @override
  String get lyric;
  @override
  List<ChordEvent> get chords;

  /// Create a copy of SongLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SongLineImplCopyWith<_$SongLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
