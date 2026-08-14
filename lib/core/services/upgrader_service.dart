import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

class BackendUpgraderStore extends UpgraderStore {
  BackendUpgraderStore({required this.platformKey, required this.manifestUrl});

  final String platformKey; // 'android' or 'ios'
  final String manifestUrl;

  @override
  Future<UpgraderVersionInfo> getVersionInfo({
    required UpgraderState state,
    required Version installedVersion,
    required String? country,
    required String? language,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(manifestUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return UpgraderVersionInfo(installedVersion: installedVersion);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final platformData = data[platformKey] as Map<String, dynamic>;

      return UpgraderVersionInfo(
        appStoreListingURL: platformData['url'] as String?,
        appStoreVersion: Version.parse(platformData['version'] as String),
        installedVersion: installedVersion,
        releaseNotes: platformData['releaseNotes'] as String?,
        isCriticalUpdate: platformData['critical'] as bool?,
        minAppVersion: platformData['minVersion'] != null
            ? Version.parse(platformData['minVersion'] as String)
            : null,
      );
    } catch (e) {
      // Fail closed: report no update rather than crash the check.
      return UpgraderVersionInfo(installedVersion: installedVersion);
    }
  }
}