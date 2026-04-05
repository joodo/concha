// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProjectList)
final projectListProvider = ProjectListProvider._();

final class ProjectListProvider
    extends $AsyncNotifierProvider<ProjectList, List<String>> {
  ProjectListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectListHash();

  @$internal
  @override
  ProjectList create() => ProjectList();
}

String _$projectListHash() => r'72e4bf5212c9ead9e26a54b98a2a47460aa7370a';

abstract class _$ProjectList extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ProjectDetail)
final projectDetailProvider = ProjectDetailFamily._();

final class ProjectDetailProvider
    extends $AsyncNotifierProvider<ProjectDetail, Project> {
  ProjectDetailProvider._({
    required ProjectDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'projectDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectDetailHash();

  @override
  String toString() {
    return r'projectDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProjectDetail create() => ProjectDetail();

  @override
  bool operator ==(Object other) {
    return other is ProjectDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectDetailHash() => r'431670e9de669506cb0c3dabbe60b8c692b4ea1c';

final class ProjectDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          ProjectDetail,
          AsyncValue<Project>,
          Project,
          FutureOr<Project>,
          String
        > {
  ProjectDetailFamily._()
    : super(
        retry: null,
        name: r'projectDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProjectDetailProvider call(String id) =>
      ProjectDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'projectDetailProvider';
}

abstract class _$ProjectDetail extends $AsyncNotifier<Project> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<Project> build(String id);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Project>, Project>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Project>, Project>,
              AsyncValue<Project>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
