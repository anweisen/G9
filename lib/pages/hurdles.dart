import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/hurdles.dart';
import '../provider/settings.dart';
import '../widgets/skeleton.dart';

class HurdlesPage extends StatelessWidget {
  const HurdlesPage({super.key, required this.checkResults});

  final List<HurdleCheckResult> checkResults;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final choice = Provider.of<SettingsDataProvider>(context).choice;

    return SubpageSkeleton(
        title: Text("Hürden", style: theme.textTheme.headlineMedium),
        children: [
          Text("Zulassungshürden", style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          for (AdmissionHurdle hurdle in AdmissionHurdle.display(choice))
            HurdleInfoBox(hurdle: hurdle, conflictingHurdleResult: checkResults.where((result) => result.hurdle == hurdle).firstOrNull),

          const SizedBox(height: 16),
          Text("Anerkennungshürden", style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          for (GraduationHurdle hurdle in GraduationHurdle.display(choice))
            HurdleInfoBox(hurdle: hurdle, conflictingHurdleResult: checkResults.where((result) => result.hurdle == hurdle).firstOrNull),
        ]
    );
  }
}

class HurdleInfoBox extends StatelessWidget {
  const HurdleInfoBox({super.key, required this.hurdle, this.conflictingHurdleResult});

  final HurdleType hurdle;
  final HurdleCheckResult? conflictingHurdleResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse("https://www.gesetze-bayern.de/Content/Document/BayGSO-${hurdle is AdmissionHurdle ? "44" : "54"}#content");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: hurdle == conflictingHurdleResult?.hurdle ? theme.splashColor : theme.dividerColor,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hurdle == conflictingHurdleResult?.hurdle) ...[
                    Text(hurdle.paragraph, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(hurdle.desc, softWrap: true, overflow: TextOverflow.ellipsis, maxLines: 5, style: theme.textTheme.displayMedium?.copyWith(color: theme.primaryColor)),
                    const SizedBox(height: 8),
                    Text(conflictingHurdleResult!.text, style: theme.textTheme.displayMedium?.copyWith(fontStyle: FontStyle.italic)),
                  ] else ...[
                    Text(hurdle.paragraph, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Text(hurdle.desc, style: theme.textTheme.displayMedium),
                  ]
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (hurdle == conflictingHurdleResult?.hurdle)
              Icon(Icons.warning_rounded, size: 20, color: theme.indicatorColor)
            else
              Icon(Icons.check_circle_rounded, size: 20, color: theme.primaryColor),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

