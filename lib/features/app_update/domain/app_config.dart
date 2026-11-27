/// Remote app config: `{"minVersion","latestVersion","maintenance",
/// "maintenanceMessage","storeUrls":{"ios","android"}}`.
class AppConfig {
  const AppConfig({
    required this.minVersion,
    required this.latestVersion,
    this.maintenance = false,
    this.maintenanceMessage,
    this.iosStoreUrl,
    this.androidStoreUrl,
  });

  final String minVersion;
  final String latestVersion;
  final bool maintenance;
  final String? maintenanceMessage;
  final String? iosStoreUrl;
  final String? androidStoreUrl;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final urls = json['storeUrls'];
    return AppConfig(
      minVersion: json['minVersion'] as String,
      latestVersion: json['latestVersion'] as String,
      maintenance: json['maintenance'] == true,
      maintenanceMessage: json['maintenanceMessage'] as String?,
      iosStoreUrl: urls is Map ? urls['ios'] as String? : null,
      androidStoreUrl: urls is Map ? urls['android'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'minVersion': minVersion,
        'latestVersion': latestVersion,
        'maintenance': maintenance,
        'maintenanceMessage': maintenanceMessage,
        'storeUrls': {'ios': iosStoreUrl, 'android': androidStoreUrl},
      };

  /// Same config with maintenance off: maintenance is only honoured from a
  /// fresh fetch, never from a cached copy.
  AppConfig withoutMaintenance() => AppConfig(
        minVersion: minVersion,
        latestVersion: latestVersion,
        maintenanceMessage: maintenanceMessage,
        iosStoreUrl: iosStoreUrl,
        androidStoreUrl: androidStoreUrl,
      );
}

enum UpdateStatus { none, optional, forced, maintenance }

/// Compares dotted versions numerically ("0.10.0" > "0.9.0"). Ignores any
/// `+build` or `-pre` suffix; missing parts count as 0.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split(RegExp(r'[+-]'))
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d.sign;
  }
  return 0;
}

/// Forced beats maintenance beats optional. No config (offline, no cache)
/// means [UpdateStatus.none]: fail open, never lock anyone out on a guess.
UpdateStatus decideStatus({
  required String installed,
  required AppConfig? config,
  String? dismissedLatest,
  bool maintenanceDismissed = false,
}) {
  if (config == null) return UpdateStatus.none;
  if (compareVersions(installed, config.minVersion) < 0) {
    return UpdateStatus.forced;
  }
  if (config.maintenance && !maintenanceDismissed) {
    return UpdateStatus.maintenance;
  }
  if (compareVersions(installed, config.latestVersion) < 0 &&
      dismissedLatest != config.latestVersion) {
    return UpdateStatus.optional;
  }
  return UpdateStatus.none;
}

/// Store link for this platform: the config's own URL when it has one, else a
/// hard-coded fallback so the gate button always has somewhere to go.
String storeUrlFor(AppConfig? config, {required bool ios}) {
  final url = ios ? config?.iosStoreUrl : config?.androidStoreUrl;
  if (url != null && url.isNotEmpty) return url;
  // ponytail: replace the iOS fallback with the real App Store id link
  // (https://apps.apple.com/app/id<id>) once the listing exists.
  return ios
      ? 'https://apps.apple.com/'
      : 'https://play.google.com/store/apps/details?id=com.daoxstudio.lumway';
}
