// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PersistStorage)
final persistStorageProvider = PersistStorageProvider._();

final class PersistStorageProvider
    extends $AsyncNotifierProvider<PersistStorage, Storage<String, String>> {
  PersistStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'persistStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$persistStorageHash();

  @$internal
  @override
  PersistStorage create() => PersistStorage();
}

String _$persistStorageHash() => r'387de3ab4d5f17742251a5bfef4e876cd15f08ea';

abstract class _$PersistStorage
    extends $AsyncNotifier<Storage<String, String>> {
  FutureOr<Storage<String, String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Storage<String, String>>,
              Storage<String, String>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Storage<String, String>>,
                Storage<String, String>
              >,
              AsyncValue<Storage<String, String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
