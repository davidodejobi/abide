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
      body: const BibleTabScreen(),
    );
  }
}
