import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/services/share_service.dart';
import '../utils/services/url_launcher_service.dart';

final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService();
});

final urlLauncherServiceProvider = Provider<UrlLauncherService>((ref) {
  return UrlLauncherService();
});
