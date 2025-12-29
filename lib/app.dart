import 'package:flutter/material.dart';

import 'presentation/pages/hymn_list_page.dart';

class OpenBaptistHymnal extends StatelessWidget {
  const OpenBaptistHymnal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Baptist Hymnal',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HymnListPage(),
    );
  }
}
