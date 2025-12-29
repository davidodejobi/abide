// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hymns_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hymnDetailHash() => r'22722588a63aa2b465ee6ce25ae1cf6da0a930cf';

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

/// See also [hymnDetail].
@ProviderFor(hymnDetail)
const hymnDetailProvider = HymnDetailFamily();

/// See also [hymnDetail].
class HymnDetailFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [hymnDetail].
  const HymnDetailFamily();

  /// See also [hymnDetail].
  HymnDetailProvider call(
    String hymnId,
  ) {
    return HymnDetailProvider(
      hymnId,
    );
  }

  @override
  HymnDetailProvider getProviderOverride(
    covariant HymnDetailProvider provider,
  ) {
    return call(
      provider.hymnId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'hymnDetailProvider';
}

/// See also [hymnDetail].
class HymnDetailProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [hymnDetail].
  HymnDetailProvider(
    String hymnId,
  ) : this._internal(
          (ref) => hymnDetail(
            ref as HymnDetailRef,
            hymnId,
          ),
          from: hymnDetailProvider,
          name: r'hymnDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hymnDetailHash,
          dependencies: HymnDetailFamily._dependencies,
          allTransitiveDependencies:
              HymnDetailFamily._allTransitiveDependencies,
          hymnId: hymnId,
        );

  HymnDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.hymnId,
  }) : super.internal();

  final String hymnId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(HymnDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HymnDetailProvider._internal(
        (ref) => create(ref as HymnDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        hymnId: hymnId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _HymnDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HymnDetailProvider && other.hymnId == hymnId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, hymnId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HymnDetailRef on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `hymnId` of this provider.
  String get hymnId;
}

class _HymnDetailProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with HymnDetailRef {
  _HymnDetailProviderElement(super.provider);

  @override
  String get hymnId => (origin as HymnDetailProvider).hymnId;
}

String _$bilingualHymnDetailHash() =>
    r'e7bf374b856408fbaf63123f7ef994d78583a49c';

/// See also [bilingualHymnDetail].
@ProviderFor(bilingualHymnDetail)
const bilingualHymnDetailProvider = BilingualHymnDetailFamily();

/// See also [bilingualHymnDetail].
class BilingualHymnDetailFamily
    extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [bilingualHymnDetail].
  const BilingualHymnDetailFamily();

  /// See also [bilingualHymnDetail].
  BilingualHymnDetailProvider call(
    String hymnId,
    List<String> languages,
  ) {
    return BilingualHymnDetailProvider(
      hymnId,
      languages,
    );
  }

  @override
  BilingualHymnDetailProvider getProviderOverride(
    covariant BilingualHymnDetailProvider provider,
  ) {
    return call(
      provider.hymnId,
      provider.languages,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bilingualHymnDetailProvider';
}

/// See also [bilingualHymnDetail].
class BilingualHymnDetailProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [bilingualHymnDetail].
  BilingualHymnDetailProvider(
    String hymnId,
    List<String> languages,
  ) : this._internal(
          (ref) => bilingualHymnDetail(
            ref as BilingualHymnDetailRef,
            hymnId,
            languages,
          ),
          from: bilingualHymnDetailProvider,
          name: r'bilingualHymnDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bilingualHymnDetailHash,
          dependencies: BilingualHymnDetailFamily._dependencies,
          allTransitiveDependencies:
              BilingualHymnDetailFamily._allTransitiveDependencies,
          hymnId: hymnId,
          languages: languages,
        );

  BilingualHymnDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.hymnId,
    required this.languages,
  }) : super.internal();

  final String hymnId;
  final List<String> languages;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(BilingualHymnDetailRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BilingualHymnDetailProvider._internal(
        (ref) => create(ref as BilingualHymnDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        hymnId: hymnId,
        languages: languages,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _BilingualHymnDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BilingualHymnDetailProvider &&
        other.hymnId == hymnId &&
        other.languages == languages;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, hymnId.hashCode);
    hash = _SystemHash.combine(hash, languages.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BilingualHymnDetailRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `hymnId` of this provider.
  String get hymnId;

  /// The parameter `languages` of this provider.
  List<String> get languages;
}

class _BilingualHymnDetailProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with BilingualHymnDetailRef {
  _BilingualHymnDetailProviderElement(super.provider);

  @override
  String get hymnId => (origin as BilingualHymnDetailProvider).hymnId;
  @override
  List<String> get languages =>
      (origin as BilingualHymnDetailProvider).languages;
}

String _$hymnsViewModelHash() => r'db8730650ecacf9c0b9843203120a50f5b5d008d';

/// See also [HymnsViewModel].
@ProviderFor(HymnsViewModel)
final hymnsViewModelProvider = AutoDisposeAsyncNotifierProvider<HymnsViewModel,
    List<Map<String, dynamic>>>.internal(
  HymnsViewModel.new,
  name: r'hymnsViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hymnsViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HymnsViewModel = AutoDisposeAsyncNotifier<List<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
