// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$performanceNotifierHash() =>
    r'096747c24c971593db445d85db31feb035ef3913';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$PerformanceNotifier
    extends BuildlessAutoDisposeNotifier<PerformanceState> {
  late final String songId;

  PerformanceState build(String songId);
}

/// Manages the state of an active performance session for [songId].
///
/// Navigation methods respect the current [RepeatMode] before advancing.
/// All font/spacing mutations clamp to [PerformanceState] bounds.
///
/// Copied from [PerformanceNotifier].
@ProviderFor(PerformanceNotifier)
const performanceNotifierProvider = PerformanceNotifierFamily();

/// Manages the state of an active performance session for [songId].
///
/// Navigation methods respect the current [RepeatMode] before advancing.
/// All font/spacing mutations clamp to [PerformanceState] bounds.
///
/// Copied from [PerformanceNotifier].
class PerformanceNotifierFamily extends Family<PerformanceState> {
  /// Manages the state of an active performance session for [songId].
  ///
  /// Navigation methods respect the current [RepeatMode] before advancing.
  /// All font/spacing mutations clamp to [PerformanceState] bounds.
  ///
  /// Copied from [PerformanceNotifier].
  const PerformanceNotifierFamily();

  /// Manages the state of an active performance session for [songId].
  ///
  /// Navigation methods respect the current [RepeatMode] before advancing.
  /// All font/spacing mutations clamp to [PerformanceState] bounds.
  ///
  /// Copied from [PerformanceNotifier].
  PerformanceNotifierProvider call(String songId) {
    return PerformanceNotifierProvider(songId);
  }

  @override
  PerformanceNotifierProvider getProviderOverride(
    covariant PerformanceNotifierProvider provider,
  ) {
    return call(provider.songId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'performanceNotifierProvider';
}

/// Manages the state of an active performance session for [songId].
///
/// Navigation methods respect the current [RepeatMode] before advancing.
/// All font/spacing mutations clamp to [PerformanceState] bounds.
///
/// Copied from [PerformanceNotifier].
class PerformanceNotifierProvider
    extends
        AutoDisposeNotifierProviderImpl<PerformanceNotifier, PerformanceState> {
  /// Manages the state of an active performance session for [songId].
  ///
  /// Navigation methods respect the current [RepeatMode] before advancing.
  /// All font/spacing mutations clamp to [PerformanceState] bounds.
  ///
  /// Copied from [PerformanceNotifier].
  PerformanceNotifierProvider(String songId)
    : this._internal(
        () => PerformanceNotifier()..songId = songId,
        from: performanceNotifierProvider,
        name: r'performanceNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$performanceNotifierHash,
        dependencies: PerformanceNotifierFamily._dependencies,
        allTransitiveDependencies:
            PerformanceNotifierFamily._allTransitiveDependencies,
        songId: songId,
      );

  PerformanceNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.songId,
  }) : super.internal();

  final String songId;

  @override
  PerformanceState runNotifierBuild(covariant PerformanceNotifier notifier) {
    return notifier.build(songId);
  }

  @override
  Override overrideWith(PerformanceNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PerformanceNotifierProvider._internal(
        () => create()..songId = songId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        songId: songId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<PerformanceNotifier, PerformanceState>
  createElement() {
    return _PerformanceNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PerformanceNotifierProvider && other.songId == songId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, songId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PerformanceNotifierRef
    on AutoDisposeNotifierProviderRef<PerformanceState> {
  /// The parameter `songId` of this provider.
  String get songId;
}

class _PerformanceNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          PerformanceNotifier,
          PerformanceState
        >
    with PerformanceNotifierRef {
  _PerformanceNotifierProviderElement(super.provider);

  @override
  String get songId => (origin as PerformanceNotifierProvider).songId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
