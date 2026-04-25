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

String _$projectListHash() => r'2146adc2ed7e7522cd7bc8a831bcc6aa4370cef9';

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

String _$projectDetailHash() => r'139d5880dfa42a2ce8bab22ee226bd370bba2d74';

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

@ProviderFor(ProjectLastVisited)
final projectLastVisitedProvider = ProjectLastVisitedFamily._();

final class ProjectLastVisitedProvider
    extends $AsyncNotifierProvider<ProjectLastVisited, DateTime> {
  ProjectLastVisitedProvider._({
    required ProjectLastVisitedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'projectLastVisitedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectLastVisitedHash();

  @override
  String toString() {
    return r'projectLastVisitedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProjectLastVisited create() => ProjectLastVisited();

  @override
  bool operator ==(Object other) {
    return other is ProjectLastVisitedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectLastVisitedHash() =>
    r'17ef20643157db5a01908ab4e91e834df6715e07';

final class ProjectLastVisitedFamily extends $Family
    with
        $ClassFamilyOverride<
          ProjectLastVisited,
          AsyncValue<DateTime>,
          DateTime,
          FutureOr<DateTime>,
          String
        > {
  ProjectLastVisitedFamily._()
    : super(
        retry: null,
        name: r'projectLastVisitedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProjectLastVisitedProvider call(String id) =>
      ProjectLastVisitedProvider._(argument: id, from: this);

  @override
  String toString() => r'projectLastVisitedProvider';
}

abstract class _$ProjectLastVisited extends $AsyncNotifier<DateTime> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<DateTime> build(String id);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DateTime>, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DateTime>, DateTime>,
              AsyncValue<DateTime>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(ProjectCoverBytes)
final projectCoverBytesProvider = ProjectCoverBytesFamily._();

final class ProjectCoverBytesProvider
    extends $AsyncNotifierProvider<ProjectCoverBytes, Uint8List?> {
  ProjectCoverBytesProvider._({
    required ProjectCoverBytesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'projectCoverBytesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectCoverBytesHash();

  @override
  String toString() {
    return r'projectCoverBytesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProjectCoverBytes create() => ProjectCoverBytes();

  @override
  bool operator ==(Object other) {
    return other is ProjectCoverBytesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectCoverBytesHash() => r'c413fc4cfbb9e7b2cbd61908c9b2bbe00174424f';

final class ProjectCoverBytesFamily extends $Family
    with
        $ClassFamilyOverride<
          ProjectCoverBytes,
          AsyncValue<Uint8List?>,
          Uint8List?,
          FutureOr<Uint8List?>,
          String
        > {
  ProjectCoverBytesFamily._()
    : super(
        retry: null,
        name: r'projectCoverBytesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProjectCoverBytesProvider call(String id) =>
      ProjectCoverBytesProvider._(argument: id, from: this);

  @override
  String toString() => r'projectCoverBytesProvider';
}

abstract class _$ProjectCoverBytes extends $AsyncNotifier<Uint8List?> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<Uint8List?> build(String id);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Uint8List?>, Uint8List?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Uint8List?>, Uint8List?>,
              AsyncValue<Uint8List?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
