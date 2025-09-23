import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../logic/choice.dart';
import '../logic/types.dart';
import '../logic/grades.dart';

part "grades.g.dart";

class GradesDataProvider extends ChangeNotifier {
  static const hiveBoxName = "grades";
  static const hiveSettingsBoxName = "grade_settings";

  GradesDataProvider() {
    load();
  }

  Semester _currentSemester = Semester.q12_1;

  Map<Semester, SubjectGradesMap>? _data;

  Semester get currentSemester => _currentSemester;
  set currentSemester(Semester value) {
    _currentSemester = value;
    notifyListeners();
    save();
  }

  // (!) READ-ONLY
  GradesList getGrades(SubjectId subjectId, {Semester? semester}) {
    semester ??= _currentSemester;
    var grades = _data?[semester]?[subjectId] ?? [];
    return grades..sort((a, b) {
      // Step 1: Prioritize 'klausur' types.
      if (a.type == GradeType.klausur && b.type != GradeType.klausur) {
        return -1; // a comes before b
      } else if (a.type != GradeType.klausur && b.type == GradeType.klausur) {
        return 1; // b comes before a
      }
      // Step 2: Prioritize 'seminar' types.
      if (a.type == GradeType.seminar && b.type != GradeType.seminar) {
        return -1; // a comes before b
      } else if (a.type != GradeType.seminar && b.type == GradeType.seminar) {
        return 1; // b comes before a
      }

      // Step 3: If the type is the same, sort by date.
      return a.date.compareTo(b.date);
    });
  }

  // (!) READ-ONLY
  Map<SubjectId, GradesList> getGradesForSemester(Choice choice, {Semester? semester}) {
    semester ??= _currentSemester;
    var currentMap = _data?[semester] ?? {};
    return choice.subjects
      .asMap().map((_, subject) => MapEntry(subject.id, currentMap[subject.id] ?? []));
  }

  Map<Semester, SubjectGradesMap> getRawGrades() {
    return _data ?? {};
  }

  void addGrade(SubjectId subjectId, GradeEntry grade, {Semester? semester}) {
    print("Adding grade $grade to $subjectId in $semester");
    assert (_data != null);
    semester ??= _currentSemester;

    var grades = _data![semester]![subjectId];
    grades ??= _data![semester]![subjectId] = [];

    grades.add(grade);

    notifyListeners();
    save();
  }

  void removeGrade(SubjectId subjectId, int index, {Semester? semester}) {
    print("Removing grade at $index from $subjectId in $semester");
    assert (_data != null);
    semester ??= _currentSemester;

    var grades = _data![semester]![subjectId];
    grades ??= _data![semester]![subjectId] = [];

    grades.removeAt(index);

    notifyListeners();
    save();
  }

  Future<void> load() async {
    var settingsBox = await Hive.openBox(hiveSettingsBoxName);
    _currentSemester = Semester.values[settingsBox.get("currentSemester", defaultValue: Semester.q12_1.index)];

    // for some reason we cannot use the generic type here directly as the casting fails
    // this then requires the mapping of the dynamic type
    var box = await Hive.openBox<Map>(hiveBoxName);

    _data = <Semester, SubjectGradesMap>{};
    for (var semester in Semester.values) {
      Map<dynamic, dynamic> dynamicMap = box.get(semester.index, defaultValue: <SubjectId, GradesList>{})!;
      _data![semester] = dynamicMap.map((key, value) => MapEntry(key as SubjectId, _mapHiveList<GradeEntry>(value)));
    }

    notifyListeners();
  }

  List<E> _mapHiveList<E>(List<dynamic> list) {
    return list.map((e) => e as E).toList();
  }

  Future<void> save() async {
    var settingsBox = await Hive.openBox(hiveSettingsBoxName);
    settingsBox.put("currentSemester", _currentSemester.index);

    // see load() for the reason of the dynamic type
    var box = await Hive.openBox<Map>(hiveBoxName);

    _data!.forEach((semester, subjectGradesMap) {
      print("Saving $semester with $subjectGradesMap");
      box.put(semester.index, subjectGradesMap);
    });
  }
}


// TODO move to logic package
@HiveType(typeId: 4)
enum Semester {
  @HiveField(0)
  q12_1(0, "12/1", "Q12/1"),

  @HiveField(1)
  q12_2(1, "12/2", "Q12/2"),

  @HiveField(2)
  q13_1(2, "13/1", "Q13/1"),

  @HiveField(3)
  q13_2(3, "13/2", "Q13/2"),

  @HiveField(5)
  seminar13(3, "Seminararbeit", "Seminararbeit Q13"),

  @HiveField(4)
  abi(4, "Abi", "Abi Prüfungen");

  static const qPhase = [q12_1, q12_2, q13_1, q13_2];
  static const normal = [...qPhase, abi];
  static const seminarPhase = [q12_1, q12_2, seminar13];

  final int order;
  final String display;
  final String detailedDisplay;

  const Semester(this.order, this.display, this.detailedDisplay);

  Semester nextSemester() {
    // error: for the last semester (abi) ! no next semester
    return Semester.normal[order + 1];
  }

  static List<Semester> qPhaseEquivalents(SubjectCategory subjectCategory) {
    if (subjectCategory == SubjectCategory.seminar) {
      return seminarPhase;
    }
    return qPhase;
  }

  static Semester mapSemesterToDisplaySemester(Semester currentSemester, SubjectCategory subjectCategory) {
    if (subjectCategory == SubjectCategory.seminar) {
      if (currentSemester == Semester.q13_1 || currentSemester == Semester.q13_2) {
        return Semester.seminar13;
      }
      return currentSemester;
    }
    // if (currentSemester == Semester.seminar13) {
    //   return Semester.q13_1; // map seminar phase to normal phase
    // }
    return currentSemester;
  }
}
