// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(waveformController)
final waveformControllerProvider = WaveformControllerProvider._();

final class WaveformControllerProvider
    extends
        $FunctionalProvider<
          Raw<WaveformController>,
          Raw<WaveformController>,
          Raw<WaveformController>
        >
    with $Provider<Raw<WaveformController>> {
  WaveformControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waveformControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waveformControllerHash();

  @$internal
  @override
  $ProviderElement<Raw<WaveformController>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<WaveformController> create(Ref ref) {
    return waveformController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<WaveformController> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<WaveformController>>(value),
    );
  }
}

String _$waveformControllerHash() =>
    r'04f989eb28dac4dff081956127acea2ae452b09a';
