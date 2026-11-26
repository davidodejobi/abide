import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';

/// Every user-facing string on the Notes screens, in one place until the ARB
/// move (DAO-131). Plain English, denomination-neutral.
abstract final class NotesStrings {
  static const notes = 'Notes';
  static const noNotesYet = 'No notes yet';
  static const searchHint = 'Search notes';
  static const newNote = 'New note';
  static const filter = 'Filter notes';
  static const clearFilter = 'Clear filter';
  static const untitled = 'Untitled';
  static const voiceNote = 'Voice note';
  static const photo = 'Photo';
  static const savedOnPhone = 'Saved on this phone';
  static const deleteNote = 'Delete note';
  static const noteDeleted = 'Note deleted';
  static const undo = 'Undo';
  static const emptyTitle = 'Your notes live here';
  static const emptyBody =
      'Write what you notice as you read. Link a verse or a hymn and it '
      'opens right from your note.';
  static const writeNote = 'Write a note';
  static const freeAndLocal = 'Notes are free and stay on this phone.';
  static const noteNotFound = 'Note not found';
  static const noteTags = 'Tags';
  static const moveToFolder = 'Move to folder';
  static const linksAndBacklinks = 'Links and backlinks';
  static const back = 'Back';
  static const titleHint = 'Title';
  static const folderEmpty = 'This folder is empty';
  static const folderEmptyBody = 'Move notes here from the editor.';
  static const tagEmpty = 'Nothing tagged here';
  static const tagEmptyBody = 'Add this tag to notes from the editor.';

  // Share
  static const shareImage = 'Share image';
  static const shareVerse = 'Share verse';
  static const shareHymn = 'Share hymn';
  static const appMark = 'Lumway';
  static const saveImage = 'Save image';
  static const copyText = 'Copy text';
  static const shareTextAction = 'Share text';
  static const imageSaved = 'Saved to your photos';
  static const saveDenied =
      'Photos access is off. Turn it on in Settings to save images.';
  static const saveError = 'Could not save the image';
  static const textCopied = 'Copied to clipboard';
  static const showReference = 'Show reference';
  static const includeLabel = 'Include';
  static const lookLabel = 'Look';
  static const shapeLabel = 'Shape';
  static const chorusLabel = 'Chorus';
  static const selectionLabel = 'Selection';
  static String stanzaLabel(int n) => 'Verse $n';
  static const shareError = 'Could not create image to share';
  static const dayRoad = 'Day road';
  static const nightRoad = 'Night road';
  static const plain = 'Plain';
  static const formatStatus = 'Status';
  static const formatSquare = 'Square';

  // Media blocks
  static const mediaMore = 'More options';
  static const mediaDragHandle = 'Drag to move';
  static const mediaDropHere = 'Drop here';
  static const imageTitle = 'Image';
  static const audioTitle = 'Recording';
  static const moveLabel = 'Move';
  static const moveUp = 'Move up';
  static const moveDown = 'Move down';
  static const sizeLabel = 'Size';
  static const sizeSmall = 'Small';
  static const sizeMedium = 'Medium';
  static const sizeFull = 'Full';
  static const alignLabel = 'Align';
  static const alignLeft = 'Left';
  static const alignCenter = 'Center';
  static const editCaption = 'Edit caption';
  static const addCaption = 'Add a caption';
  static const captionHint = 'Caption';
  static const rename = 'Rename';
  static const recordingName = 'Name';
  static const replaceImage = 'Replace image';
  static const shareFile = 'Share';
  static const deleteMedia = 'Delete';
  static const mediaDeleted = 'Removed from this note';
  static const speedLabel = 'Playback speed';
  static const fileMissing = 'This file is missing';
  static const remove = 'Remove';
  static const save = 'Save';
  static const cancel = 'Cancel';
  static const insert = 'Insert';
  static const insertCamera = 'Camera';
  static const insertPhotos = 'Photo library';
  static const insertRecord = 'Record a message';
  static const insertChecklist = 'Checklist';
  static const cameraDenied =
      'Camera access is off. Turn it on in Settings to take a photo.';
  static const noCamera = 'No camera is available on this device.';
  static const photosDenied =
      'Photos access is off. Turn it on in Settings to add an image.';
  static const play = 'Play';
  static const pause = 'Pause';

