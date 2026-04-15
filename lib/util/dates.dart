
class DateHelper {

  // Whether the day of the given date has has already passed (starting the next day)
  static bool isDatePassed(DateTime date) => date.add(const Duration(days: 1)).isBefore(DateTime.now());

  // Whether the day of the given date is today (0:00 to 23:59)
  static bool isDateToday(DateTime date) {
    DateTime now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Whether the given today is between the given start and end date (inclusive), hour/minutes are ignored
  static bool isDateSpanToday(DateTime startDate, DateTime endDate) => isWithinDateSpan(startDate, endDate, DateTime.now());

  static bool isWithinDateSpan(DateTime startDate, DateTime endDate, DateTime toCheck) {
    return (startDate.isBefore(toCheck) && endDate.isAfter(toCheck)) || isDateToday(startDate) || isDateToday(endDate);
  }

  static String formatDate(DateTime date, {includeYear = true, shortMonth = false, useRelative = true, useFullYear = false}) {
    var now = DateTime.now();

    if (useRelative && date.day == now.day && date.month == now.month && date.year == now.year) {
      return "Heute";
    }
    if (useRelative && date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
      return "Gestern";
    }

    return "${date.day}. ${shortMonth ? shortNameOfMonth(date.month) : nameOfMonth(date.month)} ${includeYear ? date.year.toString().substring(useFullYear ? 0 : 2) : ""}".trimRight();
  }

  static String formatWeek(DateTime startDate, DateTime endDate) {
    return "${startDate.day}. - ${formatDate(endDate, useRelative: false)}";
  }

  static String formatDateDifference(DateTime date, {useAbbreviations = false}) {
    var now = DateTime.now();
    var difference = now.difference(date);

    String prefix = difference.isNegative ? "in" : "vor";
    // fix: replace Duration.inDays, which is rounded down (number of entire days), we count fractional days as whole days
    int days = (difference.inMicroseconds / Duration.microsecondsPerDay).abs().ceil();

    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return "Heute";
    }
    if (days == 1 && difference.isNegative) {
      return "Morgen";
    }
    if (days == 1) {
      return "Gestern";
    }
    if (days < 31 || (useAbbreviations && days < 365)) {
      return "$prefix $days${useAbbreviations ? "d" : " Tagen"}";
    }
    if (days < 365) {
      int months = (days / 30).floor();
      return "$prefix $months${useAbbreviations ? "m" : " Monat${months > 1 ? "en" : ""}"}";
    }
    int years = (days / 365).floor();
    return "$prefix $years${useAbbreviations ? "y" : " Jahr${years > 1 ? "e" : ""}"}";
  }

  static String formatWeekDifference(DateTime startDate, DateTime endDate, {useAbbreviations = false}) {
    var now = DateTime.now();
    bool isOver = isDatePassed(endDate);
    bool isCurrentWeek = now.isAfter(startDate) && !isOver;
    if (isCurrentWeek) {
      return "Diese Woche";
    }

    return formatDateDifference(isOver ? endDate : startDate, useAbbreviations: useAbbreviations);
  }

  static String nameOfMonth(int month) {
    return switch (month) {
      1 => "Januar",
      2 => "Februar",
      3 => "März",
      4 => "April",
      5 => "Mai",
      6 => "Juni",
      7 => "Juli",
      8 => "August",
      9 => "September",
      10 => "Oktober",
      11 => "November",
      12 => "Dezember",
      _ => "$month.",
    };
  }

  static String shortNameOfMonth(int month) {
    return switch (month) {
      1 => "Jan",
      2 => "Feb",
      3 => "Mär",
      4 => "Apr",
      5 => "Mai",
      6 => "Jun",
      7 => "Jul",
      8 => "Aug",
      9 => "Sep",
      10 => "Okt",
      11 => "Nov",
      12 => "Dez",
      _ => "$month.",
    };
  }

  static String shortNameOfWeekday(int weekday) {
    return switch (weekday) {
      1 => "Mo",
      2 => "Di",
      3 => "Mi",
      4 => "Do",
      5 => "Fr",
      6 => "Sa",
      7 => "So",
      _ => "$weekday.",
    };
  }

}
