// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HttpBlob)
final httpBlobProvider = HttpBlobFamily._();

final class HttpBlobProvider
    extends $AsyncNotifierProvider<HttpBlob, Uint8List> {
  HttpBlobProvider._({
    required HttpBlobFamily super.from,
    required Uri super.argument,
  }) : super(
         retry: disableRetry,
         name: r'httpBlobProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$httpBlobHash();

  @override
  String toString() {
    return r'httpBlobProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HttpBlob create() => HttpBlob();

  @override
  bool operator ==(Object other) {
    return other is HttpBlobProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$httpBlobHash() => r'726f12a26d752e8ef41f708b38694ffcb76edc03';

final class HttpBlobFamily extends $Family
    with
        $ClassFamilyOverride<
          HttpBlob,
          AsyncValue<Uint8List>,
          Uint8List,
          FutureOr<Uint8List>,
          Uri
        > {
  HttpBlobFamily._()
    : super(
        retry: disableRetry,
        name: r'httpBlobProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HttpBlobProvider call(Uri url) =>
      HttpBlobProvider._(argument: url, from: this);

  @override
  String toString() => r'httpBlobProvider';
}

abstract class _$HttpBlob extends $AsyncNotifier<Uint8List> {
  late final _$args = ref.$arg as Uri;
  Uri get url => _$args;

  FutureOr<Uint8List> build(Uri url);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Uint8List>, Uint8List>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Uint8List>, Uint8List>,
              AsyncValue<Uint8List>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
