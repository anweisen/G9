
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
    } else if (subject == Subject.seminar) { // Seminararbeit
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
        pointsAbi += result[subject]![Semester.abi]!.grade * 4; // Api Prüfung entspricht 4 Einbringungen
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
          results[subject]![semester] = SemesterResult(GradeHelper.result(grades), grades.length);
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
      int prediction = (sum / count).floor();
      for (var semester in Semester.values) {
        if (Semester.qPhase.contains(semester) && semester.index >= choice.numberOfSemestersFor(subject)) {
          continue; // subject not taken that semester
        }

        if (results[subject]![semester] == null) {
          results[subject]![semester] = SemesterResult(prediction, 0);
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
          results[subject]![semester] = SemesterResult(totalPrediction, 0);
        }
      }
    }

    return results;
  }

  static Statistics calculateStatistics(Choice choice, Map<Subject, Map<Semester, SemesterResult>> result) {
    Subject bestSubject = choice.subjects.first;
    double bestSubjectAvg = 0;
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

      if (avg > bestSubjectAvg) {
        bestSubject = subject;
        bestSubjectAvg = avg;
      }
    }

    return Statistics(bestSubject, bestSubjectAvg, numberGrades);
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

  bool useForced = false;
  bool useExtra = false;
  bool useJoker = false; // used as joker

  bool get prediction => basedOnGradeCount == 0;

  bool get used => (useForced || useExtra || useJoker) && !replacedByJoker;

  bool replacedByJoker = false;

  SemesterResult(this.grade, this.basedOnGradeCount);

  @override
  String toString() => "$grade[${used ? "used" : "free"}${prediction ? ", predicted" : ""}]";

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
  final Subject bestSubject;
  final double bestSubjectAvg;
  final int numberGrades;

  Statistics(this.bestSubject, this.bestSubjectAvg, this.numberGrades);

  @override
  String toString() => "Statistics{bestSubject: $bestSubject, bestSubjectAvg: $bestSubjectAvg, numberGrades: $numberGrades}";
}

enum AdmissionHurdle {
  // https://www.gesetze-bayern.de/Content/Document/BayGSO-44
  // Die Schülerin oder der Schüler des Ausbildungsabschnitts 13/2 ist zugelassen, wenn sie oder er folgende Voraussetzungen erfüllt:
  // (1.) Durch die gewählten Abiturprüfungsfächer sind die drei Aufgabenfelder nach Maßgabe des § 18 Abs. 1 abgedeckt.
  // 2. In Deutsch, Mathematik und im Leistungsfach sind während der Qualifikationsphase mindestens 48 Punkte und in den fünf Abiturprüfungsfächern insgesamt mindestens 100 Punkte erreicht worden.
  // 3. In der Punktsumme aus den 40 einzubringenden Halbjahresleistungen sind mindestens 200 Punkte erreicht worden, davon in 32 Halbjahresleistungen je mindestens 5 Punkte bzw. mindestens 9 Punkte (zwei Halbjahresleistungen) in der Seminararbeit.
  // 4. Jede einzubringende Halbjahresleistung wurde mit mindestens 1 Punkt bewertet.
  // 5. Es sind unter Berücksichtigung des Ausbildungsabschnitts 13/2 mindestens die gemäß Anlage 5 vorgeschriebenen 124 oder 126 Halbjahreswochenstunden sowie die vorgeschriebenen Fächer und das Wissenschaftspropädeutische Seminar als belegt nachgewiesen, für das Kolleg ist Anlage 6 Buchst. B maßgeblich.
  // 6. Die Seminararbeit ist abgeliefert und weder diese Arbeit noch die Präsentation nach § 24 Abs. 2 sind mit 0 Punkten bewertet.
  // (7.) Es ist der Nachweis erbracht, dass der Unterricht in einer zweiten Fremdsprache wenigstens im nach § 19 Abs. 4 geforderten Mindestumfang besucht wurde.

  // mind. 48 Punkte in Deutsch, Mathe und LK
  min48dml("In Deutsch, Mathe und dem Leistungsfach müssen mindestens 48 Punkte erreicht werden"),
  // mind. 100 Punkte in den 5 Abiturfächern
  min100abi5("In den 5 Abiturfächern müssen in Q12 bis Q13 mindestens 100 Punkte erreicht werden"),
  // mind. 200 Punkte in den 40 einzubringenden Halbjahresleistungen
  min200in40("In den 40 einzubringenden Halbjahresleistungen müssen mindestens 200 Punkte erreicht werden"),
  // 32 Halbjahresleistungen je min. 5 Punkte
  min5je32("Mindestens 32 von den 40 einzubringende Halbjahresleistungen müssen je mindestens 5 Punkte haben (max. 8 Unterpunktungen)"),
  // Seminararbeit (zwei Halbjahresleistungen) min. 9 Punkte
  min9sem(""),
  // jede einzubringende Halbjahresleistung mind. 1 Punkt (=no0)
  //min1je("Jede einzubringende Halbjahresleistung wurde mit mindestens 1 Punkt bewertet"),

  // Keine Halbjahresleistung darf mit 0 Punkten bewertet sein (=> nicht belegt, keine Zulassung), außer Profilfach
  no0("Keine verpflichtende Belegung darf mit 0 Punkten bewertet sein (nicht belegt)"),
  // Seminararbeit und deren Präsentation darf nicht mit 0 Punkten bewertet sein (nicht belegt!)
  no0sem(""),
  ;

  final String desc;

