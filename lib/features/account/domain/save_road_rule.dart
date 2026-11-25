/// Days a reader completes before "Save your road" is offered.
const saveRoadAfterDays = 3;

/// Offer the sheet once, when the completed-day count goes from 2 to 3, and only
/// to an unsaved reader who has not already seen it. Pure so it is testable.
bool shouldPromptSaveRoad({
  required int? previousDays,
  required int days,
  required bool accountLoaded,
  required bool saved,
  required bool alreadyPrompted,
}) =>
    accountLoaded &&
    previousDays != null &&
    days == previousDays + 1 && // one new day, not a sync jump
    days == saveRoadAfterDays &&
    !saved &&
    !alreadyPrompted;
