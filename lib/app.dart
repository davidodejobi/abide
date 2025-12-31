import 'package:flutter/material.dart';

import 'presentation/pages/hymn_list_page.dart';
import 'utils/theme/theme.dart';

class OpenBaptistHymnal extends StatelessWidget {
  const OpenBaptistHymnal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Baptist Hymnal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HymnListPage(),
    );
  }
}
