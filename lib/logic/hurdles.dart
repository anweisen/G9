
import '../provider/grades.dart';
import 'grades.dart';
import 'choice.dart';
import 'results.dart';
import 'types.dart';

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
  min48dml("Nr. 2", "In Deutsch, Mathe und dem Leistungsfach in Q12 bis Q13 mindestens 48 Punkte"),
  // mind. 100 Punkte in den 5 Abiturfächern
  min100abi5("Nr. 2", "In den 5 Abiturfächern in Q12 bis Q13 mindestens 100 Punkte"),
  // mind. 200 Punkte in den 40 einzubringenden Halbjahresleistungen
  min200in40("Nr. 3", "In den 40 einzubringenden Halbjahresleistungen mindestens 200 Punkte"),
  // 32 Halbjahresleistungen je min. 5 Punkte
  min5je32("Nr. 3", "Mindestens 32 von den 40 einzubringende Halbjahresleistungen mit je mindestens 5 Punkte (max. 8 Unterpunktungen)"),
  // jede einzubringende Halbjahresleistung mind. 1 Punkt (=no0)
  min1je("Nr. 4", "Jede einzubringende Halbjahresleistung mit mindestens 1 Punkt bewertet"),

  // Keine Halbjahresleistung darf mit 0 Punkten bewertet sein (=> nicht belegt, keine Zulassung), außer Profilfach
  no0("Nr. 5", "Keine verpflichtende Belegung darf mit 0 Punkten bewertet sein (nicht belegt)"),
  // Seminararbeit und deren Präsentation darf nicht mit 0 Punkten bewertet sein (nicht belegt!)
  no0sem("Nr. 6", "Weder die Seminararbeit noch die Präsentation dürfen mit 0 Punkten bewertet sein"),
  ;

  final String paragraph;
  final String desc;

  const AdmissionHurdle(String section, this.desc) : paragraph = "§ 44 Abs. 2 $section BayGSO";

  static (AdmissionHurdle?, String?) check(Choice choice, Map<Subject, Map<Semester, SemesterResult>> result, GradesDataProvider provider) {
    List<SemesterResult> sortedUsedResults = [];
    for (Subject subject in choice.subjects) {
      for (Semester semester in Semester.qPhaseSeminar) {
        if (result[subject]?[semester] == null) {
          continue; // Fach in diesem Semester nicht gewählt
        }

        SemesterResult sr = result[subject]![semester]!;
        // min1je: Alle verpflichtend einzubringenden Halbjahresleistungen müssen mindestens 1 Punkt haben
        if (sr.used && sr.grade < 1) {
          return (AdmissionHurdle.min1je, "${subject.name} in ${semester.display}");
        }

        // no0: Alle Pflichthalbjahre müssen mindestens 1 Punkt haben (sonst nicht belegt), Pflichtbelegung (Mindeststundenzahl) nicht erfüllt
        if (sr.grade < 1 && subject != choice.profil12 && subject != choice.profil13) { // Belegung Profilfach nicht Pflicht
          return (AdmissionHurdle.no0, "${subject.name} in ${semester.display}");
        }
        if (sr.used) {
          sortedUsedResults.add(result[subject]![semester]!);
        }
      }
    }
    sortedUsedResults.sort((a, b) => b.grade.compareTo(a.grade)); // sort descending
    // min5je32: 32 Halbjahresleistungen je min. 5 Punkte
    for (int i = 0, min5 = 0; min5 < 32; i++) {
      if (sortedUsedResults[i].effectiveGrade < 5) {
        return (AdmissionHurdle.min5je32, "$min5 von 32");
      }
      min5 += sortedUsedResults[i].qSemesterEquivalent;
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

    // no0sem: Seminararbeit und Präsentation dürfen nicht mit 0 Punkten bewertet sein
    final seminarGrades = provider.getGrades(choice.seminar.id, semester: Semester.seminar13);
    for (var entry in seminarGrades) {
      if (entry.grade == 0) {
        return (AdmissionHurdle.no0sem, entry.type.name);
      }
    }

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

  // Aufgabenfelder: https://www.gesetze-bayern.de/Content/Document/BayGSO-ANL_3
  // - SLK, GPR, MINT

  // (3) In jeder Prüfung mindestens 1 Punkt (4 Punkte in 4-facher Wertung)
  min1je("Nr. 3", "In jedem Prüfungsergebnis mind. 1 Punkt (4 Punkte in vierfacher Wertung)"),
  // (4) In Summe mindestens 100 Punkte in der Abiturprüfung (4-fache Wertung)
  min100("Nr. 4", "In Summe mind. 100 Punkte in den Abiturprüfungen (vierfache Wertung)"),
  // (5) In mindestens 3 Fächern, darunter Deutsch, Mathe oder LK, jeweils mindestens 5 Punkte (20 Punkte in 4-facher Wertung)
  min5je3("Nr. 5", "In mind. 3 Fächern (darunter Deutsch, Mathe oder LK) jeweils mind. 5 Punkte (20 Punkte in vierfacher Wertung)"),
  // (6) In Deutsch, Mathe und einer Fremdsprache oder Naturwissenschaft mindestens 10 Punkte (40 Punkte in 4-facher Wertung),
  // - Sonderregelung bei Substitution von Deutsch/Mathe: Deutsch/Mathe(was nicht substituiert wurde), LK, Fremdsprache/Naturwissenschaft(nicht LK)
  //    Substitution von Deutsch: Mathe, LK, Fremdsprache(nicht LK)/Naturwissenschaft
  //    Substitution von Mathe: Deutsch, LK, Naturwissenschaft(nicht LK)/Fremdsprache
  min10dmns("Nr. 6 Buchst. a", "In Summe mind. 10 Punkte (40 Punkte in vierfacher Wertung) in Deutsch, Mathe und einer Fremdsprache/Naturwissenschaft"),
  min10dmns_b("Nr. 6 Buchst. b", "In Summe mind. 10 Punkte (40 Punkte in vierfacher Wertung) in Mathe, Leistungsfach und einer weiteren Fremdsprache/Naturwissenschaft"),
  min10dmns_c("Nr. 6 Buchst. c", "In Summe mind. 10 Punkte (40 Punkte in vierfacher Wertung) in Deutsch, Leistungsfach und einer weiteren Naturwissenschaft/Fremdsprache"),
  // (6) In [Deutsch, Mathe und einer Fremdsprache oder Naturwissenschaft] maximal 1x unter 4 Punkten (16 Punkte in 4-facher Wertung)
  // - bezieht sich auf die 3 Fächer, die in (6) genannt sind
  max1u4dmns("Nr. 6 Buchst. a", "In Deutsch, Mathe und einer Fremdsprache/Naturwissenschaft nur 1x unter 4 Punkten (16 Punkte in vierfacher Wertung)"),
  max1u4dmns_b("Nr. 6 Buchst. b", "In Mathe, Leistungsfach und einer weiteren Fremdsprache/Naturwissenschaft nur 1x unter 4 Punkten (16 Punkte in vierfacher Wertung)"),
  max1u4dmns_c("Nr. 6 Buchst. c", "In Deutsch, Leistungsfach und einer weiteren Naturwissenschaft/Fremdsprache nur 1x unter 4 Punkten (16 Punkte in vierfacher Wertung)"),

  // (7) Pro Aufgabenfeld nur 1x unter 4 Punkten (16 Punkte in 4-facher Wertung)
  max1u4fields("Nr 7.", "Pro Aufgabenfeld nur 1x unter 4 Punkten (16 Punkte in vierfacher Wertung)"),
  // (8) In der Gesamtqualifikation mindestens 300 Punkte
  min300("Nr. 8", "In der Gesamtqualifikation (insgesamt) mind. 300 Punkte"),
  ;

  final String desc;
  final String paragraph;

  const GraduationHurdle(String section, this.desc) : paragraph = "§ 54 Abs. 1 $section BayGSO";

  static (GraduationHurdle?, String?) check(Choice choice, Map<Subject, Map<Semester, SemesterResult>> result, ResultsFlags flags, GradesDataProvider provider) {

    List<Subject> min5Subjects = [];
    Map<SubjectTaskField, List<(Subject, SemesterResult)>> taskFieldMap = {};
    // min1je: In jeder Prüfung mindestens 1 Punkt (4 Punkte in 4-facher Wertung)
    for (Subject subject in choice.abiSubjects) {
      SemesterResult? sr = result[subject]?[Semester.abi];
      if (sr == null) continue; // Noch kein Ergebnis (eigentlich gibt es immer eine Vorhersage)

      if (sr.grade < 4) {
        return (GraduationHurdle.min1je, "In ${subject.name}: ${sr.grade} von 4");
      }

      if (sr.grade >= 20) { // 20 Punkte in 4-facher Wertung
        min5Subjects.add(subject);
      }

      taskFieldMap[subject.field] ??= [];
      taskFieldMap[subject.field]!.add((subject, sr));
    }

    // min5je3: In 3 Fächern (darunter Deutsch, Mathe oder LK) jeweils mindestens 5 Punkte (20 Punkte in 4-facher Wertung)
    if (min5Subjects.length < 3) {
      return (GraduationHurdle.min5je3, "${min5Subjects.length} von 3");
    }
    if (!min5Subjects.contains(Subject.deutsch) && !min5Subjects.contains(Subject.mathe) && !min5Subjects.contains(choice.lk)) {
      return (GraduationHurdle.min5je3, "Weder Deutsch, Mathe oder ${choice.lk.name} darunter");
    }

    // max1u4fields: Pro Aufgabenfeld nur 1x unter 4 Punkten (16 Punkte in 4-facher Wertung)
    for (var entry in taskFieldMap.entries) {
      List<(Subject, SemesterResult)> under4 = entry.value.where((element) => element.$2.grade < 16).toList();
      if (under4.length > 1) {
        return (GraduationHurdle.max1u4fields, "${under4.length}x ${entry.key.display}: ${under4.map((e) => e.$1.name).join(", ")}");
      }
    }

    // min10dmns: Deutsch, Mathe (bei Substitution LK) und eine Fremdsprache/Naturwissenschaft (bei Substitution nicht LK)
    // mindestens 10 Punkte (40 Punkte in 4-facher Wertung)
    List<Subject> dmnsSubjects = [
      choice.substituteDeutsch ? choice.lk : Subject.deutsch,
      choice.substituteMathe ? choice.lk : Subject.mathe,
    ];
    // beste Fremdsprache oder Naturwissenschaft (bei Substitution nicht LK!)
    List<Subject> validSgNtg = choice.abiSubjects
        .where((element) => element.category == SubjectCategory.sg || element.category == SubjectCategory.ntg)
        .where((element) => !((choice.substituteDeutsch || choice.substituteMathe) && element == choice.lk))
        .toList();
    validSgNtg.sort((a, b) => result[b]![Semester.abi]!.grade.compareTo(result[a]![Semester.abi]!.grade));
    dmnsSubjects.add(validSgNtg.first);

    int dmnsPoints = 0;
    List<Subject> dmnsUnder16 = [];
    for (Subject subject in dmnsSubjects) {
      SemesterResult? sr = result[subject]?[Semester.abi];
      if (sr == null) continue; // Noch kein Ergebnis (eigentlich gibt es immer eine Vorhersage)

      dmnsPoints += sr.grade;
      if (sr.grade < 16) {
        dmnsUnder16.add(subject);
      }
    }

    if (dmnsPoints < 40) {
      // a: keine Substitution, b: Substitution Deutsch, c: Substitution Mathe
      return (
        choice.substituteDeutsch ? GraduationHurdle.min10dmns_b : choice.substituteMathe ? GraduationHurdle.min10dmns_c : GraduationHurdle.min10dmns,
        "$dmnsPoints von 40"
      );
    }
    if (dmnsUnder16.length > 1) {
      return (
        choice.substituteDeutsch ? GraduationHurdle.max1u4dmns_b : choice.substituteMathe ? GraduationHurdle.max1u4dmns_c : GraduationHurdle.max1u4dmns,
        "${dmnsUnder16.length}x: ${dmnsUnder16.map((e) => e.name).join(", ")}"
      );
    }

    // min100: In Summe min. 100 Punkte in den Abiturprüfungen (4-fache Wertung)
    if (flags.pointsAbi < 100) {
      return (GraduationHurdle.min100, "${flags.pointsAbi} von 100");
    }

    // min300: Insgesamt min. 300 Punkte
    if (flags.pointsTotal < 300) {
      return (GraduationHurdle.min300, "${flags.pointsTotal} von 300");
    }

    return (null, null);
  }
}
