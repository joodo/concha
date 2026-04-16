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

@ProviderFor(shortcutsIntentMap)
final shortcutsIntentMapProvider = ShortcutsIntentMapProvider._();

final class ShortcutsIntentMapProvider
    extends
        $FunctionalProvider<
          Map<SingleActivator, Intent>,
          Map<SingleActivator, Intent>,
          Map<SingleActivator, Intent>
        >
    with $Provider<Map<SingleActivator, Intent>> {
  ShortcutsIntentMapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shortcutsIntentMapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shortcutsIntentMapHash();

  @$internal
  @override
  $ProviderElement<Map<SingleActivator, Intent>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<SingleActivator, Intent> create(Ref ref) {
    return shortcutsIntentMap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<SingleActivator, Intent> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<SingleActivator, Intent>>(value),
    );
  }
}

String _$shortcutsIntentMapHash() =>
    r'64b8055f0435c6b76668bf1afdb08c0a46f1797c';
