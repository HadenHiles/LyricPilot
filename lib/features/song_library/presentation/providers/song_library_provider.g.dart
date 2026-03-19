// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_library_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredSongsHash() => r'a79983121fba88137207f3598ab2e986daea0e1a';

/// Songs filtered by the current [songSearchQueryProvider] value.
///
/// Copied from [filteredSongs].
@ProviderFor(filteredSongs)
final filteredSongsProvider = AutoDisposeProvider<List<Song>>.internal(
  filteredSongs,
  name: r'filteredSongsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredSongsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredSongsRef = AutoDisposeProviderRef<List<Song>>;
String _$songByIdHash() => r'7ea95bdf4e144207a12c829aa821626c99dc90d3';

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

/// Looks up a single song by its [id]. Returns null if not found.
///
/// Copied from [songById].
@ProviderFor(songById)
const songByIdProvider = SongByIdFamily();

/// Looks up a single song by its [id]. Returns null if not found.
///
/// Copied from [songById].
class SongByIdFamily extends Family<Song?> {
  /// Looks up a single song by its [id]. Returns null if not found.
  ///
  /// Copied from [songById].
  const SongByIdFamily();

  /// Looks up a single song by its [id]. Returns null if not found.
  ///
  /// Copied from [songById].
  SongByIdProvider call(String id) {
    return SongByIdProvider(id);
  }

  @override
  SongByIdProvider getProviderOverride(covariant SongByIdProvider provider) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'songByIdProvider';
}

/// Looks up a single song by its [id]. Returns null if not found.
///
/// Copied from [songById].
class SongByIdProvider extends AutoDisposeProvider<Song?> {
  /// Looks up a single song by its [id]. Returns null if not found.
  ///
  /// Copied from [songById].
  SongByIdProvider(String id)
    : this._internal(
        (ref) => songById(ref as SongByIdRef, id),
        from: songByIdProvider,
        name: r'songByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$songByIdHash,
        dependencies: SongByIdFamily._dependencies,
        allTransitiveDependencies: SongByIdFamily._allTransitiveDependencies,
        id: id,
      );

  SongByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(Song? Function(SongByIdRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: SongByIdProvider._internal(
        (ref) => create(ref as SongByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Song?> createElement() {
    return _SongByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SongByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SongByIdRef on AutoDisposeProviderRef<Song?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _SongByIdProviderElement extends AutoDisposeProviderElement<Song?>
    with SongByIdRef {
  _SongByIdProviderElement(super.provider);

  @override
  String get id => (origin as SongByIdProvider).id;
}

String _$songLibraryNotifierHash() =>
    r'f3c996696940e982d41e3df1ad03a57337e94edd';

/// The authoritative song library, backed by [SongRepository].
///
/// On first launch the repository is empty — it is seeded with [sampleSongs].
/// Exposes [save] and [delete] to mutate the library and invalidate itself.
///
/// Copied from [SongLibraryNotifier].
@ProviderFor(SongLibraryNotifier)
final songLibraryNotifierProvider =
    AutoDisposeAsyncNotifierProvider<SongLibraryNotifier, List<Song>>.internal(
      SongLibraryNotifier.new,
      name: r'songLibraryNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$songLibraryNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SongLibraryNotifier = AutoDisposeAsyncNotifier<List<Song>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
