// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Trail _$TrailFromJson(Map<String, dynamic> json) {
  return _Trail.fromJson(json);
}

/// @nodoc
mixin _$Trail {
  int get id => throw _privateConstructorUsedError;
  String get highway => throw _privateConstructorUsedError;
  double get lengthM => throw _privateConstructorUsedError;
  bool get informal => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get sacScale => throw _privateConstructorUsedError;
  String? get trailVisibility => throw _privateConstructorUsedError;
  String? get surface => throw _privateConstructorUsedError;
  String? get usfsName => throw _privateConstructorUsedError;
  String? get usfsNumber => throw _privateConstructorUsedError;

  /// Polyline as [lat, lon] pairs. Empty when only metadata is loaded.
  List<List<double>> get geometry => throw _privateConstructorUsedError;

  /// Serializes this Trail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Trail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrailCopyWith<Trail> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrailCopyWith<$Res> {
  factory $TrailCopyWith(Trail value, $Res Function(Trail) then) =
      _$TrailCopyWithImpl<$Res, Trail>;
  @useResult
  $Res call(
      {int id,
      String highway,
      double lengthM,
      bool informal,
      String? name,
      String? sacScale,
      String? trailVisibility,
      String? surface,
      String? usfsName,
      String? usfsNumber,
      List<List<double>> geometry});
}

/// @nodoc
class _$TrailCopyWithImpl<$Res, $Val extends Trail>
    implements $TrailCopyWith<$Res> {
  _$TrailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Trail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? highway = null,
    Object? lengthM = null,
    Object? informal = null,
    Object? name = freezed,
    Object? sacScale = freezed,
    Object? trailVisibility = freezed,
    Object? surface = freezed,
    Object? usfsName = freezed,
    Object? usfsNumber = freezed,
    Object? geometry = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      highway: null == highway
          ? _value.highway
          : highway // ignore: cast_nullable_to_non_nullable
              as String,
      lengthM: null == lengthM
          ? _value.lengthM
          : lengthM // ignore: cast_nullable_to_non_nullable
              as double,
      informal: null == informal
          ? _value.informal
          : informal // ignore: cast_nullable_to_non_nullable
              as bool,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      sacScale: freezed == sacScale
          ? _value.sacScale
          : sacScale // ignore: cast_nullable_to_non_nullable
              as String?,
      trailVisibility: freezed == trailVisibility
          ? _value.trailVisibility
          : trailVisibility // ignore: cast_nullable_to_non_nullable
              as String?,
      surface: freezed == surface
          ? _value.surface
          : surface // ignore: cast_nullable_to_non_nullable
              as String?,
      usfsName: freezed == usfsName
          ? _value.usfsName
          : usfsName // ignore: cast_nullable_to_non_nullable
              as String?,
      usfsNumber: freezed == usfsNumber
          ? _value.usfsNumber
          : usfsNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      geometry: null == geometry
          ? _value.geometry
          : geometry // ignore: cast_nullable_to_non_nullable
              as List<List<double>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrailImplCopyWith<$Res> implements $TrailCopyWith<$Res> {
  factory _$$TrailImplCopyWith(
          _$TrailImpl value, $Res Function(_$TrailImpl) then) =
      __$$TrailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String highway,
      double lengthM,
      bool informal,
      String? name,
      String? sacScale,
      String? trailVisibility,
      String? surface,
      String? usfsName,
      String? usfsNumber,
      List<List<double>> geometry});
}

