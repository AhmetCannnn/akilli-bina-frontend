// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visitor_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dailyVisitorSummaryHash() =>
    r'be5770ba3fe655131949cf49b84a3f9775a5e875';

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

/// Belirli bir binanın günlük ziyaretçi özeti için provider
///
/// Copied from [dailyVisitorSummary].
@ProviderFor(dailyVisitorSummary)
const dailyVisitorSummaryProvider = DailyVisitorSummaryFamily();

/// Belirli bir binanın günlük ziyaretçi özeti için provider
///
/// Copied from [dailyVisitorSummary].
class DailyVisitorSummaryFamily
    extends Family<AsyncValue<Map<String, dynamic>>> {
  /// Belirli bir binanın günlük ziyaretçi özeti için provider
  ///
  /// Copied from [dailyVisitorSummary].
  const DailyVisitorSummaryFamily();

  /// Belirli bir binanın günlük ziyaretçi özeti için provider
  ///
  /// Copied from [dailyVisitorSummary].
  DailyVisitorSummaryProvider call(
    int buildingId,
    DateTime visitDate,
  ) {
    return DailyVisitorSummaryProvider(
      buildingId,
      visitDate,
    );
  }

  @override
  DailyVisitorSummaryProvider getProviderOverride(
    covariant DailyVisitorSummaryProvider provider,
  ) {
    return call(
      provider.buildingId,
      provider.visitDate,
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
  String? get name => r'dailyVisitorSummaryProvider';
}

/// Belirli bir binanın günlük ziyaretçi özeti için provider
///
/// Copied from [dailyVisitorSummary].
class DailyVisitorSummaryProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// Belirli bir binanın günlük ziyaretçi özeti için provider
  ///
  /// Copied from [dailyVisitorSummary].
  DailyVisitorSummaryProvider(
    int buildingId,
    DateTime visitDate,
  ) : this._internal(
          (ref) => dailyVisitorSummary(
            ref as DailyVisitorSummaryRef,
            buildingId,
            visitDate,
          ),
          from: dailyVisitorSummaryProvider,
          name: r'dailyVisitorSummaryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dailyVisitorSummaryHash,
          dependencies: DailyVisitorSummaryFamily._dependencies,
          allTransitiveDependencies:
              DailyVisitorSummaryFamily._allTransitiveDependencies,
          buildingId: buildingId,
          visitDate: visitDate,
        );

  DailyVisitorSummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.buildingId,
    required this.visitDate,
  }) : super.internal();

  final int buildingId;
  final DateTime visitDate;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(DailyVisitorSummaryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DailyVisitorSummaryProvider._internal(
        (ref) => create(ref as DailyVisitorSummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        buildingId: buildingId,
        visitDate: visitDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _DailyVisitorSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DailyVisitorSummaryProvider &&
        other.buildingId == buildingId &&
        other.visitDate == visitDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, buildingId.hashCode);
    hash = _SystemHash.combine(hash, visitDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DailyVisitorSummaryRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `buildingId` of this provider.
  int get buildingId;

  /// The parameter `visitDate` of this provider.
  DateTime get visitDate;
}

class _DailyVisitorSummaryProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with DailyVisitorSummaryRef {
  _DailyVisitorSummaryProviderElement(super.provider);

  @override
  int get buildingId => (origin as DailyVisitorSummaryProvider).buildingId;
  @override
  DateTime get visitDate => (origin as DailyVisitorSummaryProvider).visitDate;
}

String _$visitPurposesHash() => r'48a51fe21eecc89d88bc4047789d2b73d08b75ef';

/// Ziyaretçi amacı seçenekleri için provider
///
/// Copied from [visitPurposes].
@ProviderFor(visitPurposes)
final visitPurposesProvider = AutoDisposeProvider<List<String>>.internal(
  visitPurposes,
  name: r'visitPurposesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$visitPurposesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VisitPurposesRef = AutoDisposeProviderRef<List<String>>;
String _$visitorControllerHash() => r'291dc51d9a364758658ddc0934f9693960102b15';

/// See also [VisitorController].
@ProviderFor(VisitorController)
final visitorControllerProvider = AutoDisposeAsyncNotifierProvider<
    VisitorController, List<Map<String, dynamic>>>.internal(
  VisitorController.new,
  name: r'visitorControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$visitorControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VisitorController
    = AutoDisposeAsyncNotifier<List<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
