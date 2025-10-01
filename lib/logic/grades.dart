import 'dart:math';

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

  @override
  String toString() {
    return 'GradeEntry{$type =$grade}';
  }
}

// https://www.gesetze-bayern.de/Content/Document/BayGSO-29
// 2) 1. Die Leistungen in den Fächern werden am Ende eines jeden Ausbildungsabschnitts zu einer Halbjahresleistung zusammengefasst und in einer Endpunktzahl von höchstens 15 Punkten ausgedrückt.
//    2. Die Endpunktzahl ergibt sich als Durchschnittswert aus der Punktzahl der Schulaufgabe sowie aus dem Durchschnitt der Punktzahlen der kleinen Leistungsnachweise.
//    3. In den Fächern auf grundlegendem Anforderungsniveau ergibt sich die Halbjahresleistung im Ausbildungsabschnitt 13/2 aus dem Durchschnitt der kleinen Leistungsnachweise.
//    4. In den Ausbildungsabschnitten 12/1 und 12/2 des Wissenschaftspropädeutischen Seminars ergibt sich die Halbjahresleistung jeweils aus dem Durchschnittswert der kleinen Leistungsnachweise.
//    5. Das Ergebnis wird gerundet; eine Aufrundung zur Endpunktzahl 1 ist nicht zulässig.
//    6. § 28 Abs. 1 Satz 2 und Abs. 4 gilt entsprechend.
// 3) 1. Im Leistungsfach Kunst ergibt sich die Halbjahresleistung aus dem Durchschnitt aus der Punktzahl der Schulaufgabe, der Punktzahl des künstlerischen Projekts sowie dem Durchschnitt der Punktzahlen der kleinen Leistungsnachweise.
//    2. Die Endpunktzahl wird nach Abs. 2 Satz 1 gebildet.
// 4) 1. Im Leistungsfach Musik ergibt sich die Halbjahresleistung aus dem Durchschnitt aus der Punktzahl der Schulaufgabe, der Punktzahl der praktischen Prüfung sowie dem Durchschnitt der Punktzahlen der kleinen Leistungsnachweise.
//    2. Die Endpunktzahl wird nach Abs. 2 Satz 1 gebildet.
// 5) 1. Im Fach Sport ergibt sich die Halbjahresleistung als Durchschnittswert aus dem doppelt gewichteten Durchschnitt der Punktzahlen der praktischen Leistungen im gewählten sportlichen Handlungsfeld sowie dem Durchschnitt der Punktzahlen der kleinen Leistungsnachweise.
//    2. Im Leistungsfach Sport ergibt sich die Endpunktzahl aus dem Durchschnitt der Punktzahl im Fach Sport gemäß Satz 1 und der Punktzahl in der Sporttheorie, die nach Abs. 2 Satz 2 gebildet wird.
// 6) 1. Zur Ermittlung der Gesamtleistung in der Seminararbeit wird zunächst die Punktzahl für die abgelieferte Arbeit verdreifacht und die Punktzahl für Präsentation mit Prüfungsgespräch addiert.
//    2. Die Summe wird durch 2 geteilt und das Ergebnis gerundet.
//
// https://www.gesetze-bayern.de/Content/Document/BayGSO-52
// 1) 1. Das Ergebnis der Prüfungsleistungen in den Abiturprüfungsfächern wird dadurch festgesetzt, dass die jeweils erzielten Punktzahlen vervierfacht werden.
//    2. Wird in einem schriftlichen Prüfungsfach hingegen auch eine Zusatzprüfung nach § 50 Abs. 1 und 3 durchgeführt, so werden die beiden Prüfungsteile im Verhältnis 2:1 gewertet.
//    3. Das Endergebnis wird nach der in Anlage 12 aufgeführten Formel berechnet.
// 2) Wurde Musik als schriftliches Abiturprüfungsfach mit besonderer Fachprüfung oder Sport als schriftliches oder mündliches Abiturprüfungsfach mit besonderer Fachprüfung gewählt, gilt Folgendes:
//    1. Wenn eine Zusatzprüfung nicht abgelegt wurde, werden die Ergebnisse des schriftlichen bzw. mündlichen und des praktischen Teils der besonderen Fachprüfung addiert; die sich ergebende Summe wird verdoppelt.
//    2. Wenn eine Zusatzprüfung abgelegt wurde, werden die Ergebnisse des schriftlichen und des praktischen Teils der besonderen Fachprüfung addiert und die sich ergebende Summe vervierfacht;
//       die Punktzahl für die Zusatzprüfung wird vervierfacht. Die zwei sich ergebenden Punktwerte werden addiert. Die Summe wird durch drei geteilt.
//
// https://www.gesetze-bayern.de/Content/Document/BayGSO-ANL_21
// Berechnung des Prüfungsergebnisses aus schriftlicher Prüfung und mündlicher Zusatzprüfung
// 1. Das Prüfungsergebnis ist mit folgender Formel zu berechnen:
//    P = (2s+m)/3 * 4.
//    (P = Prüfungsergebnis, s = Punktzahl der schriftlichen Prüfung, m = Punktzahl der mündlichen Prüfung).
// 2. Das Prüfungsergebnis wird gerundet. 3Bei einem Ergebnis (vierfache Wertung) von unter 4 Punkten ist die Abiturprüfung nicht bestanden.
class GradeHelper {
  static formatNumber(double avg, {int decimals = 1, bool allowZero = false}) {
    if (avg < 0 || (!allowZero && avg == 0)) {
      return "-";
    }

    num factor = pow(10, decimals);
    double trimmed = (avg * factor).truncate() / factor;
    return trimmed.toStringAsFixed(decimals).replaceFirst(".", ",");
  }

