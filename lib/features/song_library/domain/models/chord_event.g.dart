// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chord_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChordEventImpl _$$ChordEventImplFromJson(Map<String, dynamic> json) =>
    _$ChordEventImpl(
      chord: json['chord'] as String,
      position: (json['position'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ChordEventImplToJson(_$ChordEventImpl instance) =>
    <String, dynamic>{'chord': instance.chord, 'position': instance.position};
