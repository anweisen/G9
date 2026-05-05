import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../pages/setup.dart' as setup; // BackButton: ambiguous import with material.dart
import '../provider/settings.dart';
import '../provider/grades.dart';
import '../widgets/skeleton.dart';
import '../logic/hurdles.dart';
import '../logic/results.dart';
import 'pdf_generator.dart';

class PdfPreviewPage extends StatelessWidget {
  const PdfPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final settingsProvider = Provider.of<SettingsDataProvider>(context);
    final gradesProvider = Provider.of<GradesDataProvider>(context);
    final choice = settingsProvider.choice!;

    final results = SemesterResult.calculateResultsWithPredictions(choice, gradesProvider);
    final flags = SemesterResult.applyUseFlags(choice, results);
    final statistics = SemesterResult.calculateStatistics(choice, results);
    final admissionHurdles = AdmissionHurdle.check(choice, results, flags, gradesProvider);
    final graduationHurdles = GraduationHurdle.check(choice, results, flags, gradesProvider);
    final complete = SemesterResult.isComplete(choice, results);

    return Scaffold(
      backgroundColor: theme.cardColor,
      body: Stack(
        children: [
          PdfPreview(
            scrollViewDecoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            pdfPreviewPageDecoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),

            pdfFileName: PdfGenerator.fileName,
            initialPageFormat: PdfPageFormat.a4,
            build: (format) => PdfGenerator.generatePdf(format, choice, results, flags, statistics, admissionHurdles, graduationHurdles, complete),
            useActions: false,
            canChangePageFormat: false,
            canDebug: false,
            padding: const EdgeInsets.symmetric(horizontal: PageSkeleton.leftOffset, vertical: 20),
            previewPageMargin: const EdgeInsets.only(bottom: 20),
            loadingWidget: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
          ),

          setup.BackButton(
            leftOffset: PageSkeleton.leftOffset + 2,
            animationProgress: 1,
            icon: Icons.print_rounded,
            callback: () async {
              final bytes = await PdfGenerator.generatePdf(PdfPageFormat.a4, choice, results, flags, statistics, admissionHurdles, graduationHurdles, complete);
              await Printing.sharePdf(bytes: bytes, filename: PdfGenerator.fileName);
            },
          ),
        ],
      ),
    );
  }
}
