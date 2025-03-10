
import 'choice.dart';
import 'grades.dart';
import 'types.dart';
import '../provider/grades.dart';

class SemesterResult {

  static int getMinSemestersForSubject(Choice choice, Subject subject) {
    // Sport im GK 0 - 3 Einbringungen
    // Profilfach nicht Pflicht
    if (subject == Subject.sport && choice.lk != Subject.sport) {
      return 0;
    } else if (subject == choice.profil) {
      return 0;
    }

    // Verpflichtend alle 4 Semester:
    // - Abitur Prüfungsfächer, somit auch LK / Substitut
    // - Deutsch, Mathe auch wenn substituiert
    // - einzige Fremdsprache oder Naturwissenschaft
    if (subject.category == SubjectCategory.abi) { // Deutsch, Mathe
      return 4;
    } else if (subject == choice.lk) { // LK
      return 4;
    } else if (subject == choice.abi4 || subject == choice.abi5) { // Abitur Prüfungsfächer
      return 4;
    } else if (subject == choice.mintSg2 && (choice.substituteDeutsch || choice.substituteMathe)) { // Deutsch/Mathe Substitut wird Abifach
      return 4;
    } else if (subject.category == SubjectCategory.sg && choice.mintSg2.category != SubjectCategory.sg && choice.mintSg2.category != SubjectCategory.sbs) { // einzige Fremdsprache
      return 4;
    } else if (subject.category == SubjectCategory.ntg && choice.mintSg2.category != SubjectCategory.ntg && choice.mintSg2.category != SubjectCategory.info) { // einzige Naturwissenschaft
      return 4;
    }

    // Spezialfall: Seminararbeit
    if (subject == Subject.seminar) {
      return 4;
    }

    // Nur 2 Semester belegt, Pflichteinbringung: Belegung - 1
    if (subject == Subject.pug && !choice.pug13) { // PuG nur 2 Semester belegt
      return 1;
    } else if (subject == choice.geoWr && choice.pug13) { // Geo/WR nur 2 Semester belegt
      return 1;
    } else if (subject == choice.vk) { // VK wird nur 2 Semester belegt
      return 1;
    } else if (subject == choice.mintSg2 && choice.vk != null) { // Fach ersetzt durch VK wird nur 2 Semester belegt
      return 1;
    }
    // ABER! insgesamt 3 Semester aus VK + mintSg2

    // Restlichen Fächer 4 Semester belegt: Pflichteinbringung: Belegung - 1
    return 3;
  }

  static int getMaxSemesterForSubject(Choice choice, Subject subject) {
    if (subject == Subject.sport && choice.lk != Subject.sport) { // Sport im GK 0 - 3 Einbringungen
      return 3;
    } else if (subject.category == SubjectCategory.vk) { // VKs immer nur max. 2 Semester
      return 2;
    } else if (subject == choice.profil) { // Vom Profilfach dürfen nur 3 Semester eingebracht werden
      return 3;
    } else if (!choice.pug13 && subject == Subject.pug) { // PuG nur in Q12
      return 2;
    } else if (choice.pug13 && subject == choice.geoWr) { // PuG in Q12+13, Geo/WR nur in Q12
      return 2;
    }

    return choice.numberOfSemestersFor(subject);
  }

  static bool canUseJokerForSubject(Choice choice, Subject subject) {
    // Joker nicht möglich für:
    // - Abitur Prüfungsfächer
    // - Deutsch, Mathe auch wenn substituiert
    // - einzige Fremdsprache oder Naturwissenschaft
    // - nur über 2 Semester belegte Fächer (min 1 HJ)

    if (subject.category == SubjectCategory.abi) { // Deutsch, Mathe
      return false;
    } else if (subject == choice.lk) { // LK
      return false;
    } else if (subject == choice.abi4 || subject == choice.abi5) { // Abitur Prüfungsfächer
      return false;
    } else if (subject == choice.mintSg2 && (choice.substituteDeutsch || choice.substituteMathe)) { // Deutsch/Mathe Substitut wird Abifach
      return false;
    } else if (subject.category == SubjectCategory.sg && choice.mintSg2.category != SubjectCategory.sg && choice.mintSg2.category != SubjectCategory.sbs) { // einzige Fremdsprache
      return false;
    } else if (subject.category == SubjectCategory.ntg && choice.mintSg2.category != SubjectCategory.ntg && choice.mintSg2.category != SubjectCategory.info) { // einzige Naturwissenschaft
      return false;
    } else if (subject == Subject.seminar) { // Seminararbeit
      return false;
    } else if (subject == choice.vk) { // VK
      return false;
    } else if (subject == choice.mintSg2 && choice.vk != null) { // Durch VK ersetztes Fach
      return false;
    }

    return true;
  }

