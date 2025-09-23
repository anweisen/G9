import 'package:hive/hive.dart';

import '../provider/grades.dart';
import 'choice.dart';
import 'types.dart';
import 'results.dart';

part "grades.g.dart";

typedef SubjectGradesMap = Map<SubjectId, GradesList>;

typedef GradesList = List<GradeEntry>;

@HiveType(typeId: 20)
class GradeEntry {
  @HiveField(0)
  final int grade;

  @HiveField(1)
  final GradeType type;

  @HiveField(2)
  final DateTime date;

  GradeEntry(this.grade, this.type, this.date);
}

// https://www.gesetze-bayern.de/Content/Document/BayGSO-29
// 2) 1. Die Leistungen in den Fächern werden am Ende eines jeden Ausbildungsabschnitts zu einer Halbjahresleistung zusammengefasst und in einer Endpunktzahl von höchstens 15 Punkten ausgedrückt.
//    2. Die Endpunktzahl ergibt sich als Durchschnittswert aus der Punktzahl der Schulaufgabe sowie aus dem Durchschnitt der Punktzahlen der kleinen Leistungsnachweise.
//    3. In den Fächern auf grundlegendem Anforderungsniveau ergibt sich die Halbjahresleistung im Ausbildungsabschnitt 13/2 aus dem Durchschnitt der kleinen Leistungsnachweise.
//    4. In den Ausbildungsabschnitten 12/1 und 12/2 des Wissenschaftspropädeutischen Seminars ergibt sich die Halbjahresleistung jeweils aus dem Durchschnittswert der kleinen Leistungsnachweise.
//    5. Das Ergebnis wird gerundet; eine Aufrundung zur Endpunktzahl 1 ist nicht zulässig. 6§ 28 Abs. 1 Satz 2 und Abs. 4 gilt entsprechend.
// 3) 1. Im Leistungsfach Kunst ergibt sich die Halbjahresleistung aus dem Durchschnitt aus der Punktzahl der Schulaufgabe, der Punktzahl des künstlerischen Projekts sowie dem Durchschnitt der Punktzahlen der kleinen Leistungsnachweise.
//    2. Die Endpunktzahl wird nach Abs. 2 Satz 1 gebildet.
// 4) 1. Im Leistungsfach Musik ergibt sich die Halbjahresleistung aus dem Durchschnitt aus der Punktzahl der Schulaufgabe, der Punktzahl der praktischen Prüfung sowie dem Durchschnitt der Punktzahlen der kleinen Leistungsnachweise.
//    2. Die Endpunktzahl wird nach Abs. 2 Satz 1 gebildet.
// 5) 1. Im Fach Sport ergibt sich die Halbjahresleistung als Durchschnittswert aus dem doppelt gewichteten Durchschnitt der Punktzahlen der praktischen Leistungen im gewählten sportlichen Handlungsfeld sowie dem Durchschnitt der Punktzahlen der kleinen Leistungsnachweise.
//    2. Im Leistungsfach Sport ergibt sich die Endpunktzahl aus dem Durchschnitt der Punktzahl im Fach Sport gemäß Satz 1 und der Punktzahl in der Sporttheorie, die nach Abs. 2 Satz 2 gebildet wird.
// 6) 1. Zur Ermittlung der Gesamtleistung in der Seminararbeit wird zunächst die Punktzahl für die abgelieferte Arbeit verdreifacht und die Punktzahl für Präsentation mit Prüfungsgespräch addiert.
//    2. Die Summe wird durch 2 geteilt und das Ergebnis gerundet.
class GradeHelper {
  static formatNumber(double avg, {int decimals = 1}) {
    if (avg <= 0) {
      return "-";
    }

    return avg.toStringAsFixed(decimals).replaceFirst(".", ",");
  }

  static double averageOfSubjects(SubjectGradesMap grades) {
    double sum = 0;
    int count = 0;

    grades.forEach((subjectId, grades) {
      if (grades.isNotEmpty) {
        sum += result(grades);
        count++;
      }
    });

    if (count == 0) {
      return 0;
    }

    return sum / count;
  }

