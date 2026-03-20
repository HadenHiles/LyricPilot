// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongImpl _$$SongImplFromJson(Map<String, dynamic> json) => _$SongImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  artist: json['artist'] as String,
  key: json['key'] as String?,
  bpm: (json['bpm'] as num?)?.toInt(),
  notes: json['notes'] as String?,
  sections:
      (json['sections'] as List<dynamic>?)
          ?.map((e) => SongSection.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  pinnedAt: json['pinnedAt'] == null
      ? null
      : DateTime.parse(json['pinnedAt'] as String),
);

Map<String, dynamic> _$$SongImplToJson(_$SongImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'key': instance.key,
      'bpm': instance.bpm,
      'notes': instance.notes,
      'sections': instance.sections,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'pinnedAt': instance.pinnedAt?.toIso8601String(),
    };
