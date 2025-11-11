import 'package:intl/intl.dart';

/// Utility for formatting dates in the Library list
class DateFormatter {
  static String formatAsTodayTimeOrDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown date';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (recordDate == today) {
      // Today: show time only
      return 'Today • ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      // Other days: show date
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}