  static ResultsFlags applyUseFlags(Choice choice, Map<Subject, Map<Semester, SemesterResult>> result) {

    List<MapEntry<Subject, SemesterResult>> freeSemesterGrades = [];
    List<MapEntry<Subject, SemesterResult>> usedSemesterGrades = [];

    int forcedSemesters = 0;
    for (var subject in choice.subjects) {

      // ???????
      if (result[subject]?.isEmpty ?? true) {
        return ResultsFlags(forcedSemesters, 0, 0, true);
      }

      print("Subject: ${subject.name} - ${result[subject]}");

      int minSemesters = getMinSemestersForSubject(choice, subject);

      List<SemesterResult> sorted = result[subject]!.entries
          .where((entry) => Semester.qPhase.contains(entry.key))
          .map((e) => e.value).toList()
        ..sort((a, b) => b.grade.compareTo(a.grade));

      for (int i = 0; i < minSemesters; i++) {
        sorted[i].useForced = true;
        forcedSemesters++;
        usedSemesterGrades.add(MapEntry(subject, sorted[i]));
      }

      int maxSemesters = getMaxSemesterForSubject(choice, subject);
      for (int i = minSemesters; i < maxSemesters; i++) {
        freeSemesterGrades.add(MapEntry(subject, sorted[i]));
      }
    }


    // Noch keine Noten eingetragen
    if (usedSemesterGrades.isEmpty) {
      return ResultsFlags(forcedSemesters, 0, 0, true);
    }

    freeSemesterGrades.sort((a, b) => b.value.grade.compareTo(a.value.grade));
    usedSemesterGrades.sort((a, b) => b.value.grade.compareTo(a.value.grade));

    // Verpflichtend: 1 weiteres Semester aus dem VK oder dem Fach, das durch den VK ersetzt wird
    if (choice.vk != null) {
      forcedSemesters++;

      for (var entry in freeSemesterGrades) {
        if (entry.key == choice.vk || entry.key == choice.mintSg2) {
          entry.value.useForced = true;
          freeSemesterGrades.remove(entry);
          usedSemesterGrades.add(entry);
          break;
        }
      }
    }

    // Optionsregel ("Joker")
    for (var entry in usedSemesterGrades.reversed) {
      if (!canUseJokerForSubject(choice, entry.key)) {
        continue;
      }

      // usedSemesterGrades.remove(entry);
      entry.value.replacedByJoker = true;
      // Bei mehr als 40 Einbringungen wird nur die schlechteste Note gestrichen
      // Ist das nicht der Fall, kann diese durch eine noch nicht eingebrachte Note ersetzt werden
      if (forcedSemesters <= 40) {
        var bestFree = freeSemesterGrades.removeAt(0);
        bestFree.value.useJoker = true;
        // usedSemesterGrades.add(bestFree);
      }

      break;
    }

    for (int i = 0; i < 40 - forcedSemesters; i++) {
      freeSemesterGrades[i].value.useExtra = true;
    }

    int pointsQ = 0;
    result.forEach((subject, semesterResultMap) {
      semesterResultMap.forEach((semester, result) {
        if (result.used) {
          pointsQ += result.grade;
        }
      });
    });

    int pointsAbi = 0;
    for (var subject in choice.abiSubjects) {
      if (result[subject]?[Semester.abi] != null) {
        pointsAbi += result[subject]![Semester.abi]!.grade * 4;
      }
    }

    return ResultsFlags(forcedSemesters, pointsQ, pointsAbi, false);
  }

