/// Utility to convert technical exceptions into user-friendly error messages
class ErrorMessageHelper {
  const ErrorMessageHelper._();

  /// Convert an exception into a user-friendly error message
  /// 
  /// Detects common error types:
  /// - Network errors (SocketException, connection failures)
  /// - Authentication errors
  /// - Generic errors
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) {
      return 'Something went wrong. Please try again.';
    }

    final errorString = error.toString().toLowerCase();

    // Network/connectivity errors
    if (_isNetworkError(errorString)) {
      return 'Couldn\'t connect. Check your internet connection and try again.';
    }

    // Authentication errors
    if (_isAuthError(errorString)) {
      return 'Please sign in to view your recordings.';
    }

    // Generic error fallback
    return 'Something went wrong. Please try again.';
  }

  /// Check if error is a network/connectivity issue
  static bool _isNetworkError(String errorString) {
    return errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('no address associated with hostname') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timed out') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('no internet connection') ||
        errorString.contains('clientexception') && errorString.contains('socket');
  }

  /// Check if error is an authentication issue
  static bool _isAuthError(String errorString) {
    return errorString.contains('unauthorized') ||
        errorString.contains('authentication') ||
        errorString.contains('invalid jwt') ||
        errorString.contains('session') && errorString.contains('expired') ||
        errorString.contains('401');
  }
}