  // Templates
  static const blankNote = 'Blank note';
  static const blankNoteHint = 'Just an empty page';
  static const pinned = 'Pinned';
  static const pinnedPickerHint = 'Hold a card to pin or unpin';
  static const mine = 'Mine';
  static const builtIn = 'Built-in';
  static const createTemplate = 'Create template';
  static const close = 'Close';
  static const pin = 'Pin';
  static const unpin = 'Unpin';
  static const duplicate = 'Duplicate';
  static const previewSections = 'Preview sections';
  static const addedToMine = 'Added to Mine';
  static String copyName(String name) => '$name copy';
  static const templates = 'Templates';
  static const manageTemplates = 'Manage templates';
  static const manageTemplatesHint = 'Pin, edit or add your own';
  static const pinnedManageHeader = 'Pinned (shown first in New note)';
  static const builtInFootnote =
      'Built-in templates can be duplicated, but not changed or deleted.';
  static const noOwnTemplates = 'Templates you create or save show up here.';
  static const edit = 'Edit';
  static const delete = 'Delete';
  static const dragToReorder = 'Drag to reorder';
  static String templateDeleted(String name) => '$name deleted';
  static const newTemplate = 'New template';
  static const editTemplate = 'Edit template';
  static const templateName = 'Name';
  static const templateNameHint = 'Name your template to save it';
  static const iconLabel = 'Icon';
  static const sectionsLabel = 'Sections';
  static String sectionCount(int n) => n == 1 ? '1 section' : '$n sections';
  static const addSection = 'Add section';
  static const sectionName = 'Section name';
  static const renameSection = 'Rename section';
  static const removeSection = 'Remove section';
  static const saveTemplate = 'Save template';
  static const preview = 'Preview';
  static const saveAsTemplate = 'Save as template';
  static const noSectionsToSave = 'Nothing here to save as a template yet';
  static const noteOptions = 'Note options';
  static const emptyTemplateHint =
      'Start from a template so you are never starting from scratch';
  static const dismiss = 'Dismiss';
  static const chooseTemplate = 'Choose a template';

  static String iconName(String key) => switch (key) {
        'church' => 'Church',
        'book' => 'Book',
        'pray' => 'Prayer',
        'group' => 'Group',
        'sunrise' => 'Sunrise',
        _ => 'Heart',
      };

  static String sectionType(TemplateSectionType t) => switch (t) {
        TemplateSectionType.heading => 'Heading',
        TemplateSectionType.text => 'Text',
        TemplateSectionType.bullet => 'Bullet list',
        TemplateSectionType.checklist => 'Checklist',
        TemplateSectionType.scripture => 'Scripture',
        TemplateSectionType.field => 'Field',
      };

  static String sectionTypeHint(TemplateSectionType t) => switch (t) {
        TemplateSectionType.heading => 'A title that divides the note',
        TemplateSectionType.text => 'A title with a paragraph under it',
        TemplateSectionType.bullet => 'A title with a list under it',
        TemplateSectionType.checklist => 'A title with tick boxes',
        TemplateSectionType.scripture => 'A line for a passage to link',
        TemplateSectionType.field => 'A label with a value, like Speaker',
      };

  static String count(int n) => n == 1 ? '1 note' : '$n notes';
  static String noMatches(String q) => 'No notes match “$q”';
  static String loadError(Object e) => 'Could not load notes: $e';
  static String searchFailed(Object e) => 'Search failed: $e';
  static String hymnEyebrow(String number) => 'HYMN $number';

  // Recording
  static const recordTitle = 'Record a message';
  static const recordingNow = 'Recording';
  static const recordingPaused = 'Paused';
  static const recordingInterrupted = 'Interrupted, tap to resume';
  static const resume = 'Resume';
  static const addMarker = 'Add marker';
  static const finish = 'Finish';
  static const markers = 'Markers';
  static const markerLabelHint = 'Add a label (optional)';
  static const skip = 'Skip';
  static const saveLabel = 'Save label';
  static const lockOk = 'You can lock your phone, recording continues.';
  static const keepOpen = 'Keep Lumway open while recording.';
  static const screenStaysOn =
      'Your screen stays on while you record. Plug in for long messages, '
      'and keep your phone near the speaker.';
  static const saveRecordingTitle = 'Save this recording?';
  static const saveRecordingBody = 'Your message is not saved yet.';
  static const saveFailed = 'Could not save the recording. Try again.';
  static const keepRecording = 'Keep recording';
  static const discard = 'Discard';
  static const micOffTitle = 'Microphone access is off';
  static const micOffBody = 'Turn it on in Settings to record a message.';
  static const openSettings = 'Open Settings';
  static const micError = 'Could not start recording. Try again.';
  static const consentTitle = 'Your recordings, your choice';
  static const consentIntro =
      'Here is what happens to your audio before you record for the first time.';
  static const consentLocalTitle = 'Recordings stay on your phone';
  static const consentLocalBody =
      'Your audio is saved in this app on your phone and is not sent anywhere.';
  static const consentPolicyTitle = 'Respect your church\'s policy';
  static const consentPolicyBody =
      'Some churches ask that messages are not recorded. If you are not sure, '
      'ask a leader first.';
  static const consentStart = 'I understand, start recording';
  static const notNow = 'Not now';
  static const playerBack15 = 'Back 15 seconds';