  static Map<Subject, Map<Semester, SemesterResult>> calculateResultsWithPredictions(Choice choice, GradesDataProvider provider) {
    Map<Semester, Map<SubjectId, List<GradeEntry>>> map = {};
    for (var semester in Semester.values) {
      map[semester] = provider.getGradesForSemester(choice, semester: semester);
    }

    // map existing semester grades
    Map<Subject, Map<Semester, SemesterResult>> results = {};
    map.forEach((semester, value) {
      value.forEach((subjectId, grades) {
        var subject = Subject.byId[subjectId]!;
        results.putIfAbsent(subject, () => {});

        if (grades.isNotEmpty) {
          results[subject]![semester] = SemesterResult(GradeHelper.result(grades), false);
        }
      });
    });

    int totalCount = 0;
    int totalSum = 0;
    // calculate subject based predictions
    for (var subject in choice.subjects) {

      int count = 0;
      int sum = 0;
      for (var semester in Semester.values) {
        if (results[subject]![semester] != null) {
          sum += results[subject]![semester]!.grade;
          count++;
        }
      }
      totalSum += sum;
      totalCount += count;

      // use total average/predication later
      if (sum == 0) {
        continue;
      }

      // apply prediction
      int prediction = (sum / count).round();
      for (var semester in Semester.values) {
        if (Semester.qPhase.contains(semester) && semester.index >= choice.numberOfSemestersFor(subject)) {
          continue; // subject not taken that semester
        }

        if (results[subject]![semester] == null) {
          results[subject]![semester] = SemesterResult(prediction, true);
        }
      }

    }

    // calculate total prediction
    int totalPrediction = totalCount == 0 ? 0 : (totalSum / totalCount).floor();
    for (var subject in choice.subjects) {
      for (var semester in Semester.values) {
        if (Semester.qPhase.contains(semester) && semester.index >= choice.numberOfSemestersFor(subject)) {
          continue; // subject not taken that semester
        }

        if (results[subject]![semester] == null) {
          results[subject]![semester] = SemesterResult(totalPrediction, true);
        }
      }
    }

    return results;
  }

  static double convertAverage(double points) {
    if (points == 0) return 0;
    return 6 - (5 / 14) * points;
  }

  static String pointsToAbiGrade(int points) {
    if (points >= 823 && points <= 900) return "1,0";
    if (points >= 805 && points <= 822) return "1,1";
    if (points >= 787 && points <= 804) return "1,2";
    if (points >= 769 && points <= 786) return "1,3";
    if (points >= 751 && points <= 768) return "1,4";
    if (points >= 733 && points <= 750) return "1,5";
    if (points >= 715 && points <= 732) return "1,6";
    if (points >= 697 && points <= 714) return "1,7";
    if (points >= 679 && points <= 696) return "1,8";
    if (points >= 661 && points <= 678) return "1,9";

    if (points >= 643 && points <= 660) return "2,0";
    if (points >= 625 && points <= 642) return "2,1";
    if (points >= 607 && points <= 624) return "2,2";
    if (points >= 589 && points <= 606) return "2,3";
    if (points >= 571 && points <= 588) return "2,4";
    if (points >= 553 && points <= 570) return "2,5";
    if (points >= 535 && points <= 552) return "2,6";
    if (points >= 517 && points <= 534) return "2,7";
    if (points >= 499 && points <= 516) return "2,8";
    if (points >= 481 && points <= 498) return "2,9";

    if (points >= 463 && points <= 480) return "3,0";
    if (points >= 445 && points <= 462) return "3,1";
    if (points >= 427 && points <= 444) return "3,2";
    if (points >= 409 && points <= 426) return "3,3";
    if (points >= 391 && points <= 408) return "3,4";
    if (points >= 373 && points <= 390) return "3,5";
    if (points >= 355 && points <= 372) return "3,6";
    if (points >= 337 && points <= 354) return "3,7";
    if (points >= 319 && points <= 336) return "3,8";
    if (points >= 301 && points <= 318) return "3,9";

    if (points == 300) return "4,0";

    return "ungültig";
  }

  final int grade;
  final bool prediction;

  bool useForced = false;
  bool useExtra = false;
  bool useJoker = false; // used as joker

  bool get used => (useForced || useExtra || useJoker) && !replacedByJoker;

  bool replacedByJoker = false;

  SemesterResult(this.grade, this.prediction);

  @override
  String toString() => "$grade[${used ? "used" : "free"}${prediction ? ", predicted" : ""}]";

}

class ResultsFlags {
  final int forcedSemesters;
  final int pointsQ;
  final int pointsAbi;
  final bool isEmpty;

  ResultsFlags(this.forcedSemesters, this.pointsQ, this.pointsAbi, this.isEmpty);
}
