
import 'dart:collection';

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
    } else if (subject == choice.profil12 || subject == choice.profil13) {
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
    } else if (subject.category == SubjectCategory.sg && choice.mintSg2.category != SubjectCategory.sg && choice.mintSg2.category != SubjectCategory.sbs) { // einzige Fremdsprache (spät beginnende zählt hier schon!)
      return 4;
    } else if (subject.category == SubjectCategory.ntg && choice.mintSg2.category != SubjectCategory.ntg) { // einzige Naturwissenschaft (Informatik zählt hier nicht!)
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
    } else if ((subject == choice.profil12 || subject == choice.profil13) && choice.profil12 == choice.profil13) { // Vom Profilfach dürfen nur 3 Semester eingebracht werden (wenn über 4 Semester belegt)
      return 3; // TODO: insgesamt von allen Profilfächern nur 3 Semester?
    } else if (!choice.pug13 && subject == Subject.pug) { // PuG nur in Q12
      return 2;
    } else if (choice.pug13 && subject == choice.geoWr) { // PuG in Q12+13, Geo/WR nur in Q12
      return 2;
    } else if (subject == choice.seminar || subject.category == SubjectCategory.seminar) { // Seminararbeit
      return 2; // 2 Semester in Q12 normal, Seminararbeit in Q13 als extra Sonderregel!
    }

    return choice.numberOfSemestersFor(subject);
  }

  static bool canUseJokerForSubject(Choice choice, Subject subject) {
    // Joker nicht möglich für:
    // - Abitur Prüfungsfächer
    // - Deutsch, Mathe auch wenn substituiert
    // - einzige Fremdsprache oder Naturwissenschaft
    // - nur über 2 Semester belegte Fächer (min 1 HJ)
    // - W-Seminar

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
    } else if (subject == choice.seminar || subject.category == SubjectCategory.seminar) { // Seminararbeit
      return false;
    } else if (subject == choice.vk) { // VK
      return false;
    } else if (subject == choice.mintSg2 && choice.vk != null) { // Durch VK ersetztes Fach
      return false;
    } else if (subject == Subject.pug && !choice.pug13) { // PuG nur 2 Semester belegt
      return false;
    } else if (subject == choice.geoWr && choice.pug13) { // Geo/WR nur 2 Semester belegt
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

      List<SemesterResult> sorted = result[subject]!.entries
          .where((entry) => Semester.qPhaseEquivalents(subject.category).contains(entry.key))
          .map((e) => e.value).toList()
        ..sort((a, b) => b.grade.compareTo(a.grade));

      int minSemesters = getMinSemestersForSubject(choice, subject);
      // Spezialfall: Seminararbeit in Q13 = x2 Semester-Einbringungen (aber nur 1 SemesterResult)
      if (subject == choice.seminar) {
        forcedSemesters += 1; // 1 SemesterResult, das als 2 (verpflichtende) Einbringungen zählt
        minSemesters -= 1; // nur 1 SemesterResult nicht 2
      }

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

    // TODO sort again,modified?

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
        bestFree.value.jokerResult = (entry.key, entry.value);
        entry.value.jokerResult = (bestFree.key, bestFree.value);
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
        pointsAbi += result[subject]![Semester.abi]!.grade; // Abi Prüfung entspricht 4 Einbringungen (ist bereits x4 in SemesterResult)
        result[subject]![Semester.abi]!.useForced = true; // Abi Prüfung immer verpflichtend
      }
    }

    return ResultsFlags(forcedSemesters, pointsQ, pointsAbi, (pointsQ + pointsAbi) == 0);
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
          results[subject]![semester] = SemesterResult(GradeHelper.result(grades), grades.length, semester);
        }
      });
    });

    int totalCount = 0;
    int totalSum = 0;
    // calculate subject based predictions
    for (var subject in choice.subjects) {

      int count = 0;
      int sum = 0;
      for (var semester in Semester.qPhase) {
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
      int prediction = (sum / count).floor();
      for (var semester in Semester.normal) {
        if (!choice.hasSubjectInSemester(subject, semester)) {
          continue; // subject not taken that semester
        }
        if (semester == Semester.abi && provider.getAbiPrediction(subject.id) != null) {
          continue; // apply abi prediction later
        }
        if (results[subject]![semester] == null) {
          results[subject]![semester] = SemesterResult(prediction * semester.semesterCountEquivalent, 0, semester);
        }
      }

    }

    // calculate total prediction
    int totalPrediction = totalCount == 0 ? 0 : (totalSum / totalCount).floor();
    for (var subject in choice.subjects) {
      for (var semester in Semester.normal) {
        if (!choice.hasSubjectInSemester(subject, semester)) {
          continue; // subject not taken that semester
        }

        if (semester == Semester.abi && provider.getAbiPrediction(subject.id) != null) {
          results[subject]![semester] = SemesterResult(provider.getAbiPrediction(subject.id)! * 4, 0, semester);
        } else if (results[subject]![semester] == null) {
          results[subject]![semester] = SemesterResult(totalPrediction * semester.semesterCountEquivalent, 0, semester);
        }
      }
    }

    int seminarPrediction = totalCount == 0 ? 0 : (2 * totalSum / totalCount).floor();
    if (results[choice.seminar]![Semester.seminar13]?.prediction ?? true) {
      results[choice.seminar]![Semester.seminar13] = SemesterResult(seminarPrediction, 0, Semester.seminar13);
    }

    return results;
  }

  static Statistics calculateStatistics(Choice choice, Map<Subject, Map<Semester, SemesterResult>> result) {
    List<(Subject, double)> bestSubjects = [];
    int numberGrades = 0;

    for (var subject in choice.subjects) {
      int points = 0;
      int semesters = 0;

      for (var semester in Semester.qPhase) {
        if (result[subject]![semester] == null) continue;
        if (result[subject]![semester]!.prediction) continue;

        numberGrades += result[subject]![semester]!.basedOnGradeCount;
        points += result[subject]![semester]!.grade;
        semesters++;
      }

      if (semesters == 0) continue;
      double avg = points.toDouble() / semesters.toDouble();
      bestSubjects.add((subject, avg));
    }

    bestSubjects.sort((a, b) => b.$2.compareTo(a.$2));

    return Statistics(bestSubjects, numberGrades);
  }

  static double convertAverage(double points) {
    if (points == 0) return 0;
    return 6 - (5 / 14) * points;
  }

  static double pointsAverage(int points) {
    return (points / 60.0);
  }

  // https://www.gesetze-bayern.de/Content/Document/BayGSO-ANL_23
  static Map<int, double> minPointsForAbiGradeMap = Map.unmodifiable(SplayTreeMap((a, b) => b.compareTo(a))..addAll({
    823: 1.0, 805: 1.1, 787: 1.2, 769: 1.3, 751: 1.4, 733: 1.5, 715: 1.6, 697: 1.7, 679: 1.8, 661: 1.9,
    643: 2.0, 625: 2.1, 607: 2.2, 589: 2.3, 571: 2.4, 553: 2.5, 535: 2.6, 517: 2.7, 499: 2.8, 481: 2.9,
    463: 3.0, 445: 3.1, 427: 3.2, 409: 3.3, 391: 3.4, 373: 3.5, 355: 3.6, 337: 3.7, 319: 3.8, 301: 3.9,
    300: 4.0,
  }));

  static String pointsToAbiGrade(int points) {
    if (points >= 300 && points <= 900) {
      for (var entry in minPointsForAbiGradeMap.entries) {
        if (points >= entry.key) {
          return GradeHelper.formatNumber(entry.value, decimals: 1);
        }
      }
    }
    return "ungültig";
  }

  static int getMinPointsForBetterAbiGrade(int points) {
    int lastGradePoints = 900;
    for (var entry in minPointsForAbiGradeMap.entries) {
      if (points >= entry.key) break;
      lastGradePoints = entry.key;
    }
    return lastGradePoints;
  }

  static int getMinPointsForThisAbiGrade(int points) {
    for (var entry in minPointsForAbiGradeMap.entries) {
      if (points >= entry.key) {
        return entry.key;
      }
    }
    return 0;
  }

  final int grade;
  final int basedOnGradeCount;

  final Semester semester;

  bool useForced = false;
  bool useExtra = false;
  bool useJoker = false; // used as joker

  bool get prediction => basedOnGradeCount == 0;

  bool get used => (useForced || useExtra || useJoker) && !replacedByJoker;

  bool replacedByJoker = false;

  int get effectiveGrade => (grade / semester.semesterCountEquivalent).round();

  SemesterResult(this.grade, this.basedOnGradeCount, this.semester);

  @override
  String toString() => "$grade[${semester.semesterCountEquivalent}x ${used ? "used" : "free"}${prediction ? ", predicted" : ""}]";

}

class ResultsFlags {
  final int forcedSemesters;
  final int pointsQ;
  final int pointsAbi;
  final bool isEmpty;

  get pointsTotal => pointsQ + pointsAbi;

  ResultsFlags(this.forcedSemesters, this.pointsQ, this.pointsAbi, this.isEmpty);
}

class Statistics {
  final List<(Subject, double)> bestSubjects; // double is average
  final int numberGrades;

  Statistics(this.bestSubjects, this.numberGrades);

  @override
  String toString() => "Statistics{bestSubjects: $bestSubjects, numberGrades: $numberGrades}";
}
