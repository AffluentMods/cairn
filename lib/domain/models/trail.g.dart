// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TrailImpl _$$TrailImplFromJson(Map<String, dynamic> json) => _$TrailImpl(
      id: (json['id'] as num).toInt(),
      highway: json['highway'] as String,
      lengthM: (json['lengthM'] as num).toDouble(),
      informal: json['informal'] as bool? ?? false,
      name: json['name'] as String?,
      sacScale: json['sacScale'] as String?,
      trailVisibility: json['trailVisibility'] as String?,
      surface: json['surface'] as String?,
      usfsName: json['usfsName'] as String?,
      usfsNumber: json['usfsNumber'] as String?,
      geometry: (json['geometry'] as List<dynamic>?)
              ?.map((e) => (e as List<dynamic>)
                  .map((e) => (e as num).toDouble())
                  .toList())
              .toList() ??
          const <List<double>>[],
    );

Map<String, dynamic> _$$TrailImplToJson(_$TrailImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'highway': instance.highway,
      'lengthM': instance.lengthM,
      'informal': instance.informal,
      'name': instance.name,
      'sacScale': instance.sacScale,
      'trailVisibility': instance.trailVisibility,
      'surface': instance.surface,
      'usfsName': instance.usfsName,
      'usfsNumber': instance.usfsNumber,
      'geometry': instance.geometry,
    };
