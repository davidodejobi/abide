// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [BibleCreditsPage]
class BibleCreditsRoute extends PageRouteInfo<void> {
  const BibleCreditsRoute({List<PageRouteInfo>? children})
      : super(BibleCreditsRoute.name, initialChildren: children);

  static const String name = 'BibleCreditsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const BibleCreditsPage();
    },
  );
}

/// generated route for
/// [BibleReaderPage]
class BibleReaderRoute extends PageRouteInfo<BibleReaderRouteArgs> {
  BibleReaderRoute({
    Key? key,
    String? planId,
    int? dayIndex,
    List<PageRouteInfo>? children,
  }) : super(
          BibleReaderRoute.name,
          args: BibleReaderRouteArgs(
            key: key,
            planId: planId,
            dayIndex: dayIndex,
          ),
          initialChildren: children,
        );

  static const String name = 'BibleReaderRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<BibleReaderRouteArgs>(
        orElse: () => const BibleReaderRouteArgs(),
      );
      return BibleReaderPage(
        key: args.key,
        planId: args.planId,
        dayIndex: args.dayIndex,
      );
    },
  );
}

class BibleReaderRouteArgs {
  const BibleReaderRouteArgs({this.key, this.planId, this.dayIndex});

  final Key? key;

  final String? planId;

  final int? dayIndex;

  @override
  String toString() {
    return 'BibleReaderRouteArgs{key: $key, planId: $planId, dayIndex: $dayIndex}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BibleReaderRouteArgs) return false;
    return key == other.key &&
        planId == other.planId &&
        dayIndex == other.dayIndex;
  }

  @override
  int get hashCode => key.hashCode ^ planId.hashCode ^ dayIndex.hashCode;
}

/// generated route for
/// [BibleTabScreen]
class BibleTabRoute extends PageRouteInfo<BibleTabRouteArgs> {
  BibleTabRoute({
    Key? key,
    bool controlsAppNav = true,
    String? planId,
    int? dayIndex,
    List<PageRouteInfo>? children,
  }) : super(
          BibleTabRoute.name,
          args: BibleTabRouteArgs(
            key: key,
            controlsAppNav: controlsAppNav,
            planId: planId,
            dayIndex: dayIndex,
          ),
          initialChildren: children,
        );

  static const String name = 'BibleTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<BibleTabRouteArgs>(
        orElse: () => const BibleTabRouteArgs(),
      );
      return BibleTabScreen(
        key: args.key,
        controlsAppNav: args.controlsAppNav,
        planId: args.planId,
        dayIndex: args.dayIndex,
      );
    },
  );
}

class BibleTabRouteArgs {
  const BibleTabRouteArgs({
    this.key,
    this.controlsAppNav = true,
    this.planId,
    this.dayIndex,
  });

  final Key? key;

  final bool controlsAppNav;

  final String? planId;

  final int? dayIndex;

  @override
  String toString() {
    return 'BibleTabRouteArgs{key: $key, controlsAppNav: $controlsAppNav, planId: $planId, dayIndex: $dayIndex}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BibleTabRouteArgs) return false;
    return key == other.key &&
        controlsAppNav == other.controlsAppNav &&
        planId == other.planId &&
        dayIndex == other.dayIndex;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      controlsAppNav.hashCode ^
      planId.hashCode ^
      dayIndex.hashCode;
}

/// generated route for
/// [DashboardScreen]
class DashboardRoute extends PageRouteInfo<void> {
  const DashboardRoute({List<PageRouteInfo>? children})
      : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DashboardScreen();
    },
  );
}

/// generated route for
/// [FavoritesTabScreen]
class FavoritesTabRoute extends PageRouteInfo<void> {
  const FavoritesTabRoute({List<PageRouteInfo>? children})
      : super(FavoritesTabRoute.name, initialChildren: children);

  static const String name = 'FavoritesTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FavoritesTabScreen();
    },
  );
}

/// generated route for
/// [HomeTabScreen]
class HomeTabRoute extends PageRouteInfo<void> {
  const HomeTabRoute({List<PageRouteInfo>? children})
      : super(HomeTabRoute.name, initialChildren: children);

  static const String name = 'HomeTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeTabScreen();
    },
  );
}

/// generated route for
/// [HymnDetailPage]
class HymnDetailRoute extends PageRouteInfo<HymnDetailRouteArgs> {
  HymnDetailRoute({
    Key? key,
    required String hymnId,
    List<PageRouteInfo>? children,
  }) : super(
          HymnDetailRoute.name,
          args: HymnDetailRouteArgs(key: key, hymnId: hymnId),
          initialChildren: children,
        );

