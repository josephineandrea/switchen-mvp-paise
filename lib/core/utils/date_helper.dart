import 'package:intl/intl.dart';

class DateHelper {
  DateHelper._();

  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _timeFormat = DateFormat('HH:mm', 'id_ID');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Returns remaining time as human-readable string (e.g. "14:32")
  static String formatCountdown(DateTime expiry) {
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) return 'Kedaluwarsa';
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static bool isExpired(DateTime expiry) =>
      DateTime.now().isAfter(expiry);

  static bool isExpiringSoon(DateTime expiry, {Duration threshold = const Duration(hours: 3)}) {
    final diff = expiry.difference(DateTime.now());
    return !diff.isNegative && diff <= threshold;
  }
}
