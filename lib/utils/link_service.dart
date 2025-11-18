import 'package:url_launcher/url_launcher.dart';

/// Centralized service for opening URLs and email clients
class LinkService {
  const LinkService._();

  /// Open an email client with the specified recipient, subject, and body
  /// 
  /// This opens the user's default email app (not Resend/backend email).
  /// The user must manually send the email.
  /// 
  /// Returns true if the email client was opened successfully, false otherwise.
  static Future<bool> openEmail({
    required String to,
    String? subject,
    String? body,
  }) async {
    try {
      final uri = Uri(
        scheme: 'mailto',
        path: to,
        queryParameters: {
          if (subject != null) 'subject': subject,
          if (body != null) 'body': body,
        },
      );

      // Use launchUrl's return value directly (canLaunchUrl is handled by <queries> in manifest)
      final launched = await launchUrl(uri);
      return launched;
    } catch (e) {
      return false;
    }
  }

  /// Open a URL in the external browser
  /// 
  /// Uses LaunchMode.externalApplication to ensure it opens in the system browser,
  /// not an in-app webview.
  /// 
  /// Returns true if the URL was opened successfully, false otherwise.
  static Future<bool> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      // Use launchUrl's return value directly (canLaunchUrl is handled by <queries> in manifest)
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return launched;
    } catch (e) {
      return false;
    }
  }
}

