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

String _$preferenceHash() => r'cb9c422ffe67124481af389371f338c8fa3abd00';

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

@ProviderFor(Locale)
final localeProvider = LocaleProvider._();

final class LocaleProvider extends $NotifierProvider<Locale, dart.Locale> {
  LocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeHash();

  @$internal
  @override
  Locale create() => Locale();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(dart.Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<dart.Locale>(value),
    );
  }
}

String _$localeHash() => r'708111d3344db9c7b89a6d9225964219bdbd496d';

abstract class _$Locale extends $Notifier<dart.Locale> {
  dart.Locale build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<dart.Locale, dart.Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<dart.Locale, dart.Locale>,
              dart.Locale,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(TranslateLang)
final translateLangProvider = TranslateLangProvider._();

final class TranslateLangProvider
    extends $NotifierProvider<TranslateLang, String> {
  TranslateLangProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'translateLangProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$translateLangHash();

  @$internal
  @override
  TranslateLang create() => TranslateLang();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$translateLangHash() => r'896647997a196ff4cd70ea62aedf06e8276bda2f';

abstract class _$TranslateLang extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(LyricTranslateLangs)
final lyricTranslateLangsProvider = LyricTranslateLangsProvider._();

final class LyricTranslateLangsProvider
    extends $NotifierProvider<LyricTranslateLangs, List<String>> {
  LyricTranslateLangsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lyricTranslateLangsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lyricTranslateLangsHash();

  @$internal
  @override
  LyricTranslateLangs create() => LyricTranslateLangs();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$lyricTranslateLangsHash() =>
    r'bc97385de55e1f27bed12da548672884ec2a22c5';

abstract class _$LyricTranslateLangs extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
