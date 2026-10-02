/// A single, controlled date source for the offline stakeholder demo.
abstract final class DemoClock {
  static DateTime _now = DateTime.now();

  static DateTime get now => _now;

  static void set(DateTime value) => _now = value;

  static void reset() => _now = DateTime.now();

  static DateTime daysAgo(int days, {int hour = 10}) => DateTime(
    _now.year,
    _now.month,
    _now.day,
    hour,
  ).subtract(Duration(days: days));

  static DateTime daysFromNow(int days, {int hour = 10}) =>
      DateTime(_now.year, _now.month, _now.day, hour).add(Duration(days: days));
}
