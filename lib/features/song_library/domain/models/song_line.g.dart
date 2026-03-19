// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongLineImpl _$$SongLineImplFromJson(Map<String, dynamic> json) =>
    _$SongLineImpl(
      id: json['id'] as String,
      lyric: json['lyric'] as String,
      chords:
          (json['chords'] as List<dynamic>?)
              ?.map((e) => ChordEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SongLineImplToJson(_$SongLineImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lyric': instance.lyric,
      'chords': instance.chords,
    };