  static double averageOfSubjects(SubjectGradesMap grades, {Semester? semester}) {
    double sum = 0;
    int count = 0;

    final qSemesterCountEquivalent = semester != null ? SemesterResult.getQSemesterCountEquivalent(semester) : 1;
    grades.forEach((subjectId, grades) {
      if (grades.isNotEmpty) {
        sum += result(grades) / qSemesterCountEquivalent;
        count++;
      }
    });

    if (count == 0) {
      return 0;
    }

    return sum / count;
  }

  static double averageOfSemesterUsed(Map<Subject, Map<Semester, SemesterResult>> results, Semester semester) {
    double sum = 0;
    int count = 0;

    final qSemesterCountEquivalent = SemesterResult.getQSemesterCountEquivalent(semester);
    results.forEach((subject, semesters) {
      var result = semesters[semester];
      if (result == null || result.prediction) return; // only use real results
      if (!result.used) return; // only use used results
      sum += result.grade / qSemesterCountEquivalent;
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

  static String formatSemesterAverage(GradesList grades, {int decimals = 1, int qSemesterCountEquivalent = 1}) {
    if (grades.isEmpty) {
      return "-";
    }

    return formatNumber(average(grades) / qSemesterCountEquivalent, decimals: decimals, allowZero: true);
  }

  // Für Q-Semester: 0-15
  // Für Seminar13: 0-30
  // Für Abi-Semester: 0-60
  static double average(GradesList grades) {
    if (grades.isEmpty) {
      return 0;
    }

    Set<GradeTypeArea> areas = grades.map((e) => e.type.area).toSet();
    if (areas.contains(GradeTypeArea.seminar)) {
      return averageSeminar(grades);
    }
    if (areas.contains(GradeTypeArea.sport)) {
      return averageSportLk(grades);
    }
    if (areas.contains(GradeTypeArea.abi)) {
      return averageAbi(grades);
    }
    if (areas.contains(GradeTypeArea.kunstLk)) {
      return averageKunstLk(grades);
    }
    if (areas.contains(GradeTypeArea.musikLk)) {
      return averageMusikLk(grades);
    }

    return averageNormal(grades);
  }

  static double averageNormal(GradesList grades) {
    double klausuren = averageOf(grades.where((e) => e.type == GradeType.klausur).toList());
    double rest = averageOf(grades.where((e) => e.type != GradeType.klausur).toList());
    return averageWeighted(klausuren, rest, 1);
  }

  static double averageSportLk(GradesList grades) {
    // Die jeweiligen Leistungen werden zu einer Note (gerundet ?!?)
    double praxis = averageSportGk(grades.where((e) => e.type.area == GradeTypeArea.sport).toList());
    double theorie = averageNormal(grades.where((e) => e.type.area != GradeTypeArea.sport).toList());
    return averageWeighted(praxis, theorie, 1);
  }

  static double averageSportGk(GradesList grades) {
    double praktisch = averageOf(grades.where((e) => e.type != GradeType.theorie).toList());
    double test = averageOf(grades.where((e) => e.type == GradeType.theorie).toList());
    return averageWeighted(praktisch, test, 2);
  }

  static double averageKunstLk(GradesList grades) {
    double klausur = averageOf(grades.where((e) => e.type == GradeType.klausur).toList());
    double projekt = averageOf(grades.where((e) => e.type == GradeType.kunstprojekt).toList());
    double rest = averageOf(grades.where((e) => e.type != GradeType.klausur && e.type != GradeType.kunstprojekt).toList());
    return averageOfThree(klausur, projekt, rest);
  }

  static double averageMusikLk(GradesList grades) {
    double klausur = averageOf(grades.where((e) => e.type == GradeType.klausur).toList());
    double praxis = averageOf(grades.where((e) => e.type == GradeType.musikpruefung).toList());
    double rest = averageOf(grades.where((e) => e.type != GradeType.klausur && e.type != GradeType.musikpruefung).toList());
    return averageOfThree(klausur, praxis, rest);
  }

  // (!) 2x HJ => Bis zu 30 Punkte
  static double averageSeminar(GradesList grades) {
    // Seminararbeit wird 3x gewichtet
    double seminararbeit = averageOf(grades.where((e) => e.type == GradeType.seminar).toList());
    double seminarreferat = averageOf(grades.where((e) => e.type == GradeType.seminarreferat).toList());
    return averageWeighted(seminararbeit, seminarreferat, 3) * 2;
  }

  // https://www.gesetze-bayern.de/Content/Document/BayGSO-52
  // https://www.gesetze-bayern.de/Content/Document/BayGSO-ANL_21
  // (!) 4x HJ => Bis zu 60 Punkte
  static double averageAbi(GradesList grades) {
    // Normal mit Zusatzprüfung;        2:1 - schriftlich : zusatz
    // Fachprüfung ohne Zusatzprüfung;  1:1 - schriftlich/mündlich : fach
    // Fachprüfung mit Zusatzprüfung;   1:1:1 - schriftlich : fach : zusatz (kryptisch formuliert in BayGSO-52(2)2.)

    double normal = averageOf(grades.where((e) => e.type == GradeType.schriftlich || e.type == GradeType.muendlich).toList());
    double zusatz = averageOf(grades.where((e) => e.type == GradeType.zusatz).toList());

    final types = grades.map((e) => e.type).toSet();
    if (types.contains(GradeType.fach)) {
      double fach = averageOf(grades.where((e) => e.type == GradeType.fach).toList());

      if (types.contains(GradeType.zusatz)) {
        return ((normal + fach) * 4 + zusatz * 4) / 3; // 1:1:1
      } else {
        return (normal + fach) * 2; // 1:1
      }
    }

    return averageWeighted(normal, zusatz, 2) * 4;
  }

  // ! GradeType will be ignored !
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

  static double averageOfThree(double a, double b, double c) {
    int count = 0;
    double sum = 0;
    if (a != -1) {
      sum += a;
      count++;
    }
    if (b != -1) {
      sum += b;
      count++;
    }
    if (c != -1) {
      sum += c;
      count++;
    }
    if (count == 0) {
      return -1;
    }
    return sum / count;
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

  // TODO extract; not very elegant
  static String getWeightingExplanation(Subject subject, Semester semester, Choice choice) {
    if (semester == Semester.seminar13 && subject == choice.seminar) {
      return "Gewichtung 3:1 ≙ 3×(Seminararbeit) : 1×(Seminarpräsentation)\n"
          "max. 30 Punkte (x2 Halbjahresleistungen)";
    }
    if (semester == Semester.abi) {
      if (subject == choice.lk && (subject == Subject.sport || subject == Subject.musik)) {
        return "Gewichtung (ohne Nachprüfung) 1:1 ≙ 1×(schriftl. Prüfung) : 1×(bes. Fachprüfung)\n"
            "Gewichtung (mit Nachprüfung) 1:1:1 ≙ 1×(schriftl. Prüfung) : 1×(bes. Fachprüfung) : 1×(mündl. Zusatzprüfung)\n"
            "max. 60 Punkte (x4 Halbjahresleistungen)";
      }
      return "Ergebnis (ohne Nachprüfung) = (mündl./schrift. Prüfung)\n"
          "Gewichtung (mit Nachprüfung) 2:1 ≙ 2×(schriftl. Prüfung) : 1×(mündl. Zusatzprüfung)\n"
          "max. 60 Punkte (x4 Halbjahresleistungen)";
    }
    if (subject == Subject.sport) {
      if (choice.lk == Subject.sport) {
        return "Gewichtung 1:1 ≙ 1×(Sportpraxis 'gA') : 1×(Sporttheorie 'eA')\n"
            "Sportpraxis: Gewichtung 2:1 ≙ 2×(⌀ prakt. Leistungen) : 1×(⌀ kl. Leistungsnachweise gA/Praxis)\n"
            "Sporttheorie: Gewichtung 1:1 ≙ 1×(⌀ kl. Leistungsnachweise eA/Theorie) : 1×(Klausur)\n"
            "Das Ergebnis wird gerundet (auf 1 wird nicht aufgerundet)\n"
            "max. 15 Punkte (x1 Halbjahresleistung)";
      }
      return "Gewichtung 2:1 ≙ 2×(⌀ praktische Leistungen) : 1×(⌀ kl. Leistungsnachweise)\n"
          "Das Ergebnis wird gerundet (auf 1 wird nicht aufgerundet)\n"
          "max. 15 Punkte (x1 Halbjahresleistung)";
    }
    if (subject == Subject.kunst && choice.lk == subject) {
      return "Gewichtung 1:1:1 ≙ 1×(Klausur) : 1×(künstlerisches Projekt) : 1×(⌀ kl. Leistungsnachweise)\n"
          "Das Ergebnis wird gerundet (auf 1 wird nicht aufgerundet)\n"
          "max. 15 Punkte (x1 Halbjahresleistung)";
    }
    if (subject == Subject.musik && choice.lk == subject) {
      return "Gewichtung 1:1:1 ≙ 1×(Klausur) : 1×(praktische Prüfung) : 1×(⌀ kl. Leistungsnachweise)\n"
          "Das Ergebnis wird gerundet (auf 1 wird nicht aufgerundet)\n"
          "max. 15 Punkte (x1 Halbjahresleistung)";
    }

    if (semester == Semester.q13_2 && !choice.abiSubjects.contains(subject)
        || (semester == Semester.q12_1 || semester == Semester.q12_2) && subject == choice.seminar) {
      return "Ergebnis = ⌀ kl. Leistungsnachweise\n"
          "Das Ergebnis wird gerundet (auf 1 wird nicht aufgerundet)\n"
          "max. 15 Punkte (x1 Halbjahresleistung)";
    }
    return "Gewichtung 1:1 ≙ 1×(⌀ kl. Leistungsnachweise) : 1×(Klausur)\n"
        "Das Ergebnis wird gerundet (auf 1 wird nicht aufgerundet)\n"
        "max. 15 Punkte (x1 Halbjahresleistung)";
  }
}

@HiveType(typeId: 21)
enum GradeType {
  @HiveField(0)
  klausur("Klausur", GradeTypeArea.klausur),

  @HiveField(1)
  test("Stegreifaufgabe", GradeTypeArea.muendlich),

  @HiveField(2)
  ausfrage("Ausfrage", GradeTypeArea.muendlich),

  @HiveField(3)
  referat("Referat", GradeTypeArea.muendlich),

  @HiveField(4)
  mitarbeit("Unterrichtsbeitrag", GradeTypeArea.muendlich),

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

  @HiveField(33)
  fach("Besondere Fachprüfung (Praktisch)", GradeTypeArea.abi),

  @HiveField(40)
  kunstprojekt("Künstlerisches Projekt", GradeTypeArea.kunstLk),

  @HiveField(50)
  musikpruefung("Praktische Prüfung", GradeTypeArea.musikLk)

  ;

  const GradeType(this.name, this.area);

  final String name;
  final GradeTypeArea area;

  static List<GradeType> listNormalNoK = only(GradeTypeArea.muendlich);
  static List<GradeType> listNormal = [klausur, ...listNormalNoK];
  static List<GradeType> listAbiNormal = [schriftlich, muendlich, zusatz]; // keine besondere Fachprüfung
  static List<GradeType> listAbiBesFach = only(GradeTypeArea.abi);

  static List<GradeType> only(GradeTypeArea area) {
    return values.where((it) => it.area == area).toList();
  }

  static List<GradeType> types(Choice choice, Subject subject, Semester semester) {
    if (semester == Semester.abi) {
      if (subject == choice.lk && (subject == Subject.sport || subject == Subject.musik)) {
        // besondere Fachprüfung im LK: Sport, Musik
        return listAbiBesFach;
      }

      return listAbiNormal;
    }

    if (subject == Subject.seminar) {
      if (semester == Semester.q12_1 || semester == Semester.q12_2) {
        return listNormalNoK;
      }
      return only(GradeTypeArea.seminar);
    }
    if (subject == Subject.sport) {
      if (choice.lk == Subject.sport) {
        return [...listNormal, ...only(GradeTypeArea.sport)];
      }
      return only(GradeTypeArea.sport);
    }
    if (subject == Subject.kunst && choice.lk == Subject.kunst) {
      return [...listNormal, kunstprojekt];
    }
    if (subject == Subject.musik && choice.lk == Subject.musik) {
      return [...listNormal, musikpruefung];
    }

    if (semester == Semester.q13_2 && !choice.abiSubjects.contains(subject)) {
      return listNormalNoK;
    }

    return listNormal;
  }

  bool stillPossible(List<GradeType> existingTypes) {
    switch (this) {
      case GradeType.klausur: // max 1 Klausur
        return !existingTypes.contains(GradeType.klausur);
      case GradeType.seminar: // max 1 Seminararbeit
        return !existingTypes.contains(GradeType.seminar);
      case GradeType.seminarreferat: // max 1 Seminarreferat
        return !existingTypes.contains(GradeType.seminarreferat);
      case GradeType.schriftlich: // max 1 (schriftliche ODER mündliche) Abiturprüfung
      case GradeType.muendlich:
        return !existingTypes.contains(GradeType.schriftlich) && !existingTypes.contains(GradeType.muendlich);
      case GradeType.zusatz: // max 1 Zusatzprüfung, nur bei schriftlicher Prüfung
        return !existingTypes.contains(GradeType.zusatz) && existingTypes.contains(GradeType.schriftlich);
      case GradeType.fach: // max 1 Fachprüfung (bei mündlicher UND schriftlicher Prüfung möglich)
        return !existingTypes.contains(GradeType.fach);
      case GradeType.kunstprojekt: // max 1 Kunstprojekt
        return !existingTypes.contains(GradeType.kunstprojekt);
      case GradeType.musikpruefung: // max 1 Musikprüfung
        return !existingTypes.contains(GradeType.musikpruefung);
      default:
        return true;
    }
  }

}

enum GradeTypeArea {
  /// Klausur / Schulaufgabe
  klausur,
  /// Mündliche Noten in einem Fach
  muendlich,
  /// Die beiden letzten Halbjahreseinbringungen setzen sich aus der Seminararbeit und dem Referat dazu zusammen
  seminar,
  /// Das Fach Sport(GK) hat keine üblichen Noten(sondern Praxis & Theorie) (= Praxisteil im LK)
  sport,
  /// Im Kunst LK wird ein künstlerisches Projekt benotet
  kunstLk,
  /// Im Musik LK wird eine praktische Prüfung benotet
  musikLk,
  /// Abiturprüfungen: schriftliche / mündliche Prüfungen, Fachprüfungen, Zusatzprüfungen, etc.
  abi,
}
