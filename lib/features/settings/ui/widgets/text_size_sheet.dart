import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/settings/ui/widgets/font_size_control.dart';

/// Reading text size in a bottom sheet, shared by the Bible reader and the
/// hymn page. The text behind the sheet resizes live because the pages watch
/// the font scale provider.
Future<void> showTextSizeSheet(BuildContext context, {required String title}) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(title,
                  style:
                      LumText.title2.copyWith(color: context.lum.textPrimary)),
            ),
            const SizedBox(height: 16),
            const Flexible(
                child: SingleChildScrollView(child: FontSizeControl())),
          ],
        ),
      ),
    ),
  );
}
