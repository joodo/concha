// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Preference)
final preferenceProvider = PreferenceFamily._();

final class PreferenceProvider<T> extends $NotifierProvider<Preference<T>, T?> {
  PreferenceProvider._({
    required PreferenceFamily super.from,
    required PrefKey super.argument,
  }) : super(
         retry: null,
         name: r'preferenceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$preferenceHash();

  @override
  String toString() {
    return r'preferenceProvider'
        '<${T}>'
        '($argument)';
  }

  @$internal
  @override
  Preference<T> create() => Preference<T>();

  $R _captureGenerics<$R>($R Function<T>() cb) {
    return cb<T>();
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(T? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<T?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PreferenceProvider &&
        other.runtimeType == runtimeType &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, argument);
  }
}

String _$preferenceHash() => r'7a9acd10b8c8c4e315a6d8bc514989763985f13a';

final class PreferenceFamily extends $Family {
  PreferenceFamily._()
    : super(
        retry: null,
        name: r'preferenceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PreferenceProvider<T> call<T>(PrefKey key) =>
      PreferenceProvider<T>._(argument: key, from: this);

  @override
  String toString() => r'preferenceProvider';

  /// {@macro riverpod.override_with}
  Override overrideWith(Preference<T> Function<T>() create) => $FamilyOverride(
    from: this,
    createElement: (pointer) {
      final provider = pointer.origin as PreferenceProvider;
      return provider._captureGenerics(<T>() {
        provider as PreferenceProvider<T>;
        return provider.$view(create: create<T>).$createElement(pointer);
      });
    },
  );

  /// {@macro riverpod.override_with_build}
  Override overrideWithBuild(
    T? Function<T>(Ref ref, Preference<T> notifier) build,
  ) => $FamilyOverride(
    from: this,
    createElement: (pointer) {
      final provider = pointer.origin as PreferenceProvider;
      return provider._captureGenerics(<T>() {
        provider as PreferenceProvider<T>;
        return provider
            .$view(runNotifierBuildOverride: build<T>)
            .$createElement(pointer);
      });
    },
  );
}

abstract class _$Preference<T> extends $Notifier<T?> {
  late final _$args = ref.$arg as PrefKey;
  PrefKey get key => _$args;

  T? build(PrefKey key);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<T?, T?>;
    final element =
        ref.element
            as $ClassProviderElement<AnyNotifier<T?, T?>, T?, Object?, Object?>;
    element.handleCreate(ref, () => build(_$args));
  }
}
