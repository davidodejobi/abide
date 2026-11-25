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
  static const shareError = 'Could not create image to share';
  static const dayRoad = 'Day road';
  static const nightRoad = 'Night road';
  static const plain = 'Plain';
  static const formatStatus = 'Status';
  static const formatSquare = 'Square';

  static String count(int n) => n == 1 ? '1 note' : '$n notes';
  static String noMatches(String q) => 'No notes match “$q”';
  static String loadError(Object e) => 'Could not load notes: $e';
  static String searchFailed(Object e) => 'Search failed: $e';
  static String hymnEyebrow(String number) => 'HYMN $number';
}
