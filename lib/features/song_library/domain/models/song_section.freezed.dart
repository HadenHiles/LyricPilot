// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'song_section.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SongSection {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  SectionType get type => throw _privateConstructorUsedError;
  List<SongLine> get lines => throw _privateConstructorUsedError;

  /// Create a copy of SongSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SongSectionCopyWith<SongSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongSectionCopyWith<$Res> {
  factory $SongSectionCopyWith(
    SongSection value,
    $Res Function(SongSection) then,
  ) = _$SongSectionCopyWithImpl<$Res, SongSection>;
  @useResult
  $Res call({String id, String name, SectionType type, List<SongLine> lines});
}

/// @nodoc
class _$SongSectionCopyWithImpl<$Res, $Val extends SongSection>
    implements $SongSectionCopyWith<$Res> {
  _$SongSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SongSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? lines = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as SectionType,
            lines: null == lines
                ? _value.lines
                : lines // ignore: cast_nullable_to_non_nullable
                      as List<SongLine>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SongSectionImplCopyWith<$Res>
    implements $SongSectionCopyWith<$Res> {
  factory _$$SongSectionImplCopyWith(
    _$SongSectionImpl value,
    $Res Function(_$SongSectionImpl) then,
  ) = __$$SongSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, SectionType type, List<SongLine> lines});
}

/// @nodoc
class __$$SongSectionImplCopyWithImpl<$Res>
    extends _$SongSectionCopyWithImpl<$Res, _$SongSectionImpl>
    implements _$$SongSectionImplCopyWith<$Res> {
  __$$SongSectionImplCopyWithImpl(
    _$SongSectionImpl _value,
    $Res Function(_$SongSectionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SongSection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? lines = null,
  }) {
    return _then(
      _$SongSectionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as SectionType,
        lines: null == lines
            ? _value._lines
            : lines // ignore: cast_nullable_to_non_nullable
                  as List<SongLine>,
      ),
    );
  }
}

/// @nodoc

class _$SongSectionImpl extends _SongSection {
  const _$SongSectionImpl({
    required this.id,
    required this.name,
    required this.type,
    final List<SongLine> lines = const [],
  }) : _lines = lines,
       super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final SectionType type;
  final List<SongLine> _lines;
  @override
  @JsonKey()
  List<SongLine> get lines {
    if (_lines is EqualUnmodifiableListView) return _lines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lines);
  }

  @override
  String toString() {
    return 'SongSection(id: $id, name: $name, type: $type, lines: $lines)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongSectionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._lines, _lines));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    type,
    const DeepCollectionEquality().hash(_lines),
  );

  /// Create a copy of SongSection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SongSectionImplCopyWith<_$SongSectionImpl> get copyWith =>
      __$$SongSectionImplCopyWithImpl<_$SongSectionImpl>(this, _$identity);
}

abstract class _SongSection extends SongSection {
  const factory _SongSection({
    required final String id,
    required final String name,
    required final SectionType type,
    final List<SongLine> lines,
  }) = _$SongSectionImpl;
  const _SongSection._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  SectionType get type;
  @override
  List<SongLine> get lines;

  /// Create a copy of SongSection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SongSectionImplCopyWith<_$SongSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
