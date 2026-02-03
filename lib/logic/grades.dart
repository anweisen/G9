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
// 2. Das Prüfungsergebnis wird gerundet.
// 3. Bei einem Ergebnis (vierfache Wertung) von unter 4 Punkten ist die Abiturprüfung nicht bestanden.
class GradeWeighting {
  final List<GradeWeightingComponent> components;
  final int semesterCountEquivalent;

  GradeWeighting(this.semesterCountEquivalent, this.components);

  double calculateAverage(GradesList grades) {
    return GradeWeightingComponent.calculateSubComponentsAverage(grades, components) * semesterCountEquivalent;
  }

  int _calculateDepth(List<GradeWeightingComponent>? components) {
    if (components != null && components.isNotEmpty) {
      int maxSubDepth = 0;
      for (var subcomponent in components) {
        int subDepth = 1 + _calculateDepth(subcomponent.subcomponents);
        if (subDepth > maxSubDepth) {
          maxSubDepth = subDepth;
        }
      }
      return maxSubDepth;
    }
    return 0;
  }

  int calculateComponentTreeDepth() {
    return _calculateDepth(components);
  }

  String generateInfoText() {
    String text = "";

    if (components.length > 1) {
      text += "Gewichtung ";
      text += generateInfoTextLineForComponents(components);

      for (GradeWeightingComponent component in components) {
        if (component.subcomponents != null && component.subcomponents!.length > 1) {
          text += "\n";
          text += "für ${component.title} ${generateInfoTextLineForComponents(component.subcomponents!)}";
        }
      }
    } else {
      text += "Ergebnis = ";
      text += "(${components[0].singleGrade ? "" : "⌀ "}${components[0].title})";
    }

    text += "\n";
    text += "Das Ergebnis wird gerundet (auf 1 wird nicht aufgerundet)\n";
    text += "max. ${semesterCountEquivalent * 15} Punkte (x$semesterCountEquivalent Halbjahresleistung)";
    return text;
  }

  static String generateInfoTextLineForComponents(List<GradeWeightingComponent> components) {
    String text = "";
    text += generateWeightingTextForComponents(components);
    text += " ≙ ";
    for (int i = 0; i < components.length; i++) {
      text += "${components[i].weight}×(${components[i].singleGrade ? "" : "⌀ "}${components[i].title})";
      if (i < components.length - 1) {
        text += " : ";
      }
    }
    return text;
  }

  static String generateWeightingTextForComponents(List<GradeWeightingComponent> components) {
    String text = "";
    for (int i = 0; i < components.length; i++) {
      text += "${components[i].weight}";
      if (i < components.length - 1) {
        text += ":";
      }
    }
    return text;
  }

  static GradeWeighting normal = GradeWeighting(1, [
    GradeWeightingComponent(title: "Klausur", weight: 1, singleGrade: true, filterTypes: {GradeType.klausur},),
    GradeWeightingComponent(title: "kl. Leistungsnachweise", weight: 1, filterAreas: {GradeTypeArea.muendlich},),
  ]);

  static GradeWeighting normalNoK = GradeWeighting(1, [
    GradeWeightingComponent(title: "kl. Leistungsnachweise", weight: 1, filterAreas: {GradeTypeArea.muendlich},),
  ]);

  static GradeWeighting sportGk = GradeWeighting(1, [
    GradeWeightingComponent(title: "praktische Leistungen", weight: 2, filterTypes: {GradeType.praxis, GradeType.technik},),
    GradeWeightingComponent(title: "schriftl. Leistungen", weight: 1, filterTypes: {GradeType.theorie},),
  ]);

  static GradeWeighting sportLk = GradeWeighting(1, [
    GradeWeightingComponent(title: "Sporttheorie", weight: 1, fromWeighting: normal,),
    GradeWeightingComponent(title: "Sportpraxis", weight: 1, fromWeighting: sportGk,),
  ]);

  static GradeWeighting kunstLk = GradeWeighting(1, [
    GradeWeightingComponent(title: "Klausur", weight: 1, singleGrade: true, filterTypes: {GradeType.klausur},),
    GradeWeightingComponent(title: "künstlerisches Projekt", weight: 1, singleGrade: true, filterTypes: {GradeType.kunstprojekt},),
    GradeWeightingComponent(title: "kl. Leistungsnachweise", weight: 1, filterAreas: {GradeTypeArea.muendlich},),
  ]);

