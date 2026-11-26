import 'package:material_ui/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Icon for a template's stored icon key (see `templateIconKeys`).
IconData templateIcon(String key) => switch (key) {
      'church' => PhosphorIcons.church(),
      'book' => PhosphorIcons.bookOpenText(),
      'pray' => PhosphorIcons.handsPraying(),
      'group' => PhosphorIcons.usersThree(),
      'sunrise' => PhosphorIcons.sunHorizon(),
      _ => PhosphorIcons.heart(),
    };

IconData sectionTypeIcon(String name) => switch (name) {
      'heading' => PhosphorIcons.textHOne(),
      'text' => PhosphorIcons.textAlignLeft(),
      'bullet' => PhosphorIcons.listBullets(),
      'checklist' => PhosphorIcons.checkSquare(),
      'scripture' => PhosphorIcons.bookOpenText(),
      _ => PhosphorIcons.textbox(),
    };
