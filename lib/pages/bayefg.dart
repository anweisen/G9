import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/hurdles.dart';
import '../provider/settings.dart';
import '../widgets/skeleton.dart';

class BayEfgHurdlePage extends StatelessWidget {
  const BayEfgHurdlePage({super.key, required this.checkResults});

  final List<HurdleCheckResult> checkResults;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SubpageSkeleton(
        title: const PageTitle(title: "Auswahlhürden BayEFG"),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hürden des gymnasialen Auswahlverfahrens für das Max-Weber-Programm nach dem Bayerischen Elite-Förderungsgesetz (BayEFG). Stand 2026", style: theme.textTheme.displayMedium?.copyWith(color: theme.primaryColor, height: 0)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    const url = "https://www.elitenetzwerk.bayern.de/start/foerderangebote/max-weber-programm/von-der-schule-zum-stipendium";
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new_rounded, color: theme.primaryColor, size: 18,),
                        const SizedBox(width: 10,),
                        Text("Weitere Informationen", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16)),
                      ],

                    ),
                  ),
                ),
              ],
            )
          ),

          const SizedBox(height: 12),

          Text("Vorauswahlhürden", style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          for (BayEfgHurdle hurdle in BayEfgHurdle.values.where((hurdle) => !hurdle.finalCheckAfterAbi))
            HurdleInfoBox(hurdle: hurdle, conflictingHurdleResult: checkResults.where((result) => result.hurdle == hurdle).firstOrNull),

          const SizedBox(height: 16),
          Text("Finale Auswahlhürden", style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          for (BayEfgHurdle hurdle in BayEfgHurdle.values.where((hurdle) => hurdle.finalCheckAfterAbi))
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
        final uri = Uri.parse("https://www.gesetze-bayern.de/Content/Document/BayDVEFG-5#content");
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
              Icon(Icons.warning_rounded, size: 20, color: theme.disabledColor)
            else
              Icon(Icons.check_circle_rounded, size: 20, color: theme.primaryColor),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

