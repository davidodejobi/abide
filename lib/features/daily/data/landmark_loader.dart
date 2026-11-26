import 'package:flutter/services.dart';

import '../domain/landmark_glb_loader.dart';
import 'glb_cache.dart';

/// Cache, bundle, then CDN (see [LandmarkGlbLoader]); one for the app, shared
/// by the landmark sheet and the bulk download.
LandmarkGlbLoader createLandmarkLoader() => LandmarkGlbLoader(
      cache: createGlbCache(),
      loadBundled: (art) async =>
          (await rootBundle.load('assets/images/road/models/$art.glb'))
              .buffer
              .asUint8List(),
      fetch: fetchGlb,
    );

/// The app's one loader, built on first use.
final LandmarkGlbLoader sharedLandmarkLoader = createLandmarkLoader();