  static const String name = 'HymnDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HymnDetailRouteArgs>();
      return HymnDetailPage(key: args.key, hymnId: args.hymnId);
    },
  );
}

class HymnDetailRouteArgs {
  const HymnDetailRouteArgs({this.key, required this.hymnId});

  final Key? key;

  final String hymnId;

  @override
  String toString() {
    return 'HymnDetailRouteArgs{key: $key, hymnId: $hymnId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HymnDetailRouteArgs) return false;
    return key == other.key && hymnId == other.hymnId;
  }

  @override
  int get hashCode => key.hashCode ^ hymnId.hashCode;
}

/// generated route for
/// [ManageTemplatesPage]
class ManageTemplatesRoute extends PageRouteInfo<void> {
  const ManageTemplatesRoute({List<PageRouteInfo>? children})
      : super(ManageTemplatesRoute.name, initialChildren: children);

  static const String name = 'ManageTemplatesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ManageTemplatesPage();
    },
  );
}

/// generated route for
/// [MoreBiblesPage]
class MoreBiblesRoute extends PageRouteInfo<void> {
  const MoreBiblesRoute({List<PageRouteInfo>? children})
      : super(MoreBiblesRoute.name, initialChildren: children);

  static const String name = 'MoreBiblesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MoreBiblesPage();
    },
  );
}

/// generated route for
/// [OnboardingPage]
class OnboardingRoute extends PageRouteInfo<void> {
  const OnboardingRoute({List<PageRouteInfo>? children})
      : super(OnboardingRoute.name, initialChildren: children);

  static const String name = 'OnboardingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OnboardingPage();
    },
  );
}

/// generated route for
/// [PlanDaysPage]
class PlanDaysRoute extends PageRouteInfo<PlanDaysRouteArgs> {
  PlanDaysRoute({
    Key? key,
    required String planId,
    List<PageRouteInfo>? children,
  }) : super(
          PlanDaysRoute.name,
          args: PlanDaysRouteArgs(key: key, planId: planId),
          initialChildren: children,
        );

  static const String name = 'PlanDaysRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PlanDaysRouteArgs>();
      return PlanDaysPage(key: args.key, planId: args.planId);
    },
  );
}

class PlanDaysRouteArgs {
  const PlanDaysRouteArgs({this.key, required this.planId});

  final Key? key;

  final String planId;

  @override
  String toString() {
    return 'PlanDaysRouteArgs{key: $key, planId: $planId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlanDaysRouteArgs) return false;
    return key == other.key && planId == other.planId;
  }

  @override
  int get hashCode => key.hashCode ^ planId.hashCode;
}

/// generated route for
/// [PlusPage]
class PlusRoute extends PageRouteInfo<void> {
  const PlusRoute({List<PageRouteInfo>? children})
      : super(PlusRoute.name, initialChildren: children);

  static const String name = 'PlusRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PlusPage();
    },
  );
}

/// generated route for
/// [RoadAheadPage]
class RoadAheadRoute extends PageRouteInfo<void> {
  const RoadAheadRoute({List<PageRouteInfo>? children})
      : super(RoadAheadRoute.name, initialChildren: children);

  static const String name = 'RoadAheadRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RoadAheadPage();
    },
  );
}

/// generated route for
/// [RoadShareCardPage]
class RoadShareCardRoute extends PageRouteInfo<RoadShareCardRouteArgs> {
  RoadShareCardRoute({
    Key? key,
    required int day,
    required int totalDays,
    required String planTitle,
    int streak = 0,
    String? passage,
    String? landmarkTitle,
    String? landmarkArt,
    List<PageRouteInfo>? children,
  }) : super(
          RoadShareCardRoute.name,
          args: RoadShareCardRouteArgs(
            key: key,
            day: day,
            totalDays: totalDays,
            planTitle: planTitle,
            streak: streak,
            passage: passage,
            landmarkTitle: landmarkTitle,
            landmarkArt: landmarkArt,
          ),
          initialChildren: children,
        );

  static const String name = 'RoadShareCardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RoadShareCardRouteArgs>();
      return RoadShareCardPage(
        key: args.key,
        day: args.day,
        totalDays: args.totalDays,
        planTitle: args.planTitle,
        streak: args.streak,
        passage: args.passage,
        landmarkTitle: args.landmarkTitle,
        landmarkArt: args.landmarkArt,
      );
    },
  );
}

class RoadShareCardRouteArgs {
  const RoadShareCardRouteArgs({
    this.key,
    required this.day,
    required this.totalDays,
    required this.planTitle,
    this.streak = 0,
    this.passage,
    this.landmarkTitle,
    this.landmarkArt,
  });

  final Key? key;

  final int day;

  final int totalDays;

  final String planTitle;

  final int streak;

