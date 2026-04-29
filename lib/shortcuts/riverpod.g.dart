// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shortcutsRouter)
final shortcutsRouterProvider = ShortcutsRouterProvider._();

final class ShortcutsRouterProvider
    extends
        $FunctionalProvider<
          Map<Shortcut, SingleActivator?>,
          Map<Shortcut, SingleActivator?>,
          Map<Shortcut, SingleActivator?>
        >
    with $Provider<Map<Shortcut, SingleActivator?>> {
  ShortcutsRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shortcutsRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shortcutsRouterHash();

  @$internal
  @override
  $ProviderElement<Map<Shortcut, SingleActivator?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<Shortcut, SingleActivator?> create(Ref ref) {
    return shortcutsRouter(ref);
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

String _$shortcutsRouterHash() => r'87543c38956707077b10959bf7e3140d87d4d8c4';
