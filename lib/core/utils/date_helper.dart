import 'package:intl/intl.dart';

class DateHelper {
  DateHelper._();


  static String formatFull(DateTime date) =>
      DateFormat('EEEE, d MMMM yyyy').format(date);

  static String formatMedium(DateTime date) =>
      DateFormat('d MMMM yyyy').format(date);

  static String formatShort(DateTime date) =>
      DateFormat('dd/MM/yy').format(date);

  /// Returns how many days until [expiryDate].
  /// Negative = already expired.
  static int daysUntil(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry =
        DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  static String daysLabel(int days) {
    if (days < 0) return '${days.abs()}d ago';
    if (days == 0) return 'Today!';
    if (days == 1) return '1 day left';
    return '$days days left';
  }

  static String statusLabel(int days) {
    if (days < 0) return 'Expired ${days.abs()} day(s) ago';
    if (days == 0) return 'Expires today!';
    if (days <= 2) return 'Expires in $days day(s) — Near expiry';
    return 'Expires in $days days — Fresh';
  }

  /// Returns the DateTime to fire a "2 days before" notification at 09:00.
  /// Returns null if the target time is already in the past.
  static DateTime? twoDaysBefore(DateTime expiryDate) {
    final target = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
      9,
    ).subtract(const Duration(days: 2));
    return target.isAfter(DateTime.now()) ? target : null;
  }

  /// Returns the DateTime to fire an "expires today" notification at 08:00.
  /// Returns null if the target time is already in the past.
  static DateTime? onExpiryDay(DateTime expiryDate) {
    final target = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
      8,
    );
    return target.isAfter(DateTime.now()) ? target : null;
  }
}