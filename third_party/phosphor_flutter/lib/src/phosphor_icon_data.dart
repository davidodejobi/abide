library phosphor_flutter;

import 'package:flutter/widgets.dart';

// Patched for Flutter >= 3.47: IconData is final and its constructor requires
// literal arguments (@RecordUse), so the wrapper classes are gone and every
// generated icon is a plain const IconData. Duotone renders its primary glyph only.
typedef PhosphorIconData = IconData;
typedef PhosphorFlatIconData = IconData;
typedef PhosphorDuotoneIconData = IconData;