  static double averageOfSemester(Map<Subject, Map<Semester, SemesterResult>> results, Semester semester) {
    double sum = 0;
    int count = 0;

    results.forEach((subject, semesters) {
      var result = semesters[semester];
      if (result == null || result.prediction) return; // only use real results
      if (!result.used) return; // only use used results
      sum += result.grade;
      count++;
    });

    if (count == 0) {
      return 0;
    }

    return sum / count;
  }

  static int result(GradesList grades) {
    final avg = average(grades);
    return avg < 1 ? 0 : avg.round();
  }

  static String formatAverage(GradesList grades, {int decimals = 1}) {
    if (grades.isEmpty) {
      return "-";
    }

    return average(grades).toStringAsFixed(decimals).replaceFirst(".", ",");
  }

  static double average(GradesList grades) {
    if (grades.isEmpty) {
      return 0;
    }

    Set<GradeTypeArea> areas = grades.map((e) => e.type.area).toSet();
    if (areas.contains(GradeTypeArea.seminar)) {
      return averageSeminar(grades);
    }
    if (areas.contains(GradeTypeArea.sport) && grades.length > 1) {
      return averageSportLk(grades);
    }

    return averageNormal(grades);
  }

  static double averageNormal(GradesList grades) {
    double klausuren = averageOf(grades.where((e) => e.type == GradeType.klausur).toList());
    double rest = averageOf(grades.where((e) => e.type != GradeType.klausur).toList());
    return averageWeighted(klausuren, rest, 1);
  }

  static double averageSportLk(GradesList grades) {
    // Die jeweiligen Leistungen werden zu einer Note gerundet
    double praxis = averageOf(grades.where((e) => e.type.area == GradeTypeArea.sport).toList()).roundToDouble();
    double theorie = averageNormal(grades.where((e) => e.type.area != GradeTypeArea.sport).toList()).roundToDouble();
    return averageWeighted(praxis, theorie, 1);
  }

  // (!) 2x HJ => Bis zu 30 Punkte
  static double averageSeminar(GradesList grades) {
    // Seminararbeit wird 3x gewichtet
    double seminararbeit = averageOf(grades.where((e) => e.type == GradeType.seminar).toList());
    double seminarreferat = averageOf(grades.where((e) => e.type == GradeType.seminarreferat).toList());
    return averageWeighted(seminararbeit, seminarreferat, 3) * 2;
  }

  // https://www.gesetze-bayern.de/Content/Document/BayGSO-ANL_21
  // TODO fix this (rounding after *4 !)
  static double averageAbi(GradesList grades) {
    double normal = averageOf(grades.where((e) => e.type != GradeType.zusatz).toList());
    double zusatz = averageOf(grades.where((e) => e.type == GradeType.zusatz).toList());
    return averageWeighted(normal, zusatz, 2);
  }

  static double averageOf(List<GradeEntry> grades) {
    if (grades.isEmpty) {
      return -1;
    }

    double sum = 0;
    for (var value in grades) {
      sum += value.grade;
    }

    return sum / grades.length;
  }

  static double averageWeighted(double a, double b, double weightAtoB) {
    if (a == -1) {
      return b;
    }
    if (b == -1) {
      return a;
    }

    return (a * weightAtoB + b) / (weightAtoB + 1);
  }

  static String formatDate(DateTime date) {
    var now = DateTime.now();

    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return "Heute";
    }
    if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
      return "Gestern";
    }

    return "${date.day}. ${nameOfMonth(date.month)} ${date.year.toString().substring(2)}";
  }

  static String nameOfMonth(int month) {
    switch (month) {
      case 1:
        return "Januar";
      case 2:
        return "Februar";
      case 3:
        return "März";
      case 4:
        return "April";
      case 5:
        return "Mai";
      case 6:
        return "Juni";
      case 7:
        return "Juli";
      case 8:
        return "August";
      case 9:
        return "September";
      case 10:
        return "Oktober";
      case 11:
        return "November";
      case 12:
        return "Dezember";
      default:
        return "$month. ";
    }
  }
}