/// @nodoc
class __$$TrailImplCopyWithImpl<$Res>
    extends _$TrailCopyWithImpl<$Res, _$TrailImpl>
    implements _$$TrailImplCopyWith<$Res> {
  __$$TrailImplCopyWithImpl(
      _$TrailImpl _value, $Res Function(_$TrailImpl) _then)
      : super(_value, _then);

  /// Create a copy of Trail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? highway = null,
    Object? lengthM = null,
    Object? informal = null,
    Object? name = freezed,
    Object? sacScale = freezed,
    Object? trailVisibility = freezed,
    Object? surface = freezed,
    Object? usfsName = freezed,
    Object? usfsNumber = freezed,
    Object? geometry = null,
  }) {
    return _then(_$TrailImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      highway: null == highway
          ? _value.highway
          : highway // ignore: cast_nullable_to_non_nullable
              as String,
      lengthM: null == lengthM
          ? _value.lengthM
          : lengthM // ignore: cast_nullable_to_non_nullable
              as double,
      informal: null == informal
          ? _value.informal
          : informal // ignore: cast_nullable_to_non_nullable
              as bool,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      sacScale: freezed == sacScale
          ? _value.sacScale
          : sacScale // ignore: cast_nullable_to_non_nullable
              as String?,
      trailVisibility: freezed == trailVisibility
          ? _value.trailVisibility
          : trailVisibility // ignore: cast_nullable_to_non_nullable
              as String?,
      surface: freezed == surface
          ? _value.surface
          : surface // ignore: cast_nullable_to_non_nullable
              as String?,
      usfsName: freezed == usfsName
          ? _value.usfsName
          : usfsName // ignore: cast_nullable_to_non_nullable
              as String?,
      usfsNumber: freezed == usfsNumber
          ? _value.usfsNumber
          : usfsNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      geometry: null == geometry
          ? _value._geometry
          : geometry // ignore: cast_nullable_to_non_nullable
              as List<List<double>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrailImpl implements _Trail {
  const _$TrailImpl(
      {required this.id,
      required this.highway,
      required this.lengthM,
      this.informal = false,
      this.name,
      this.sacScale,
      this.trailVisibility,
      this.surface,
      this.usfsName,
      this.usfsNumber,
      final List<List<double>> geometry = const <List<double>>[]})
      : _geometry = geometry;

  factory _$TrailImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrailImplFromJson(json);

  @override
  final int id;
  @override
  final String highway;
  @override
  final double lengthM;
  @override
  @JsonKey()
  final bool informal;
  @override
  final String? name;
  @override
  final String? sacScale;
  @override
  final String? trailVisibility;
  @override
  final String? surface;
  @override
  final String? usfsName;
  @override
  final String? usfsNumber;

  /// Polyline as [lat, lon] pairs. Empty when only metadata is loaded.
  final List<List<double>> _geometry;

  /// Polyline as [lat, lon] pairs. Empty when only metadata is loaded.
  @override
  @JsonKey()
  List<List<double>> get geometry {
    if (_geometry is EqualUnmodifiableListView) return _geometry;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_geometry);
  }

  @override
  String toString() {
    return 'Trail(id: $id, highway: $highway, lengthM: $lengthM, informal: $informal, name: $name, sacScale: $sacScale, trailVisibility: $trailVisibility, surface: $surface, usfsName: $usfsName, usfsNumber: $usfsNumber, geometry: $geometry)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.highway, highway) || other.highway == highway) &&
            (identical(other.lengthM, lengthM) || other.lengthM == lengthM) &&
            (identical(other.informal, informal) ||
                other.informal == informal) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sacScale, sacScale) ||
                other.sacScale == sacScale) &&
            (identical(other.trailVisibility, trailVisibility) ||
                other.trailVisibility == trailVisibility) &&
            (identical(other.surface, surface) || other.surface == surface) &&
            (identical(other.usfsName, usfsName) ||
                other.usfsName == usfsName) &&
            (identical(other.usfsNumber, usfsNumber) ||
                other.usfsNumber == usfsNumber) &&
            const DeepCollectionEquality().equals(other._geometry, _geometry));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      highway,
      lengthM,
      informal,
      name,
      sacScale,
      trailVisibility,
      surface,
      usfsName,
      usfsNumber,
      const DeepCollectionEquality().hash(_geometry));

  /// Create a copy of Trail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrailImplCopyWith<_$TrailImpl> get copyWith =>
      __$$TrailImplCopyWithImpl<_$TrailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrailImplToJson(
      this,
    );
  }
}

abstract class _Trail implements Trail {
  const factory _Trail(
      {required final int id,
      required final String highway,
      required final double lengthM,
      final bool informal,
      final String? name,
      final String? sacScale,
      final String? trailVisibility,
      final String? surface,
      final String? usfsName,
      final String? usfsNumber,
      final List<List<double>> geometry}) = _$TrailImpl;

  factory _Trail.fromJson(Map<String, dynamic> json) = _$TrailImpl.fromJson;

  @override
  int get id;
  @override
  String get highway;
  @override
  double get lengthM;
  @override
  bool get informal;
  @override
  String? get name;
  @override
  String? get sacScale;
  @override
  String? get trailVisibility;
  @override
  String? get surface;
  @override
  String? get usfsName;
  @override
  String? get usfsNumber;

  /// Polyline as [lat, lon] pairs. Empty when only metadata is loaded.
  @override
  List<List<double>> get geometry;

  /// Create a copy of Trail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrailImplCopyWith<_$TrailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
