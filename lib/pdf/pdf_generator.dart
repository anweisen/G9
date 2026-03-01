import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../logic/choice.dart';
import '../logic/grades.dart';
import '../logic/hurdles.dart';
import '../logic/types.dart';
import '../logic/results.dart';
import '../provider/grades.dart';

class PdfGenerator {

  static const String fileName = "Noten.pdf";
  static const PdfColor
      primaryColor = PdfColors.black,
      secondaryColor = PdfColors.grey600;
  static final TextStyle
      bodyTextStyle = TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.normal),
      headerTextStyle = TextStyle(fontSize: 9, color: primaryColor, fontWeight: FontWeight.bold);

  static Future<Uint8List> generatePdf(
      PdfPageFormat format,
      Choice choice, Map<Subject, Map<Semester, SemesterResult>> results, ResultsFlags flags, Statistics statistics,
      List<HurdleCheckResult> admissionHurdles, List<HurdleCheckResult> graduationHurdles
      ) async {

    final pdf = Document(title: fileName);

    final regulaFontData = await rootBundle.load("assets/fonts/Poppins-Regular.ttf");
    final regularFontTtf = Font.ttf(regulaFontData);
    final boldFontData = await rootBundle.load("assets/fonts/Poppins-SemiBold.ttf");
    final boldFontTtf = Font.ttf(boldFontData);

    final svgRaw = await rootBundle.loadString("assets/icons/logo.svg");

    final groupedSubjects = groupSubjectsByField(choice.subjects);

    pdf.addPage(
        MultiPage(
          pageFormat: format,
          theme: ThemeData.withFont(
            base: regularFontTtf,
            bold: boldFontTtf,
          ),
          build: (context) => [
            Text("Notenübersicht", style: TextStyle(fontSize: 14, height: 1, fontWeight: FontWeight.bold),),

            SizedBox(height: 2),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (Semester semester in Semester.qPhase)
                  SizedBox(child: Text(semester.detailedDisplay, style: TextStyle(fontSize: 8, color: primaryColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center), width: 40),
              ]
            ),

            for (MapEntry<SubjectTaskField, List<Subject>> entry in groupedSubjects.entries) ...[
              SizedBox(height: 4),
              Text(entry.key.fullName, style: headerTextStyle),
              for (Subject subject in entry.value)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(subject.name, style: bodyTextStyle),
                        if (subject == choice.lk) Text("  (LF)", style: TextStyle(fontSize: 8, color: primaryColor, fontWeight: FontWeight.bold),)
                      ]
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (Semester semester in Semester.qPhase)
                          SizedBox(child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: buildSemesterResultText(results[subject]?[semester])
                          ), width: 40),
                      ],
                    )
                  ]
                ),
            ],

            SizedBox(height: 16),

            Text("Wissenschaftspropädeutisches Seminar", style: headerTextStyle),
            for (Subject subject in [Subject.seminar])
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${subject.name}arbeit", style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.normal),),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 5),
                              Text("≈ ${(results[subject]![Semester.seminar13]?.effectiveGrade.toString() ?? "-")}",
                                  style: TextStyle(fontSize: 9, color: (results[subject]![Semester.seminar13]?.prediction ?? false) ? secondaryColor : primaryColor, fontWeight: FontWeight.normal), textAlign: TextAlign.center
                              ),
                              Text(" 3)", style: TextStyle(fontSize: 5, color: secondaryColor, fontWeight: FontWeight.bold),),
                            ]
                        ), width: 40),
                        SizedBox(child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: buildSemesterResultText(results[subject]![Semester.seminar13])
                        ), width: 40),
                      ],
                    )
                  ]
              ),

            SizedBox(height: 8),

            Text("Abiturprüfungen", style: headerTextStyle),
            for (Subject subject in choice.abiSubjects)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(subject.name, style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.normal),),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 5),
                          Text("≈ ${(results[subject]![Semester.abi]?.effectiveGrade.toString() ?? "-")}",
                              style: TextStyle(fontSize: 9, color: (results[subject]![Semester.abi]?.prediction ?? false) ? secondaryColor : primaryColor, fontWeight: FontWeight.normal), textAlign: TextAlign.center
                          ),
                          Text(" 3)", style: TextStyle(fontSize: 5, color: secondaryColor, fontWeight: FontWeight.bold),),
                        ]
                      ), width: 40),
                      SizedBox(child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: buildSemesterResultText(results[subject]![Semester.abi])
                      ), width: 40),
                    ],
                  )
                ]
              ),

            SizedBox(height: 16),

            Text("Abitur Vorhersage", style: headerTextStyle,),
            buildInfoTextLine("Note", "Ø ${SemesterResult.pointsToAbiGrade(flags.pointsTotal)}"),
            buildInfoTextLine("Punkte", "${flags.pointsTotal}"),
            SizedBox(height: 2),
            buildInfoTextLine("Punkte in Qualifikationsphase", "${flags.pointsQ} von 600"),
            buildInfoTextLine("Punkte in Prüfungsphase", "${flags.pointsAbi} von 300"),

            SizedBox(height: 8),

            Text("Zulassungs- und Anerkennungshürden", style: headerTextStyle),
            if (admissionHurdles.isEmpty && graduationHurdles.isEmpty)
              Text("Voraussichtlich werden alle nötigen Hürden erfüllt", style: bodyTextStyle,)
            else if (flags.isEmpty)
              Text("Es wurden bisher noch keine Noten eingetragen", style: bodyTextStyle,)
            else for (HurdleCheckResult check in [...admissionHurdles, ...graduationHurdles]) ...[
              buildHurdleCheckResultTextLine(check),
              SizedBox(height: 3),
            ],

            Spacer(),

            buildFootNoteText("1", "Diese Note ist eine Prognose, basierend auf bisherigen Leistungen, da noch keine Noten in diesem Semester eingetragen wurden. Sie kann von der tatsächlichen Note abweichen."),
            buildFootNoteText("2", "Diese Halbjahresleistung wird nicht in die Gesamtqualifikation einbezogen, da sie nicht zu den 40 eingebrachten Halbjahresleistungen zählt."),
            buildFootNoteText("3", "Note in einfacher Wertung (0 - 15 Punkte). Diese wird nicht zur Berechnung der Gesamtqualifikation herangezogen, sondern dient lediglich als Orientierungshilfe."),

            SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgImage(
                        width: 22,
                        height: 22,
                        svg: svgRaw,
                        colorFilter: secondaryColor
                    ),
                    SizedBox(width: 4),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              children: [
                                Text("Erstellt mit ", style: const TextStyle(fontSize: 7, color: secondaryColor),),
                                Text("G9 Notenapp", style: TextStyle(fontSize: 7, color: secondaryColor, fontWeight: FontWeight.bold),),
                              ]
                          ),
                          Row(
                            children: [
                              Text("https://g9.anweisen.net", style: const TextStyle(fontSize: 5, color: secondaryColor),),
                              SizedBox(width: 4),
                              Container(width: 1.5, height: 1.5, decoration: const BoxDecoration(color: secondaryColor, shape: BoxShape.circle),),
                              SizedBox(width: 4),
                              Text("© anweisen", style: const TextStyle(fontSize: 5, color: secondaryColor),),
                            ]
                          )
                        ]
                    )
                  ]
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Angaben ohne Gewähr", style: const TextStyle(fontSize: 7, color: secondaryColor),),
                    Text("Stand: ${GradeHelper.formatDate(DateTime.now(), useRelative: false)}", style: const TextStyle(fontSize: 7, color: secondaryColor),)
                  ]
                )
              ]
            )

          ],
        )
    );
    return pdf.save();
  }

  static List<Widget> buildSemesterResultText(SemesterResult? result) {
    final bool isPrediction = result?.prediction ?? false;
    final bool isUnused = !(result?.used ?? true);
    return [
      if (isPrediction) SizedBox(width: 5),
      if (isUnused) SizedBox(width: 5),
      Text("${isUnused ? "(" : ""}${result?.grade.toString() ?? "-"}${isUnused ? ")" : ""}", style: TextStyle(
          fontSize: 10,
          color: isPrediction ? secondaryColor : primaryColor,
          fontWeight: FontWeight.normal), textAlign: TextAlign.center),
      if (isPrediction) Text(" 1)", style: TextStyle(fontSize: 5, color: secondaryColor, fontWeight: FontWeight.bold),),
      if (isUnused) Text(" 2)", style: TextStyle(fontSize: 5, color: secondaryColor, fontWeight: FontWeight.bold),),
    ];
  }

  static Widget buildInfoTextLine(String name, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: bodyTextStyle,),
        Text(value, style: bodyTextStyle,)
      ],
    );
  }

  static Widget buildFootNoteText(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 6,
          child: Text("$number)", style: TextStyle(fontSize: 6, color: secondaryColor, fontWeight: FontWeight.normal),),
        ),
        SizedBox(width: 4),
        Expanded(child: Text(text, style: TextStyle(fontSize: 6, color: secondaryColor, fontWeight: FontWeight.normal),))
      ],
    );
  }

  static Widget buildHurdleCheckResultTextLine(HurdleCheckResult check) {
    final double relative = check.text.length.toDouble() / check.hurdle.desc.length.toDouble();
    final int flex = (relative * 100).clamp(15, 40).round(); // min 15%, max 40% for desc

    return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 100 - flex, child: Text(check.hurdle.desc, style: bodyTextStyle, softWrap: true, maxLines: 3,),),
          SizedBox(width: 8),
          Expanded(flex: flex, child: Text(check.text, style: TextStyle(fontSize: 8, color: secondaryColor, fontWeight: FontWeight.normal,), softWrap: true, maxLines: 5, textAlign: TextAlign.right)),
        ]
    );
  }

  static Map<SubjectTaskField, List<Subject>> groupSubjectsByField(List<Subject> subjects) {
    Map<SubjectTaskField, List<Subject>> grouped = {};
    for (var field in SubjectTaskField.values) { // init all for correct order
      grouped[field] = [];
    }
    for (Subject subject in subjects) {
      grouped[subject.field]!.add(subject);
    }
    return grouped;
  }

}
