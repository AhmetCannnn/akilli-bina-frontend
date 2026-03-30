// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'building_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$buildingControllerHash() =>
    r'62d0078217acca4bc336264db2c234bacd636231';

/// See also [BuildingController].
@ProviderFor(BuildingController)
final buildingControllerProvider = AutoDisposeAsyncNotifierProvider<
    BuildingController, List<Map<String, dynamic>>>.internal(
  BuildingController.new,
  name: r'buildingControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$buildingControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BuildingController
    = AutoDisposeAsyncNotifier<List<Map<String, dynamic>>>;
String _$buildingDetailControllerHash() =>
    r'fc03c3c35ea6501de7a166b980ccc31ea0540ad2';

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

abstract class _$BuildingDetailController
    extends BuildlessAutoDisposeAsyncNotifier<Map<String, dynamic>> {
  late final int buildingId;

  FutureOr<Map<String, dynamic>> build(
    int buildingId,
  );
}

/// See also [BuildingDetailController].
@ProviderFor(BuildingDetailController)
const buildingDetailControllerProvider = BuildingDetailControllerFamily();

/// See also [BuildingDetailController].
class BuildingDetailControllerFamily
    extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [BuildingDetailController].
  const BuildingDetailControllerFamily();

  /// See also [BuildingDetailController].
  BuildingDetailControllerProvider call(
    int buildingId,
  ) {
    return BuildingDetailControllerProvider(
      buildingId,
    );
  }

  @override
  BuildingDetailControllerProvider getProviderOverride(
    covariant BuildingDetailControllerProvider provider,
  ) {
    return call(
      provider.buildingId,
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
  String? get name => r'buildingDetailControllerProvider';
}

/// See also [BuildingDetailController].
class BuildingDetailControllerProvider
    extends AutoDisposeAsyncNotifierProviderImpl<BuildingDetailController,
        Map<String, dynamic>> {
  /// See also [BuildingDetailController].
  BuildingDetailControllerProvider(
    int buildingId,
  ) : this._internal(
          () => BuildingDetailController()..buildingId = buildingId,
          from: buildingDetailControllerProvider,
          name: r'buildingDetailControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$buildingDetailControllerHash,
          dependencies: BuildingDetailControllerFamily._dependencies,
          allTransitiveDependencies:
              BuildingDetailControllerFamily._allTransitiveDependencies,
          buildingId: buildingId,
        );

  BuildingDetailControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.buildingId,
  }) : super.internal();

  final int buildingId;

  @override
  FutureOr<Map<String, dynamic>> runNotifierBuild(
    covariant BuildingDetailController notifier,
  ) {
    return notifier.build(
      buildingId,
    );
  }

  @override
  Override overrideWith(BuildingDetailController Function() create) {
    return ProviderOverride(
      origin: this,
      override: BuildingDetailControllerProvider._internal(
        () => create()..buildingId = buildingId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        buildingId: buildingId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<BuildingDetailController,
      Map<String, dynamic>> createElement() {
    return _BuildingDetailControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BuildingDetailControllerProvider &&
        other.buildingId == buildingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, buildingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BuildingDetailControllerRef
    on AutoDisposeAsyncNotifierProviderRef<Map<String, dynamic>> {
  /// The parameter `buildingId` of this provider.
  int get buildingId;
}

class _BuildingDetailControllerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<BuildingDetailController,
        Map<String, dynamic>> with BuildingDetailControllerRef {
  _BuildingDetailControllerProviderElement(super.provider);

  @override
  int get buildingId => (origin as BuildingDetailControllerProvider).buildingId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
