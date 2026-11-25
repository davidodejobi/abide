import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/daily/domain/date_key.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';

import '../domain/onboarding_defaults.dart';

/// What the person has picked so far during onboarding. Nothing is written
/// until [OnboardingNotifier.complete].
class OnboardingState {
  const OnboardingState({
    required this.languageCode,
    required this.editionId,
    required this.planId,
    this.name = '',
  });

  final String languageCode;
  final String editionId;
  final String planId;

  /// Untrimmed, as typed.
  final String name;

  OnboardingState copyWith({
    String? languageCode,
    String? editionId,
    String? planId,
    String? name,
  }) =>
      OnboardingState(
        languageCode: languageCode ?? this.languageCode,
        editionId: editionId ?? this.editionId,
        planId: planId ?? this.planId,
        name: name ?? this.name,
      );
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
        OnboardingNotifier.new);

/// The name the user saved during onboarding (null if they skipped it).
/// Read by the home header to greet the user personally.
final userNameProvider = Provider<String?>((ref) {
  final name = ref.watch(storageServiceProvider).getUserName()?.trim();
  return (name == null || name.isEmpty) ? null : name;
});

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    final lang =
        defaultLanguageFor(PlatformDispatcher.instance.locale.languageCode);
    return OnboardingState(
      languageCode: lang,
      editionId: defaultEditionFor(lang),
      planId: kOnboardingDefaultPlanId,
    );
  }

  /// Picking a language moves the edition to that language's first Bible.
  void setLanguage(String code) {
    if (code == state.languageCode) return;
    state = state.copyWith(
        languageCode: code, editionId: defaultEditionFor(code));
  }

  void setEdition(String id) => state = state.copyWith(editionId: id);
  void setPlan(String id) => state = state.copyWith(planId: id);
  void setName(String name) => state = state.copyWith(name: name);

  /// Writes every choice to where the rest of the app reads it, then marks
  /// onboarding complete. The flag goes last so a failure part-way lets the
  /// person run onboarding again.
  Future<void> complete() async {
    final storage = ref.read(storageServiceProvider);
    final name = state.name.trim();
    if (name.isNotEmpty) {
      await storage.saveUserName(name);
    }
    ref.read(bibleReadingPositionProvider.notifier).setEdition(state.editionId);
    // Songs ship in English and Yoruba only; other languages keep the default.
    if (state.languageCode == 'en' || state.languageCode == 'yo') {
      ref.read(languageProvider.notifier).state = state.languageCode;
    }
    await ref.read(readingPlansDaoProvider).startPlan(
          planId: state.planId,
          startDateKey: todayKey(),
        );
    await storage.saveOnboardingComplete(true);
  }
}