  static GradeWeighting musikLk = GradeWeighting(1, [
    GradeWeightingComponent(title: "Klausur", weight: 1, singleGrade: true, filterTypes: {GradeType.klausur},),
    GradeWeightingComponent(title: "praktische Prüfung", weight: 1, singleGrade: true, filterTypes: {GradeType.musikpruefung},),
    GradeWeightingComponent(title: "kl. Leistungsnachweise", weight: 1, filterAreas: {GradeTypeArea.muendlich},),
  ]);

  static GradeWeighting seminar = GradeWeighting(2, [
    GradeWeightingComponent(title: "Seminararbeit", weight: 3, singleGrade: true, filterTypes: {GradeType.seminar},),
    GradeWeightingComponent(title: "Präsentation", weight: 1, singleGrade: true, filterTypes: {GradeType.seminarreferat},),
  ]);

  // https://www.gesetze-bayern.de/Content/Document/BayGSO-52
  // https://www.gesetze-bayern.de/Content/Document/BayGSO-ANL_21

  static GradeWeighting abi = GradeWeighting(4, [
    GradeWeightingComponent(title: "mündl./schriftl. Prüfung", weight: 1, singleGrade: true, filterTypes: {GradeType.schriftlich, GradeType.muendlich},),
  ]);

  // Normal mit Zusatzprüfung;        2:1 - schriftlich : zusatz
  static GradeWeighting abiZusatz = GradeWeighting(4, [
    GradeWeightingComponent(title: "schriftl. Prüfung", weight: 2, singleGrade: true, filterTypes: {GradeType.schriftlich, GradeType.muendlich},),
    GradeWeightingComponent(title: "mündl. Zusatzprüfung", weight: 1, singleGrade: true, filterTypes: {GradeType.zusatz},),
  ]);

  // Fachprüfung ohne Zusatzprüfung;  1:1 - schriftlich/mündlich : fach
  static GradeWeighting abiFach = GradeWeighting(4, [
    GradeWeightingComponent(title: "mündl./schriftl. Prüfung", weight: 1, singleGrade: true, filterTypes: {GradeType.schriftlich, GradeType.muendlich},),
    GradeWeightingComponent(title: "bes. Fachprüfung", weight: 1, singleGrade: true, filterTypes: {GradeType.fach},),
  ]);

  // Fachprüfung mit Zusatzprüfung;   1:1:1 - schriftlich : fach : zusatz (kryptisch formuliert in BayGSO-52(2)2.)
  static GradeWeighting abiFachZusatz = GradeWeighting(4, [
    GradeWeightingComponent(title: "schriftl. Prüfung", weight: 1, singleGrade: true, filterTypes: {GradeType.schriftlich, GradeType.muendlich},),
    GradeWeightingComponent(title: "bes. Fachprüfung", weight: 1, singleGrade: true, filterTypes: {GradeType.fach},),
    GradeWeightingComponent(title: "mündl. Zusatzprüfung", weight: 1, singleGrade: true, filterTypes: {GradeType.zusatz},),
  ]);

}

class GradeWeightingComponent {
  final String title;
  final int weight;
  final bool singleGrade;
  late List<GradeWeightingComponent>? subcomponents;
  final Set<GradeType>? filterTypes;
  final Set<GradeTypeArea>? filterAreas;

  bool get hasSubComponents => subcomponents != null && subcomponents!.isNotEmpty;

  GradeWeightingComponent({required this.title, required this.weight, this.singleGrade = false, this.subcomponents, this.filterTypes, this.filterAreas, GradeWeighting? fromWeighting}) {
    assert (subcomponents != null || filterTypes != null || filterAreas != null || fromWeighting != null);
    assert (subcomponents == null || (filterTypes == null && filterAreas == null) || fromWeighting == null);

    if (fromWeighting != null) subcomponents = fromWeighting.components;
  }

  GradesList filter(GradesList grades) {
    if (filterAreas != null) {
      grades = grades.where((e) => filterAreas!.contains(e.type.area)).toList();
    }
    if (filterTypes != null) {
      grades = grades.where((e) => filterTypes!.contains(e.type)).toList();
    }
    return grades;
  }

  double calculateAverage(GradesList grades) {
    final filteredGrades = filter(grades);
    if (subcomponents == null) return GradeHelper.unweightedAverageOf(filteredGrades);
    return calculateSubComponentsAverage(filteredGrades, subcomponents!);
  }

