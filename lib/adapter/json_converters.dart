import 'package:json_annotation/json_annotation.dart';

class DateOnlyConverter implements JsonConverter<DateTime, String> {
  const DateOnlyConverter();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json);
  }

  @override
  String toJson(DateTime object) {
    return object.toIso8601String().split('T').first;
  }
}

class GoDateTimeConverter implements JsonConverter<DateTime, String> {
  const GoDateTimeConverter();

  @override
  DateTime fromJson(String json) {
    // DateTime.parse is smart enough to handle strings with or without 'Z'
    // and will return a local or UTC time accordingly.
    return DateTime.parse(json).toUtc();
  }

  @override
  String toJson(DateTime date) {
    // 1. .toUtc() ensures the string ends with 'Z'
    // 2. .toIso8601String() ensures the 'T' separator is used instead of a space
    return date.toUtc().toIso8601String();
  }
}
