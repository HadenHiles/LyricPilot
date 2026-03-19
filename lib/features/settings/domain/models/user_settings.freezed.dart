// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UserSettings {
  // --- Display (Phase 3) ---
  double get fontSize => throw _privateConstructorUsedError;
  double get lineSpacing => throw _privateConstructorUsedError;
  bool get keepScreenAwake =>
      throw _privateConstructorUsedError; // --- Scroll (Phase 4) ---
  // TODO(phase-4): wire up in scroll engine
  bool get autoScrollEnabled => throw _privateConstructorUsedError;
  double get scrollSpeedMultiplier =>
      throw _privateConstructorUsedError; // --- Audio (Phase 5) ---
  // TODO(phase-5): wire up in audio analyzer
  bool get audioFollowingEnabled => throw _privateConstructorUsedError;
  double get audioSensitivity => throw _privateConstructorUsedError;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserSettingsCopyWith<UserSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsCopyWith<$Res> {
  factory $UserSettingsCopyWith(
    UserSettings value,
    $Res Function(UserSettings) then,
  ) = _$UserSettingsCopyWithImpl<$Res, UserSettings>;
  @useResult
  $Res call({
    double fontSize,
    double lineSpacing,
    bool keepScreenAwake,
    bool autoScrollEnabled,
    double scrollSpeedMultiplier,
    bool audioFollowingEnabled,
    double audioSensitivity,
  });
}

