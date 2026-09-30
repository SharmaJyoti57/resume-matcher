// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matcher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Matcher)
final matcherProvider = MatcherProvider._();

final class MatcherProvider extends $NotifierProvider<Matcher, MatcherState> {
  MatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matcherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matcherHash();

  @$internal
  @override
  Matcher create() => Matcher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatcherState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatcherState>(value),
    );
  }
}

String _$matcherHash() => r'e81a8bb75ab0024fe2da7f6fe24d83a33542c469';

abstract class _$Matcher extends $Notifier<MatcherState> {
  MatcherState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MatcherState, MatcherState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MatcherState, MatcherState>,
              MatcherState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