  static double calculateSubComponentsAverage(GradesList grades, List<GradeWeightingComponent> components) {
    double sum = 0;
    int totalWeight = 0;

    for (var component in components) {
      double componentAvg = component.calculateAverage(grades);
      if (componentAvg != -1) {
        sum += componentAvg * component.weight;
        totalWeight += component.weight;
      }
    }

    if (totalWeight == 0) return -1;
    return sum / totalWeight;
  }
}

class GradeHelper {
  static GradeWeighting getWeightingFor(Subject subject, Semester semester, Choice choice, GradesList grades) {
    if (semester == Semester.abi) {
      final types = grades.map((e) => e.type).toSet();
      if (subject == choice.lk && (subject == Subject.sport || subject == Subject.musik)) {
        if (types.contains(GradeType.muendlich)) return GradeWeighting.abiFach;
        return GradeWeighting.abiFachZusatz;
      }

      if (types.contains(GradeType.schriftlich)) return GradeWeighting.abiZusatz;
      return GradeWeighting.abi;
    }
    if (subject == choice.seminar && semester == Semester.seminar13) return GradeWeighting.seminar;
    if (subject == choice.seminar) return GradeWeighting.normalNoK;
    if (subject == Subject.sport && subject != choice.lk) return GradeWeighting.sportGk;
    if (subject == Subject.sport && subject == choice.lk) return GradeWeighting.sportLk;
    if (subject == Subject.kunst && subject == choice.lk) return GradeWeighting.kunstLk;
    if (subject == Subject.musik && subject == choice.lk) return GradeWeighting.musikLk;
    if (semester == Semester.q13_2 && !(subject == choice.lk || subject == Subject.mathe || subject == Subject.deutsch)) return GradeWeighting.normalNoK;
    return GradeWeighting.normal;
  }

  static formatNumber(double avg, {int decimals = 1, bool allowZero = false}) {
    if (avg < 0 || (!allowZero && avg == 0)) {
      return "-";
    }

    num factor = pow(10, decimals);
    double trimmed = (avg * factor).truncate() / factor;
    return trimmed.toStringAsFixed(decimals).replaceFirst(".", ",");
  }

  static formatResult(double avg, {bool allowZero = true}) {
    if (avg < 0 || (!allowZero && avg == 0)) {
      return "-";
    }

    return roundResult(avg).toString();
  }

  static double averageOfSubjects(SubjectGradesMap grades, {Semester? semester}) {
    double sum = 0;
    int count = 0;

    grades.forEach((subjectId, grades) {
      if (grades.isNotEmpty) {
        sum += result(grades) / (semester?.semesterCountEquivalent ?? 1);
        count++;
      }
    });

    if (count == 0) return 0;
    return sum / count;
  }

  static double averageOfSemesterUsed(Map<Subject, Map<Semester, SemesterResult>> results, Semester semester) {
    double sum = 0;
    int count = 0;

    results.forEach((subject, semesters) {
      var result = semesters[semester];
      if (result == null || result.prediction) return; // only use real results
      if (!result.used) return; // only use used results
      sum += result.grade / semester.semesterCountEquivalent;
      count++;
    });

    if (count == 0) return 0;
    return sum / count;
  }

  static int result(GradesList grades) {
    return roundResult(average(grades));
  }

  static int roundResult(double avg) {
    return avg < 1 ? 0 : avg.round();
  }

  static String formatSemesterAverage(GradesList grades, {int decimals = 1, int semesterCountEquivalent = 1}) {
    if (grades.isEmpty) {
      return "-";
    }

    return formatNumber(average(grades) / semesterCountEquivalent, decimals: decimals, allowZero: true);
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
    double klausuren = unweightedAverageOf(grades.where((e) => e.type == GradeType.klausur).toList());
    double rest = unweightedAverageOf(grades.where((e) => e.type != GradeType.klausur).toList());
    return averageWeighted(klausuren, rest, 1);
  }

  static double averageSportLk(GradesList grades) {
    // Die jeweiligen Leistungen werden zu einer Note (gerundet ?!?)
    double praxis = averageSportGk(grades.where((e) => e.type.area == GradeTypeArea.sport).toList());
    double theorie = averageNormal(grades.where((e) => e.type.area != GradeTypeArea.sport).toList());
    return averageWeighted(praxis, theorie, 1);
  }

  static double averageSportGk(GradesList grades) {
    double praktisch = unweightedAverageOf(grades.where((e) => e.type != GradeType.theorie).toList());
    double test = unweightedAverageOf(grades.where((e) => e.type == GradeType.theorie).toList());
    return averageWeighted(praktisch, test, 2);
  }

