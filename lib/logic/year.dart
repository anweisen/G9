
import '../provider/grades.dart';
import 'grades.dart';
import 'types.dart';

class YearHelper {

  static int extractGraduationYear(GradesDataProvider dataProvider) {
    Map<Semester, Map<SubjectId, GradesList>>? grades = dataProvider.getRawGrades();

    Map<Semester, int> maxYearGradeEntries = {};
    Map<Semester, int> minYearGradeEntries = {};
    for (Semester semester in grades.keys) {
      int maxYear = -1;
      int minYear = -1;

      for (SubjectId subjectId in grades[semester]!.keys) {
        for (GradeEntry grade in grades[semester]![subjectId]!) {
          if (maxYear == -1 || grade.date.year > maxYear) {
            maxYear = grade.date.year;
          }
          if (minYear == -1 || grade.date.year < minYear) {
            minYear = grade.date.year;
          }
        }
      }
      maxYearGradeEntries[semester] = maxYear;
      minYearGradeEntries[semester] = minYear;
    }

    // Oft werden Noten erst im Nachhinein eingetragen, daher nehmen wir die spätesten Semester als Anhaltspunkt
    // da diese eher aktuell (z.B. kurz vor Abitur) eingetragen wurden

    if (maxYearGradeEntries[Semester.abi] != -1) {
      return maxYearGradeEntries[Semester.abi]!;
    }
    if (maxYearGradeEntries[Semester.q13_2] != -1) {
      // Q13/2 beginnt im Januar/Februar des gleichen Jahres
      return maxYearGradeEntries[Semester.q13_2]!;
    }
    if (maxYearGradeEntries[Semester.q13_1] != -1) {
      // Q13/1 beginnt im September des Vorjahres, aber geht ins neue Jahr rein (meistens werden jedoch alle Noten im alten Jahr gemacht)
      if (maxYearGradeEntries[Semester.q13_1] == minYearGradeEntries[Semester.q13_1]) {
        return minYearGradeEntries[Semester.q13_1]! + 1;
      }
      return maxYearGradeEntries[Semester.q13_1]!;
    }
    if (minYearGradeEntries[Semester.q12_2] != -1) {
      // Q12/2 beginnt im Vorjahr
      return minYearGradeEntries[Semester.q12_2]! + 1;
    }
    if (minYearGradeEntries[Semester.q12_1] != -1) {
      // Q12/1 beginnt im Januar des Vor-Vorjahres, aber geht ins neue Jahr rein, daher +2 vom Beginn
      return minYearGradeEntries[Semester.q12_1]! + 2;
    }

    // Noch keine Noten eingetragen: Vermutlich (Beginn) 12. Klasse
    final now = DateTime.now();
    int currentYear = now.year;

    // Nach Juli (-> August: Sommerferien) beginnt dann das neue Schuljahr
    if (now.month > 7) return currentYear + 2;
    return currentYear + 1; // Bereits im laufenden Schuljahr
  }

  static String formatClassOfYear(int year) {
    return "${year - 2}/${year.toString().substring(2)}";
  }

}