@HiveType(typeId: 21)
enum GradeType {
  @HiveField(0)
  klausur("Klausur", GradeTypeArea.normal),

  @HiveField(1)
  test("Stegreifaufgabe", GradeTypeArea.normal),

  @HiveField(2)
  ausfrage("Ausfrage", GradeTypeArea.normal),

  @HiveField(3)
  referat("Referat", GradeTypeArea.normal),

  @HiveField(4)
  mitarbeit("Unterrichtsbeitrag", GradeTypeArea.normal),

  @HiveField(10)
  praxis("Praxis", GradeTypeArea.sport),

  @HiveField(12)
  technik("Technik", GradeTypeArea.sport),

  @HiveField(11)
  theorie("Theorie", GradeTypeArea.sport),

  @HiveField(20)
  seminar("Seminar Arbeit", GradeTypeArea.seminar), // wird 3x gewichtet

  @HiveField(21)
  seminarreferat("Seminar Präsentation", GradeTypeArea.seminar),

  @HiveField(30)
  schriftlich("Schriftliche Prüfung", GradeTypeArea.abi),

  @HiveField(31)
  muendlich("Mündliche Prüfung (Kolloquium)", GradeTypeArea.abi),

  @HiveField(32)
  zusatz("Mündliche Zusatzprüfung (Nachprüfung)", GradeTypeArea.abi),

  // TODO: Fach-, Zusatzprüfungen, etc.

  ;

  const GradeType(this.name, this.area);

  final String name;
  final GradeTypeArea area;

  static List<GradeType> normal = only(GradeTypeArea.normal);
  static List<GradeType> normalNoK = GradeType.normal.where((element) => element != GradeType.klausur).toList();

  static List<GradeType> only(GradeTypeArea area) {
    return values.where((it) => it.area == area).toList();
  }

  static List<GradeType> types(Choice choice, Subject subject, Semester semester) {
    if (semester == Semester.abi) {
      return only(GradeTypeArea.abi);
    }

    if (subject == Subject.seminar) {
      if (semester == Semester.q12_1 || semester == Semester.q12_2) {
        return normal;
      }
      return only(GradeTypeArea.seminar);
    }
    if (subject == Subject.sport) {
      if (choice.lk == Subject.sport) {
        return [...normal, ...only(GradeTypeArea.sport)];
      }
      return only(GradeTypeArea.sport);
    }

    if (semester == Semester.q13_2 && !choice.abiSubjects.contains(subject)) {
      return normalNoK;
    }

    return normal;
  }

  bool stillPossible(List<GradeType> existingTypes) {
    switch (this) {
      case GradeType.klausur: // max 1 Klausur
        return !existingTypes.contains(GradeType.klausur);
      case GradeType.seminar: // max 1 Seminararbeit
        return !existingTypes.contains(GradeType.seminar);
      case GradeType.seminarreferat: // max 1 Seminarreferat
        return !existingTypes.contains(GradeType.seminarreferat);
      case GradeType.schriftlich: // max 1 (schriftliche, mündliche) Abiturprüfung
      case GradeType.muendlich:
        return !existingTypes.contains(GradeType.schriftlich) && !existingTypes.contains(GradeType.muendlich);
      case GradeType.zusatz: // max 1 Zusatzprüfung, nur bei schriftlicher Prüfung
        return !existingTypes.contains(GradeType.zusatz) && existingTypes.contains(GradeType.schriftlich);
      default:
        return true;
    }
  }

}

enum GradeTypeArea {
  /// Normale Noten in einem Fach
  normal,
  /// Die beiden letzten Halbjahreseinbringungen setzen sich aus der Seminararbeit und dem Referat dazu zusammen
  seminar,
  /// Das Fach Sport(GK) hat keine üblichen Noten(sondern Praxis & Theorie) (= Praxisteil im LK)
  sport,
  /// Abiturprüfungen: schriftliche / mündliche Prüfungen, Fachprüfungen, Zusatzprüfungen, etc.
  abi,
}
