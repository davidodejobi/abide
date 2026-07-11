// GENERATED HELPER — not a test of anything.
//
// Flutter's --coverage only reports files that a test actually imports. Files
// nobody imports are omitted from lcov entirely rather than counted as 0%, so
// the headline number silently measures only the tested subset. That makes the
// gate both inflated AND fragile: the first test to touch a new file drags its
// uncovered lines into the denominator and coverage DROPS, failing CI as a
// punishment for writing a test.
//
// Importing every logic file here fixes the denominator, so the percentage
// means "of all our logic", and adding a test can only ever move it up.
//
// UI (lib/**/ui/**) is deliberately absent: it's excluded from the gate and
// verified by widget/golden tests instead. Generated code is absent for the
// same reason it's excluded from the gate.
//
// Regenerate with: tool/gen_coverage_helper.sh
// ignore_for_file: unused_import, directives_ordering
import 'package:openbaptisthymnal/core/app.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality_provider.dart';
import 'package:openbaptisthymnal/core/preferences/linking_preferences.dart';
import 'package:openbaptisthymnal/core/providers/app_info_provider.dart';
import 'package:openbaptisthymnal/core/providers/bottom_nav_provider.dart';
import 'package:openbaptisthymnal/core/providers/service_providers.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/bible_annotations_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/folders_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/tags_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/storage/database/fts_query.dart';
import 'package:openbaptisthymnal/core/storage/database/tables.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_service.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/core/theme/font_scale.dart';
import 'package:openbaptisthymnal/core/theme/font_scale_provider.dart';
import 'package:openbaptisthymnal/core/theme/theme.dart';
import 'package:openbaptisthymnal/core/theme/theme_provider.dart';
import 'package:openbaptisthymnal/core/utils/extensions/context_extensions.dart';
import 'package:openbaptisthymnal/core/utils/extensions/num_extensions.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';
import 'package:openbaptisthymnal/core/utils/extensions/widget_extensions.dart';
import 'package:openbaptisthymnal/core/utils/json_loader.dart';
import 'package:openbaptisthymnal/core/utils/services/file_storage_service.dart';
import 'package:openbaptisthymnal/core/utils/services/share_service.dart';
import 'package:openbaptisthymnal/core/utils/services/url_launcher_service.dart';
import 'package:openbaptisthymnal/core/utils/time_greeting.dart';
import 'package:openbaptisthymnal/core/utils/toast_helper.dart';
import 'package:openbaptisthymnal/core/widgets/split_orientation_toggle.dart';
import 'package:openbaptisthymnal/core/widgets/split_pane.dart';
import 'package:openbaptisthymnal/core/widgets/split_view.dart';
import 'package:openbaptisthymnal/features/bible/data/bible_repository.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_local_source.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_reading_position_source.dart';
import 'package:openbaptisthymnal/features/bible/domain/bible_link_resolver.dart';
import 'package:openbaptisthymnal/features/bible/domain/book_codes.dart';
import 'package:openbaptisthymnal/features/bible/domain/highlight_palette.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_reference_format.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/providers/pending_verse_highlight_provider.dart';
import 'package:openbaptisthymnal/features/bible/providers/verse_backlinks_provider.dart';
import 'package:openbaptisthymnal/features/bible/providers/verse_highlights_provider.dart';
import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';
import 'package:openbaptisthymnal/features/hymn/data/sources/local/favorites_local_source.dart';
import 'package:openbaptisthymnal/features/hymn/domain/get_hymn_for_split_view.dart';
import 'package:openbaptisthymnal/features/hymn/domain/get_hymns_by_language.dart';
import 'package:openbaptisthymnal/features/hymn/domain/hymn_link_resolver.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymn.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_core.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_index.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/model/lyrics.dart';
import 'package:openbaptisthymnal/features/hymn/model/stanza.dart';
import 'package:openbaptisthymnal/features/hymn/providers/favorites_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/onboarding/audio/onboarding_sfx.dart';
import 'package:openbaptisthymnal/features/onboarding/domain/seed_welcome_note.dart';
import 'package:openbaptisthymnal/features/onboarding/providers/onboarding_provider.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/tablets_repository.dart';
import 'package:openbaptisthymnal/features/tablet/data/sources/local/tablets_local_source.dart';
import 'package:openbaptisthymnal/features/tablet/domain/bible_autocomplete.dart';
import 'package:openbaptisthymnal/features/tablet/domain/insert_audio_node.dart';
import 'package:openbaptisthymnal/features/tablet/domain/link_autocomplete.dart';
import 'package:openbaptisthymnal/features/tablet/domain/parse_links.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_media.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_preview.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:openbaptisthymnal/main.dart';

void main() {}
