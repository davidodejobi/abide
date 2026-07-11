import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_tab_screen.dart';

@RoutePage()
class BibleReaderPage extends StatelessWidget {
  const BibleReaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      // controlsAppNav: false -- this is a pushed route with no bottom nav of its
      // own. Left at the default, scrolling here hides the DASHBOARD's nav bar,
      // and it is still hidden when the user pops back, with nothing on screen
      // to explain where it went.
      body: const BibleTabScreen(controlsAppNav: false),
    );
  }
}