  // Transcript
  static const transcribe = 'Transcribe';
  static const noteTab = 'Note';
  static const transcriptTab = 'Transcript';
  static const transcribeBody =
      'Free, and done on your phone. The audio is not uploaded.';
  static const transcriptUnavailable =
      'Transcript not available for this language yet';
  static const transcriptEmptyTitle = 'No transcript yet';
  static const transcriptResume = 'Resume';
  static const searchTranscript = 'Search transcript';
  static const copyToNote = 'Copy to note';
  static const transcriptCopied = 'Transcript added to your note';
  static const noSpeechFound = 'No speech found in this recording';
  static const speechDeniedTitle = 'Speech recognition is off';
  static const speechDeniedBody =
      'Allow speech recognition in Settings to transcribe on this phone.';
  static const transcribeFailedBody =
      'Something went wrong. What was done so far is saved.';
  static const modelDownloadTitle = 'Download the speech model';
  static String modelDownloadBody(int mb) =>
      'To transcribe on this phone, Lumway needs a one-time download of '
      'about $mb MB. It is kept on this phone and used for every transcript.';
  static const wifiOnly = 'Wi-Fi only';
  static const downloadAndStart = 'Download and transcribe';
  static const modelFailedTitle = 'Model download failed';
  static const modelFailedBody =
      'Check your connection (or turn off Wi-Fi only) and try again.';
  static const transcribingOnPhone = 'Transcribing on this phone';
  static const stepAudioPrepared = 'Audio prepared';
  static const stepWriting = 'Writing the transcript';
  static const stepReady = 'Ready to read';
  static const cancelTranscription = 'Cancel transcription';
  static const followAlong = 'Follow along';
  static const transcriptPrivacy = 'Made on this phone. May contain mistakes.';
  static const didNotFinish = 'The transcript did not finish';
  static const didNotFinishBody =
      'Your recording is safe on this phone. Nothing was lost.';
  static const whatHappened = 'What happened';
  static const whatYouCanDo = 'What you can do';
  static const tryAgainHint =
      'Try again, or close other apps first. Longer messages can take a '
      'while on older phones.';
  static const tryAgain = 'Try again';
  static const keepRecordingOnly = 'Keep the recording only';
  static const languageTitle = 'Language of the message';
  static const englishRowBody =
      'Matches your reading language. Free, on this phone.';
  static const yorubaRowBody =
      'Transcript not available for this language yet. Your recording and '
      'markers are saved.';
  static const otherLanguagesRow = 'Igbo, Hausa';
  static const unavailableRowBody =
      'Transcript not available for this language yet.';
  static const mixedLanguages =
      'Mixed languages? The transcript will be English only.';
  static const step1OpenSettings = '1. Open Settings';
  static const speechSettingsHint =
      'Find Lumway in the list, then turn on Speech Recognition.';
  static const notesAreSafe = 'Your notes are safe';
  static const notesAreSafeBody =
      'Writing, reading and playback still work without a transcript.';
  static const downloadingModelTitle = 'Downloading the speech model';
  static const replaceTitle = 'Replace transcript?';
  static const replaceBody =
      'The current transcript stays until the new one is finished.';
  static const replace = 'Replace';
  static const waitingForWifiTitle = 'Waiting for Wi-Fi';
  static const waitingForWifiBody =
      'The speech model is a one-time download. It waits for Wi-Fi unless you '
      'choose mobile data.';
  static const useMobileData = 'Use mobile data';
  static const stopping = 'Stopping...';
  static const readSaved = 'Read what was saved';
  static String stoppedAt(String at, String total) =>
      'The transcript stopped at $at of $total.';
  static const englishRowBodyFree = 'Free, on this phone.';
}
