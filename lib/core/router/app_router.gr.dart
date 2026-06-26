// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [BibleReaderPage]
class BibleReaderRoute extends PageRouteInfo<void> {
  const BibleReaderRoute({List<PageRouteInfo>? children})
      : super(BibleReaderRoute.name, initialChildren: children);

  static const String name = 'BibleReaderRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const BibleReaderPage();
    },
  );
}

/// generated route for
/// [BibleTabScreen]
class BibleTabRoute extends PageRouteInfo<void> {
  const BibleTabRoute({List<PageRouteInfo>? children})
      : super(BibleTabRoute.name, initialChildren: children);

  static const String name = 'BibleTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const BibleTabScreen();
    },
  );
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
        const ListEquality().equals(verses, other.verses);
  }

  @override
  int get hashCode =>
      key.hashCode ^ reference.hashCode ^ const ListEquality().hash(verses);
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
    required String body,
    List<PageRouteInfo>? children,
  }) : super(
          ShareCardRoute.name,
          args: ShareCardRouteArgs(
            key: key,
            hymnNumber: hymnNumber,
            title: title,
            body: body,
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
      );
    },
  );
}

class ShareCardRouteArgs {
  const ShareCardRouteArgs({
    this.key,
    required this.hymnNumber,
    required this.title,
    required this.body,
  });

  final Key? key;

  final String hymnNumber;

  final String title;

  final String body;

  @override
  String toString() {
    return 'ShareCardRouteArgs{key: $key, hymnNumber: $hymnNumber, title: $title, body: $body}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ShareCardRouteArgs) return false;
    return key == other.key &&
        hymnNumber == other.hymnNumber &&
        title == other.title &&
        body == other.body;
  }

  @override
  int get hashCode =>
      key.hashCode ^ hymnNumber.hashCode ^ title.hashCode ^ body.hashCode;
}

/// generated route for
/// [TabletEditorPage]
class TabletEditorRoute extends PageRouteInfo<TabletEditorRouteArgs> {
  TabletEditorRoute({
    Key? key,
    String? noteId,
    String? initialMarkdown,
    List<PageRouteInfo>? children,
  }) : super(
          TabletEditorRoute.name,
          args: TabletEditorRouteArgs(
            key: key,
            noteId: noteId,
            initialMarkdown: initialMarkdown,
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
      );
    },
  );
}

class TabletEditorRouteArgs {
  const TabletEditorRouteArgs({this.key, this.noteId, this.initialMarkdown});

  final Key? key;

  final String? noteId;

  final String? initialMarkdown;

  @override
  String toString() {
    return 'TabletEditorRouteArgs{key: $key, noteId: $noteId, initialMarkdown: $initialMarkdown}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TabletEditorRouteArgs) return false;
    return key == other.key &&
        noteId == other.noteId &&
        initialMarkdown == other.initialMarkdown;
  }

  @override
  int get hashCode => key.hashCode ^ noteId.hashCode ^ initialMarkdown.hashCode;
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