/// @nodoc
class _$UserSettingsCopyWithImpl<$Res, $Val extends UserSettings>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fontSize = null,
    Object? lineSpacing = null,
    Object? keepScreenAwake = null,
    Object? autoScrollEnabled = null,
    Object? scrollSpeedMultiplier = null,
    Object? audioFollowingEnabled = null,
    Object? audioSensitivity = null,
  }) {
    return _then(
      _value.copyWith(
            fontSize: null == fontSize
                ? _value.fontSize
                : fontSize // ignore: cast_nullable_to_non_nullable
                      as double,
            lineSpacing: null == lineSpacing
                ? _value.lineSpacing
                : lineSpacing // ignore: cast_nullable_to_non_nullable
                      as double,
            keepScreenAwake: null == keepScreenAwake
                ? _value.keepScreenAwake
                : keepScreenAwake // ignore: cast_nullable_to_non_nullable
                      as bool,
            autoScrollEnabled: null == autoScrollEnabled
                ? _value.autoScrollEnabled
                : autoScrollEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            scrollSpeedMultiplier: null == scrollSpeedMultiplier
                ? _value.scrollSpeedMultiplier
                : scrollSpeedMultiplier // ignore: cast_nullable_to_non_nullable
                      as double,
            audioFollowingEnabled: null == audioFollowingEnabled
                ? _value.audioFollowingEnabled
                : audioFollowingEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            audioSensitivity: null == audioSensitivity
                ? _value.audioSensitivity
                : audioSensitivity // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserSettingsImplCopyWith<$Res>
    implements $UserSettingsCopyWith<$Res> {
  factory _$$UserSettingsImplCopyWith(
    _$UserSettingsImpl value,
    $Res Function(_$UserSettingsImpl) then,
  ) = __$$UserSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double fontSize,
    double lineSpacing,
    bool keepScreenAwake,
    bool autoScrollEnabled,
    double scrollSpeedMultiplier,
    bool audioFollowingEnabled,
    double audioSensitivity,
  });
}

/// @nodoc
class __$$UserSettingsImplCopyWithImpl<$Res>
    extends _$UserSettingsCopyWithImpl<$Res, _$UserSettingsImpl>
    implements _$$UserSettingsImplCopyWith<$Res> {
  __$$UserSettingsImplCopyWithImpl(
    _$UserSettingsImpl _value,
    $Res Function(_$UserSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fontSize = null,
    Object? lineSpacing = null,
    Object? keepScreenAwake = null,
    Object? autoScrollEnabled = null,
    Object? scrollSpeedMultiplier = null,
    Object? audioFollowingEnabled = null,
    Object? audioSensitivity = null,
  }) {
    return _then(
      _$UserSettingsImpl(
        fontSize: null == fontSize
            ? _value.fontSize
            : fontSize // ignore: cast_nullable_to_non_nullable
                  as double,
        lineSpacing: null == lineSpacing
            ? _value.lineSpacing
            : lineSpacing // ignore: cast_nullable_to_non_nullable
                  as double,
        keepScreenAwake: null == keepScreenAwake
            ? _value.keepScreenAwake
            : keepScreenAwake // ignore: cast_nullable_to_non_nullable
                  as bool,
        autoScrollEnabled: null == autoScrollEnabled
            ? _value.autoScrollEnabled
            : autoScrollEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        scrollSpeedMultiplier: null == scrollSpeedMultiplier
            ? _value.scrollSpeedMultiplier
            : scrollSpeedMultiplier // ignore: cast_nullable_to_non_nullable
                  as double,
        audioFollowingEnabled: null == audioFollowingEnabled
            ? _value.audioFollowingEnabled
            : audioFollowingEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        audioSensitivity: null == audioSensitivity
            ? _value.audioSensitivity
            : audioSensitivity // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$UserSettingsImpl implements _UserSettings {
  const _$UserSettingsImpl({
    this.fontSize = 20.0,
    this.lineSpacing = 1.5,
    this.keepScreenAwake = true,
    this.autoScrollEnabled = false,
    this.scrollSpeedMultiplier = 1.0,
    this.audioFollowingEnabled = false,
    this.audioSensitivity = 0.5,
  });

  // --- Display (Phase 3) ---
  @override
  @JsonKey()
  final double fontSize;
  @override
  @JsonKey()
  final double lineSpacing;
  @override
  @JsonKey()
  final bool keepScreenAwake;
  // --- Scroll (Phase 4) ---
  // TODO(phase-4): wire up in scroll engine
  @override
  @JsonKey()
  final bool autoScrollEnabled;
  @override
  @JsonKey()
  final double scrollSpeedMultiplier;
  // --- Audio (Phase 5) ---
  // TODO(phase-5): wire up in audio analyzer
  @override
  @JsonKey()
  final bool audioFollowingEnabled;
  @override
  @JsonKey()
  final double audioSensitivity;

  @override
  String toString() {
    return 'UserSettings(fontSize: $fontSize, lineSpacing: $lineSpacing, keepScreenAwake: $keepScreenAwake, autoScrollEnabled: $autoScrollEnabled, scrollSpeedMultiplier: $scrollSpeedMultiplier, audioFollowingEnabled: $audioFollowingEnabled, audioSensitivity: $audioSensitivity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsImpl &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize) &&
            (identical(other.lineSpacing, lineSpacing) ||
                other.lineSpacing == lineSpacing) &&
            (identical(other.keepScreenAwake, keepScreenAwake) ||
                other.keepScreenAwake == keepScreenAwake) &&
            (identical(other.autoScrollEnabled, autoScrollEnabled) ||
                other.autoScrollEnabled == autoScrollEnabled) &&
            (identical(other.scrollSpeedMultiplier, scrollSpeedMultiplier) ||
                other.scrollSpeedMultiplier == scrollSpeedMultiplier) &&
            (identical(other.audioFollowingEnabled, audioFollowingEnabled) ||
                other.audioFollowingEnabled == audioFollowingEnabled) &&
            (identical(other.audioSensitivity, audioSensitivity) ||
                other.audioSensitivity == audioSensitivity));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    fontSize,
    lineSpacing,
    keepScreenAwake,
    autoScrollEnabled,
    scrollSpeedMultiplier,
    audioFollowingEnabled,
    audioSensitivity,
  );

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      __$$UserSettingsImplCopyWithImpl<_$UserSettingsImpl>(this, _$identity);
}

abstract class _UserSettings implements UserSettings {
  const factory _UserSettings({
    final double fontSize,
    final double lineSpacing,
    final bool keepScreenAwake,
    final bool autoScrollEnabled,
    final double scrollSpeedMultiplier,
    final bool audioFollowingEnabled,
    final double audioSensitivity,
  }) = _$UserSettingsImpl;

  // --- Display (Phase 3) ---
  @override
  double get fontSize;
  @override
  double get lineSpacing;
  @override
  bool get keepScreenAwake; // --- Scroll (Phase 4) ---
  // TODO(phase-4): wire up in scroll engine
  @override
  bool get autoScrollEnabled;
  @override
  double get scrollSpeedMultiplier; // --- Audio (Phase 5) ---
  // TODO(phase-5): wire up in audio analyzer
  @override
  bool get audioFollowingEnabled;
  @override
  double get audioSensitivity;

  /// Create a copy of UserSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
