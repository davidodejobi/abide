import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_tab_screen.dart';

/// The reader as a pushed route. Opened with a [planId] and [dayIndex] from
/// Start reading on Today, it carries the gold Mark read.
@RoutePage()
class BibleReaderPage extends StatelessWidget {
  const BibleReaderPage({super.key, this.planId, this.dayIndex});

  final String? planId;
  final int? dayIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LumPageBackground(
        child: SafeArea(
          bottom: false,
          // controlsAppNav: false -- this is a pushed route with no bottom nav of
          // its own. Left at the default, scrolling here hides the DASHBOARD's
          // nav bar, and it is still hidden when the user pops back, with
          // nothing on screen to explain where it went.
          child: BibleTabScreen(
            controlsAppNav: false,
            planId: planId,
            dayIndex: dayIndex,
          ),
        ),
      ),
    );
  }
}
