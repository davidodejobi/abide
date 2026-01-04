import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  Future<void> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        debugPrint('Could not launch $url');
        // Try adding https if missing
        if (!url.startsWith('http')) {
          final newUrl = 'https://$url';
          final newUri = Uri.parse(newUrl);
          if (await canLaunchUrl(newUri)) {
            await launchUrl(newUri, mode: LaunchMode.platformDefault);
            return;
          }
        }
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      rethrow;
    }
  }

  Future<void> launchEmail({
    required String email,
    String? subject,
    String? body,
  }) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQueryParameters(<String, String>{
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      }),
    );

    await _launch(emailLaunchUri);
  }

  Future<void> launchPhone(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await _launch(launchUri);
  }

  Future<void> launchWhatsapp({required String phone, String? message}) async {
    String url = 'https://wa.me/$phone';
    if (message != null) {
      url += '?text=${Uri.encodeComponent(message)}';
    }
    // WhatsApp URLs work best with external application mode or platform default
    await openUrl(url);
  }

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $uri');
      throw 'Could not launch $uri';
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
