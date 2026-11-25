/// Days a reader completes before "Save your road" is offered.
const saveRoadAfterDays = 3;

/// Offer the sheet once, when the completed-day count crosses day 3, and only
/// to an unsaved reader who has not already seen it. Pure so it is testable.
bool shouldPromptSaveRoad({
  required int? previousDays,
  required int days,
  required bool saved,
  required bool alreadyPrompted,
}) =>
    previousDays != null &&
    previousDays < saveRoadAfterDays &&
    days >= saveRoadAfterDays &&
    !saved &&
    !alreadyPrompted;
