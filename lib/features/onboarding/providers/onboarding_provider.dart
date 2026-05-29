import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';

/// Holds the name the user is entering during onboarding and persists the
/// completion flag. State is the current (untrimmed) name string.
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, String>(OnboardingNotifier.new);

class OnboardingNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setName(String name) => state = name;

  /// Saves the name and marks onboarding complete.
  Future<void> complete() async {
    final storage = ref.read(storageServiceProvider);
    final name = state.trim();
    if (name.isNotEmpty) {
      await storage.saveUserName(name);
    }
    await storage.saveOnboardingComplete(true);
  }
}
