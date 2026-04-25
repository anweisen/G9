import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:http/http.dart' as http;

import '../adapter/json_converters.dart';
import '../logic/choice.dart';
import '../logic/types.dart';

part 'kmapi.g.dart';

class KmApi {
  static const String kmapiBaseUrl = "https://kmapi.anweisen.net";
  static const String routeBavariaGymAbiNext = "/by/gym/abi/next";
  static String routeBavariaGymAbiYear(int year) => "/by/gym/abi/$year";


  static Future<AbiDates?> fetchAbiDates(int predictedYear) async {
    DateTime now = DateTime.now();
    int currentYear = now.year;

    // dates might not be available yet, fallback to previous year until to display
    for (int year = predictedYear; year >= currentYear; year--) {
      var selectedYearDates = await _fetchAbiDates(routeBavariaGymAbiYear(year));
      if (selectedYearDates != null) return selectedYearDates;
    }

    return await _fetchAbiDates(routeBavariaGymAbiNext);
  }

  static Future<AbiDates?> _fetchAbiDates(String route) async {
    try {
      final response = await http.get(
        Uri.parse("$kmapiBaseUrl$route"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        print("Abi Dates Fetch Success: ${response.body}");
        Map<String, dynamic> data = jsonDecode(response.body);
        return AbiDates.fromJson(data);
      } else {
        print("Abi Dates Fetch failed: ${response.statusCode} - ${response.body} (${response.request?.url.toString()})");
      }
    } catch (e) {
      print("Error during Abi Dates Fetch: $e");
    }

    return null;
  }

  static bool checkSubjectNameMatchesSubject(String subjectName, Subject subject) {
    String normalizedSubjectName = subjectName.trim().toLowerCase();
    return normalizedSubjectName.contains(subject.name.toLowerCase());
  }

  static List<(Subject, WrittenAbiExamDate)> sortWittenAbiExamDates(Map<Subject, WrittenAbiExamDate> subjectToDateMap) {
    List<(Subject, WrittenAbiExamDate)> sortedList = subjectToDateMap.entries
        .map((entry) => (entry.key, entry.value))
        .toList()
      ..sort((a, b) => a.$2.date.compareTo(b.$2.date));
    return sortedList;
  }

  static Map<Subject, WrittenAbiExamDate> mapSubjectsToWrittenExamDates(List<WrittenAbiExamDate> dates, List<Subject> subjects, Choice choice) {
    Map<Subject, WrittenAbiExamDate> subjectToDateMap = {};

    for (Subject subject in subjects) {
      WrittenAbiExamDate? examDate = findWrittenExamDateForSubject(dates, choice, subject);
      if (examDate != null) {
        subjectToDateMap[subject] = examDate;
      }
    }

    return subjectToDateMap;
  }

  static WrittenAbiExamDate? findWrittenExamDateForSubject(List<WrittenAbiExamDate> dates, Choice choice, Subject subject) {
    bool isEa = choice.isSubjectEa(subject);
    for (WrittenAbiExamDate date in dates) {
      if (isEa && !date.ea) continue;
      if (!isEa && !date.ga) continue;

      if (date.isRemaining) {
        if (date.excludedSubjectNames.isNotEmpty) {
          bool isExcluded = false;
          for (String excludedSubjectName in date.excludedSubjectNames) {
            if (checkSubjectNameMatchesSubject(excludedSubjectName, subject)) {
              isExcluded = true;
              break;
            }
          }
          if (isExcluded) continue;
        }
        return date;
      }

      if (checkSubjectNameMatchesSubject(date.subjectName, subject)) {
        return date;
      }
    }

    return null;
  }

}

@JsonSerializable()
class AbiDates {
  @JsonKey(name: "written")
  List<WrittenAbiExamDate> writtenExamDates;

  @JsonKey(name: "oral")
  List<OralAbiExamWeek> oralExamWeeks;

  @JsonKey(name: "practical")
  List<PracticalAbiExamDate> practicalExamDates;

  @JsonKey(name: "graduation")
  AbiGraduationDate graduationDate;

  AbiDates({
    required this.writtenExamDates,
    required this.oralExamWeeks,
    required this.practicalExamDates,
    required this.graduationDate
  });

  factory AbiDates.fromJson(Map<String, dynamic> json) => _$AbiDatesFromJson(json);
}

@JsonSerializable()
class WrittenAbiExamDate {

  @JsonKey(name: "subject")
  String subjectName;

  @JsonKey(name: "date") @DateOnlyConverter()
  DateTime date;

  @JsonKey(name: "date_formatted")
  String formattedDate;

  bool ea;

  bool ga;

  @JsonKey(name: "is_remaining", defaultValue: false)
  bool isRemaining;

  @JsonKey(name: "excluded_subjects", defaultValue: [])
  List<String> excludedSubjectNames;

  WrittenAbiExamDate({
    required this.subjectName,
    required this.date,
    required this.formattedDate,
    required this.ea,
    required this.ga,
    required this.isRemaining,
    required this.excludedSubjectNames
  });

  factory WrittenAbiExamDate.fromJson(Map<String, dynamic> json) => _$WrittenAbiExamDateFromJson(json);
}

@JsonSerializable()
class OralAbiExamWeek {

  @JsonKey(name: "week_number")
  int weekNumber;

  @JsonKey(name: "start_date") @DateOnlyConverter()
  DateTime startDate;

  @JsonKey(name: "end_date") @DateOnlyConverter()
  DateTime endDate;

  @JsonKey(name: "date_formatted")
  String formattedDate;

  @JsonKey(name: "week_formatted")
  String formattedWeekName;

  OralAbiExamWeek({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.formattedDate,
    required this.formattedWeekName
  });

  factory OralAbiExamWeek.fromJson(Map<String, dynamic> json) => _$OralAbiExamWeekFromJson(json);
}

@JsonSerializable()
class PracticalAbiExamDate {

  @JsonKey(name: "subject")
  String subjectName;

  @JsonKey(name: "start_date") @DateOnlyConverter()
  DateTime startDate;

  @JsonKey(name: "date_formatted")
  String formattedDate;

  PracticalAbiExamDate({
    required this.subjectName,
    required this.startDate,
    required this.formattedDate,
  });

  factory PracticalAbiExamDate.fromJson(Map<String, dynamic> json) => _$PracticalAbiExamDateFromJson(json);
}

@JsonSerializable()
class AbiGraduationDate {

  @JsonKey(name: "date") @DateOnlyConverter()
  DateTime date;

  @JsonKey(name: "date_formatted")
  String formattedDate;

  AbiGraduationDate({
    required this.date,
    required this.formattedDate,
  });

  factory AbiGraduationDate.fromJson(Map<String, dynamic> json) => _$AbiGraduationDateFromJson(json);
}