  final String? passage;

  final String? landmarkTitle;

  final String? landmarkArt;

  @override
  String toString() {
    return 'RoadShareCardRouteArgs{key: $key, day: $day, totalDays: $totalDays, planTitle: $planTitle, streak: $streak, passage: $passage, landmarkTitle: $landmarkTitle, landmarkArt: $landmarkArt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RoadShareCardRouteArgs) return false;
    return key == other.key &&
        day == other.day &&
        totalDays == other.totalDays &&
        planTitle == other.planTitle &&
        streak == other.streak &&
        passage == other.passage &&
        landmarkTitle == other.landmarkTitle &&
        landmarkArt == other.landmarkArt;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      day.hashCode ^
      totalDays.hashCode ^
      planTitle.hashCode ^
      streak.hashCode ^
      passage.hashCode ^
      landmarkTitle.hashCode ^
      landmarkArt.hashCode;
}

/// generated route for
/// [ScriptureShareCardPage]
class ScriptureShareCardRoute
    extends PageRouteInfo<ScriptureShareCardRouteArgs> {
  ScriptureShareCardRoute({
    Key? key,
    required String reference,
    required List<({int number, String text})> verses,
    List<PageRouteInfo>? children,
  }) : super(
          ScriptureShareCardRoute.name,
          args: ScriptureShareCardRouteArgs(
            key: key,
            reference: reference,
            verses: verses,
          ),
          initialChildren: children,
        );

  static const String name = 'ScriptureShareCardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ScriptureShareCardRouteArgs>();
      return ScriptureShareCardPage(
        key: args.key,
        reference: args.reference,
        verses: args.verses,
      );
    },
  );
}

class ScriptureShareCardRouteArgs {
  const ScriptureShareCardRouteArgs({
    this.key,
    required this.reference,
    required this.verses,
  });

  final Key? key;

  final String reference;

  final List<({int number, String text})> verses;

  @override
  String toString() {
    return 'ScriptureShareCardRouteArgs{key: $key, reference: $reference, verses: $verses}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ScriptureShareCardRouteArgs) return false;
    return key == other.key &&
        reference == other.reference &&
        const ListEquality<({int number, String text})>().equals(
          verses,
          other.verses,
        );
  }

  @override
  int get hashCode =>
      key.hashCode ^
      reference.hashCode ^
      const ListEquality<({int number, String text})>().hash(verses);
}

/// generated route for
/// [SettingsTabScreen]
class SettingsTabRoute extends PageRouteInfo<void> {
  const SettingsTabRoute({List<PageRouteInfo>? children})
      : super(SettingsTabRoute.name, initialChildren: children);

  static const String name = 'SettingsTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SettingsTabScreen();
    },
  );
}

/// generated route for
/// [ShareCardPage]
class ShareCardRoute extends PageRouteInfo<ShareCardRouteArgs> {
  ShareCardRoute({
    Key? key,
    required String hymnNumber,
    required String title,
    String body = '',
    List<({String label, String text})> parts = const [],
    List<PageRouteInfo>? children,
  }) : super(
          ShareCardRoute.name,
          args: ShareCardRouteArgs(
            key: key,
            hymnNumber: hymnNumber,
            title: title,
            body: body,
            parts: parts,
          ),
          initialChildren: children,
        );

  static const String name = 'ShareCardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ShareCardRouteArgs>();
      return ShareCardPage(
        key: args.key,
        hymnNumber: args.hymnNumber,
        title: args.title,
        body: args.body,
        parts: args.parts,
      );
    },
  );
}

class ShareCardRouteArgs {
  const ShareCardRouteArgs({
    this.key,
    required this.hymnNumber,
    required this.title,
    this.body = '',
    this.parts = const [],
  });

  final Key? key;

  final String hymnNumber;

  final String title;

  final String body;

  final List<({String label, String text})> parts;

  @override
  String toString() {
    return 'ShareCardRouteArgs{key: $key, hymnNumber: $hymnNumber, title: $title, body: $body, parts: $parts}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ShareCardRouteArgs) return false;
    return key == other.key &&
        hymnNumber == other.hymnNumber &&
        title == other.title &&
        body == other.body &&
        const ListEquality<({String label, String text})>().equals(
          parts,
          other.parts,
        );
  }

  @override
  int get hashCode =>
      key.hashCode ^
      hymnNumber.hashCode ^
      title.hashCode ^
      body.hashCode ^
      const ListEquality<({String label, String text})>().hash(parts);
}

/// generated route for
/// [SponsorPage]
class SponsorRoute extends PageRouteInfo<void> {
  const SponsorRoute({List<PageRouteInfo>? children})
      : super(SponsorRoute.name, initialChildren: children);