  static double averageKunstLk(GradesList grades) {
    double klausur = unweightedAverageOf(grades.where((e) => e.type == GradeType.klausur).toList());
    double projekt = unweightedAverageOf(grades.where((e) => e.type == GradeType.kunstprojekt).toList());
    double rest = unweightedAverageOf(grades.where((e) => e.type != GradeType.klausur && e.type != GradeType.kunstprojekt).toList());
    return averageOfThree(klausur, projekt, rest);
  }

  static double averageMusikLk(GradesList grades) {
    double klausur = unweightedAverageOf(grades.where((e) => e.type == GradeType.klausur).toList());
    double praxis = unweightedAverageOf(grades.where((e) => e.type == GradeType.musikpruefung).toList());
    double rest = unweightedAverageOf(grades.where((e) => e.type != GradeType.klausur && e.type != GradeType.musikpruefung).toList());
    return averageOfThree(klausur, praxis, rest);
  }

  // (!) 2x HJ => Bis zu 30 Punkte
  static double averageSeminar(GradesList grades) {
    // Seminararbeit wird 3x gewichtet
    double seminararbeit = unweightedAverageOf(grades.where((e) => e.type == GradeType.seminar).toList());
    double seminarreferat = unweightedAverageOf(grades.where((e) => e.type == GradeType.seminarreferat).toList());
    return averageWeighted(seminararbeit, seminarreferat, 3) * 2;
  }

  // https://www.gesetze-bayern.de/Content/Document/BayGSO-52
  // https://www.gesetze-bayern.de/Content/Document/BayGSO-ANL_21
  // (!) 4x HJ => Bis zu 60 Punkte
  static double averageAbi(GradesList grades) {
    // Normal mit Zusatzprüfung;        2:1 - schriftlich : zusatz
    // Fachprüfung ohne Zusatzprüfung;  1:1 - schriftlich/mündlich : fach
    // Fachprüfung mit Zusatzprüfung;   1:1:1 - schriftlich : fach : zusatz (kryptisch formuliert in BayGSO-52(2)2.)

    double normal = unweightedAverageOf(grades.where((e) => e.type == GradeType.schriftlich || e.type == GradeType.muendlich).toList());
    double zusatz = unweightedAverageOf(grades.where((e) => e.type == GradeType.zusatz).toList());

    final types = grades.map((e) => e.type).toSet();
    if (types.contains(GradeType.fach)) {
      double fach = unweightedAverageOf(grades.where((e) => e.type == GradeType.fach).toList());

      if (types.contains(GradeType.zusatz)) {
        return ((normal + fach) * 4 + zusatz * 4) / 3; // 1:1:1
      } else {
        return (normal + fach) * 2; // 1:1
      }
    }

    return averageWeighted(normal, zusatz, 2) * 4;
  }

  // ! GradeType will be ignored !
  static double unweightedAverageOf(List<GradeEntry> grades) {
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

  static String formatDate(DateTime date, {includeYear = true, shortMonth = false}) {
    var now = DateTime.now();

    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return "Heute";
    }
    if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
      return "Gestern";
    }

    return "${date.day}. ${shortMonth ? shortNameOfMonth(date.month) : nameOfMonth(date.month)} ${includeYear ? date.year.toString().substring(2) : ""}".trimRight();
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
      _ => "$month. ",
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
      _ => "$month. ",
    };
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

    if (semester == Semester.q13_2 && !(subject == choice.lk || subject == Subject.mathe || subject == Subject.deutsch)) {
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
  klausur("Klausur"),
  /// Mündliche Noten in einem Fach
  muendlich("kl. Leistungsnachweise"),
  /// Die beiden letzten Halbjahreseinbringungen setzen sich aus der Seminararbeit und dem Referat dazu zusammen
  seminar("W-Seminar"),
  /// Das Fach Sport(GK) hat keine üblichen Noten(sondern Praxis & Theorie) (= Praxisteil im LK)
  sport("Sportpraxis"),
  /// Im Kunst LK wird ein künstlerisches Projekt benotet
  kunstLk("Leistungsfach Kunst"),
  /// Im Musik LK wird eine praktische Prüfung benotet
  musikLk("Leistungsfach Musik"),
  /// Abiturprüfungen: schriftliche / mündliche Prüfungen, Fachprüfungen, Zusatzprüfungen, etc.
  abi("Abiturprüfungen");

  const GradeTypeArea(this.name);

  final String name;
}