  const AdmissionHurdle(this.desc);

  static (AdmissionHurdle?, String?) check(Choice choice, Map<Subject, Map<Semester, SemesterResult>> result) {
    List<SemesterResult> sortedUsedResults = [];
    for (Subject subject in choice.subjects) {
      for (Semester semester in Semester.qPhase) {
        if (result[subject]?[semester] == null) {
          continue; // Fach in diesem Semester nicht gewählt
        }

        SemesterResult sr = result[subject]![semester]!;
        // no0: Alle Belegungen müssen mindestens 1 Punkt haben (sonst nicht belegt)
        if (sr.grade < 1 && subject != choice.profil) { // Belegung Profilfach nicht Pflicht
          return (AdmissionHurdle.no0, "${subject.name} in ${semester.display}");
        }
        if (sr.used) {
          sortedUsedResults.add(result[subject]![semester]!);
        }
      }
    }
    sortedUsedResults.sort((a, b) => b.grade.compareTo(a.grade)); // sort descending
    // min5je32: 32 Halbjahresleistungen je min. 5 Punkte
    for (int i = 0; i < 32; i++) {
      if (sortedUsedResults[i].grade < 5) {
        return (AdmissionHurdle.min5je32, "$i von 32");
      }
    }
    // min200in40: mindestens 200 Punkte in den 40 einzubringenden Halbjahresleistungen
    int pointsIn40 = sortedUsedResults.map((e) => e.grade).reduce((value, element) => value + element);
    if (pointsIn40 < 200) {
      return (AdmissionHurdle.min200in40, "$pointsIn40 von 200");
    }

    // min100abi5: mindestens 100 Punkte in den 5 Abiturfächern
    int pointsInAbi5 = 0;
    for (Subject subject in choice.abiSubjects) {
      for (Semester semester in Semester.qPhase) {
        pointsInAbi5 += result[subject]![semester]!.grade;
      }
    }
    if (pointsInAbi5 < 100) {
      return (AdmissionHurdle.min100abi5, "$pointsInAbi5 von 100");
    }

    // min48dml: mindestens 48 Punkte in Deutsch, Mathe und LK
    int pointsInDML = 0;
    for (Semester semester in Semester.qPhase) {
      pointsInDML += result[Subject.deutsch]![semester]!.grade; // Deutsch
      pointsInDML += result[Subject.mathe]![semester]!.grade; // Mathe
      pointsInDML += result[choice.lk]![semester]!.grade; // LK
    }
    if (pointsInDML < 48) {
      return (AdmissionHurdle.min48dml, "$pointsInDML von 48");
    }

    // TODO no0sem, min9sem W-SEMINAR >= 9; != 0

    return (null, null);
  }
}
enum GraduationHurdle {
  // https://www.gesetze-bayern.de/Content/Document/BayGSO-54
  // Die allgemeine Hochschulreife wird der Schülerin oder dem Schüler zuerkannt, wenn
  // (1.) die Zulassungsvoraussetzungen nach § 44 erfüllt sind,
  // (2.) alle verpflichtend vorgeschriebenen Prüfungen abgelegt wurden,
  // 3. keines der nach § 52 errechneten Prüfungsergebnisse weniger als 4 Punkte (vierfache Wertung) beträgt,
  // 4. die Punktsumme der Abiturprüfung (§ 52) mindestens 100 beträgt,
  // 5. in mindestens drei Fächern, darunter Deutsch, Mathematik oder das Leistungsfach, jeweils mindestens 20 Punkte erzielt wurden,
  // 6. entweder
  //  a)  in Deutsch und Mathematik sowie einer Fremdsprache oder einer Naturwissenschaft
  //      oder
  //  b)  bei Substitution von Deutsch, in Mathematik, im Leistungsfach sowie in einer Fremdsprache, die nicht Leistungsfach ist, oder einer Naturwissenschaft
  //      oder
  //  c) bei Substitution von Mathematik, in Deutsch, im Leistungsfach sowie in einer Fremdsprache oder einer Naturwissenschaft, die nicht Leistungsfach ist,
  //  in den nach § 52 ermittelten Prüfungsergebnissen in der Summe mindestens 40 Punkte, darunter aus diesen drei Fächern nur einmal weniger als 16 Punkte, erreicht wurden,
  // 7. pro Aufgabenfeld nur einmal weniger als 16 Punkte erzielt wurden und
  // 8. in der Gesamtqualifikation mindestens 300 Punkte erzielt wurden
  min1je, // (3) In jeder Prüfung mindestens 1 Punkt (4 Punkte in 4-facher Wertung)
  min100, // (4) In Summe mindestens 100 Punkte in der Abiturprüfung (4-fache Wertung)
  min5je3, // (5) In mindestens 3 Fächern, darunter Deutsch, Mathe oder LK, jeweils mindestens 5 Punkte (20 Punkte in 4-facher Wertung)
  min10dmnsg, // (6) In Deutsch, Mathe und einer Fremdsprache oder Naturwissenschaft mindestens 10 Punkte (40 Punkte in 4-facher Wertung),
  min4x2dmnsg, // (6) In Deutsch, Mathe und einer Fremdsprache oder Naturwissenschaft maximal 1x unter 4 Punkten (16 Punkte in 4-facher Wertung)
  max1u4fields, // (7) Pro Aufgabenfeld nur 1x unter 4 Punkten (16 Punkte in 4-facher Wertung)
  min300, // (8) In der Gesamtqualifikation mindestens 300 Punkte
  ;
}
