// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shortcuts)
final shortcutsProvider = ShortcutsProvider._();

final class ShortcutsProvider
    extends
        $FunctionalProvider<
          Map<Shortcut, SingleActivator?>,
          Map<Shortcut, SingleActivator?>,
          Map<Shortcut, SingleActivator?>
        >
    with $Provider<Map<Shortcut, SingleActivator?>> {
  ShortcutsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shortcutsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shortcutsHash();

  @$internal
  @override
  $ProviderElement<Map<Shortcut, SingleActivator?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<Shortcut, SingleActivator?> create(Ref ref) {
    return shortcuts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<Shortcut, SingleActivator?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<Shortcut, SingleActivator?>>(
        value,
      ),
    );
  }
}

String _$shortcutsHash() => r'5f877bc7476c0530a137eb9ddea2dfff0dcea712';