  static const String name = 'SponsorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SponsorPage();
    },
  );
}

/// generated route for
/// [StreakPage]
class StreakRoute extends PageRouteInfo<void> {
  const StreakRoute({List<PageRouteInfo>? children})
      : super(StreakRoute.name, initialChildren: children);

  static const String name = 'StreakRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const StreakPage();
    },
  );
}

/// generated route for
/// [TabletEditorPage]
class TabletEditorRoute extends PageRouteInfo<TabletEditorRouteArgs> {
  TabletEditorRoute({
    Key? key,
    String? noteId,
    String? initialMarkdown,
    String? templateId,
    List<PageRouteInfo>? children,
  }) : super(
          TabletEditorRoute.name,
          args: TabletEditorRouteArgs(
            key: key,
            noteId: noteId,
            initialMarkdown: initialMarkdown,
            templateId: templateId,
          ),
          initialChildren: children,
        );

  static const String name = 'TabletEditorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TabletEditorRouteArgs>(
        orElse: () => const TabletEditorRouteArgs(),
      );
      return TabletEditorPage(
        key: args.key,
        noteId: args.noteId,
        initialMarkdown: args.initialMarkdown,
        templateId: args.templateId,
      );
    },
  );
}

class TabletEditorRouteArgs {
  const TabletEditorRouteArgs({
    this.key,
    this.noteId,
    this.initialMarkdown,
    this.templateId,
  });

  final Key? key;

  final String? noteId;

  final String? initialMarkdown;

  final String? templateId;

  @override
  String toString() {
    return 'TabletEditorRouteArgs{key: $key, noteId: $noteId, initialMarkdown: $initialMarkdown, templateId: $templateId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TabletEditorRouteArgs) return false;
    return key == other.key &&
        noteId == other.noteId &&
        initialMarkdown == other.initialMarkdown &&
        templateId == other.templateId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      noteId.hashCode ^
      initialMarkdown.hashCode ^
      templateId.hashCode;
}

/// generated route for
/// [TabletsTabScreen]
class TabletsTabRoute extends PageRouteInfo<void> {
  const TabletsTabRoute({List<PageRouteInfo>? children})
      : super(TabletsTabRoute.name, initialChildren: children);

  static const String name = 'TabletsTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TabletsTabScreen();
    },
  );
}

/// generated route for
/// [TemplateEditorPage]
class TemplateEditorRoute extends PageRouteInfo<TemplateEditorRouteArgs> {
  TemplateEditorRoute({
    Key? key,
    String? templateId,
    String initialName = '',
    String initialIcon = 'church',
    List<TemplateSection> initialSections = const [],
    List<PageRouteInfo>? children,
  }) : super(
          TemplateEditorRoute.name,
          args: TemplateEditorRouteArgs(
            key: key,
            templateId: templateId,
            initialName: initialName,
            initialIcon: initialIcon,
            initialSections: initialSections,
          ),
          initialChildren: children,
        );

  static const String name = 'TemplateEditorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TemplateEditorRouteArgs>(
        orElse: () => const TemplateEditorRouteArgs(),
      );
      return TemplateEditorPage(
        key: args.key,
        templateId: args.templateId,
        initialName: args.initialName,
        initialIcon: args.initialIcon,
        initialSections: args.initialSections,
      );
    },
  );
}

class TemplateEditorRouteArgs {
  const TemplateEditorRouteArgs({
    this.key,
    this.templateId,
    this.initialName = '',
    this.initialIcon = 'church',
    this.initialSections = const [],
  });

  final Key? key;

  final String? templateId;

  final String initialName;

  final String initialIcon;

  final List<TemplateSection> initialSections;

  @override
  String toString() {
    return 'TemplateEditorRouteArgs{key: $key, templateId: $templateId, initialName: $initialName, initialIcon: $initialIcon, initialSections: $initialSections}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TemplateEditorRouteArgs) return false;
    return key == other.key &&
        templateId == other.templateId &&
        initialName == other.initialName &&
        initialIcon == other.initialIcon &&
        const ListEquality<TemplateSection>().equals(
          initialSections,
          other.initialSections,
        );
  }

  @override
  int get hashCode =>
      key.hashCode ^
      templateId.hashCode ^
      initialName.hashCode ^
      initialIcon.hashCode ^
      const ListEquality<TemplateSection>().hash(initialSections);
}

/// generated route for
/// [TodayTabScreen]
class TodayTabRoute extends PageRouteInfo<void> {
  const TodayTabRoute({List<PageRouteInfo>? children})
      : super(TodayTabRoute.name, initialChildren: children);

  static const String name = 'TodayTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TodayTabScreen();
    },
  );
}
