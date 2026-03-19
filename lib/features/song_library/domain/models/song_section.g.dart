// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_section.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongSectionImpl _$$SongSectionImplFromJson(Map<String, dynamic> json) =>
    _$SongSectionImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$SectionTypeEnumMap, json['type']),
      lines:
          (json['lines'] as List<dynamic>?)
              ?.map((e) => SongLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SongSectionImplToJson(_$SongSectionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$SectionTypeEnumMap[instance.type]!,
      'lines': instance.lines,
    };

const _$SectionTypeEnumMap = {
  SectionType.intro: 'intro',
  SectionType.verse: 'verse',
  SectionType.preChorus: 'preChorus',
  SectionType.chorus: 'chorus',
  SectionType.bridge: 'bridge',
  SectionType.outro: 'outro',
  SectionType.solo: 'solo',
  SectionType.instrumental: 'instrumental',
  SectionType.custom: 'custom',
};
