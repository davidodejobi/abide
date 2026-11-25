import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Lists the tablets that link to a given verse; tapping a row opens that
/// tablet in the editor.
class BacklinksSheet extends StatelessWidget {
  const BacklinksSheet(
      {super.key, required this.reference, required this.items});

  final String reference;
  final List<BibleBacklink> items;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Semantics(
                header: true,
                child: Text(BibleStrings.linkedFrom(reference),
                    style: LumText.title3.copyWith(color: c.textPrimary)),
              ),
            ),
            for (final item in items)
              ListTile(
                minTileHeight: LumSize.rowMin,
                leading: Icon(PhosphorIcons.note(), color: c.iconDefault),
                title: Text(
                  item.noteTitle.trim().isEmpty
                      ? BibleStrings.untitledNote
                      : item.noteTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LumText.body.copyWith(color: c.textPrimary),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  context.router.push(TabletEditorRoute(noteId: item.noteId));
                },
              ),
            const SizedBox(height: LumSpace.sm),
          ],
        ),
      ),
    );
  }
}
