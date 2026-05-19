import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../logic/choice.dart';
import '../logic/types.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import '../widgets/skeleton.dart';
import 'change.dart';
import 'settings.dart';

class ChangeVkPage extends StatelessWidget {
  const ChangeVkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsDataProvider>(context);
    final grades = Provider.of<GradesDataProvider>(context);

    final choice = settings.choice!;

    bool hasVk = choice.vk != null;
    bool hasVkAsProfile = choice.profil12?.category == SubjectCategory.vk;
    Subject? vk = hasVk ? choice.vk : hasVkAsProfile ? choice.profil12 : null;
    // vk ersatz nur: wenn ntg/info/sg (kein sbs, nicht abwählbar) und abgewähltes fach nicht im abi (z.B. bei substituieren)
    bool canUseVk = (choice.mintSg2.category == SubjectCategory.ntg || choice.mintSg2.category == SubjectCategory.info) ? !choice.abiSubjects.contains(choice.mintSg2)
        : (choice.mintSg2.category == SubjectCategory.sg) ? !choice.abiSubjects.contains(choice.mintSg2)
        : false;
    // änderung zu vk: mintSg2 wird abgewählt -> canUseVk
    bool canSwitchAsProfile = (hasVk && choice.profil12 == null) || (hasVkAsProfile && choice.vk == null && canUseVk);
    // deutschVK: only allow both sg (not sbs) ; matheVk: only allow both ntg (not info)
    bool canSwitchVkReplacement = !choice.abiSubjects.contains(choice.sg1) && choice.mintSg2.category == SubjectCategory.sg
        || !choice.abiSubjects.contains(choice.ntg1) && choice.mintSg2.category == SubjectCategory.ntg;

    List<ChangeAbiChoiceResult> results = [];

    if (canSwitchAsProfile) {
      if (hasVk) {
        Choice modifiedChoice = (ChoiceBuilder.fromChoice(choice)
          ..profil12 = choice.vk
          ..vk = null
        ).build();
        results.add(ChangeAbiChoiceResult.createChoiceResult(modifiedChoice, grades));
      } else if (hasVkAsProfile) {
        Choice modifiedChoice = (ChoiceBuilder.fromChoice(choice)
          ..vk = choice.profil12
          ..profil12 = null
        ).build();
        results.add(ChangeAbiChoiceResult.createChoiceResult(modifiedChoice, grades));
      }
    }
    if (hasVk && canSwitchVkReplacement) {
      if (vk == Subject.deutschVk) {
        Choice modifiedChoice = (ChoiceBuilder.fromChoice(choice)
          ..sg1 = choice.mintSg2
          ..mintSg2 = choice.sg1
        ).build();
        results.add(ChangeAbiChoiceResult.createChoiceResult(modifiedChoice, grades));
      } else if (vk == Subject.matheVk) {
        Choice modifiedChoice = (ChoiceBuilder.fromChoice(choice)
          ..mint1 = choice.mintSg2
          ..mintSg2 = choice.ntg1
        ).build();
        results.add(ChangeAbiChoiceResult.createChoiceResult(modifiedChoice, grades));
      }
    }
    if (!hasVkAsProfile && !hasVk && canUseVk) {
      Choice modifiedChoice = (ChoiceBuilder.fromChoice(choice)
        ..vk = choice.mintSg2.category == SubjectCategory.sg ? Subject.deutschVk : Subject.matheVk
      ).build();
      results.add(ChangeAbiChoiceResult.createChoiceResult(modifiedChoice, grades));
    }
    if (!hasVkAsProfile && !hasVk && canSwitchVkReplacement) {
      Choice modifiedChoice = (ChoiceBuilder.fromChoice(choice)
        ..vk = choice.mintSg2.category == SubjectCategory.sg ? Subject.deutschVk : Subject.matheVk
        ..sg1 = choice.mintSg2.category == SubjectCategory.sg ? choice.mintSg2 : choice.sg1
        ..mint1 = choice.mintSg2.category == SubjectCategory.ntg ? choice.mintSg2 : choice.ntg1
        ..mintSg2 = choice.mintSg2.category == SubjectCategory.sg ? choice.sg1 : choice.ntg1
      ).build();
      results.add(ChangeAbiChoiceResult.createChoiceResult(modifiedChoice, grades));
    }
    if (!hasVkAsProfile && !hasVk && choice.profil12 == null) {
      Choice modifiedChoice = (ChoiceBuilder.fromChoice(choice)
        ..profil12 = (choice.mintSg2.category == SubjectCategory.ntg || choice.mintSg2.category == SubjectCategory.info) ? Subject.matheVk : Subject.deutschVk
      ).build();
      results.add(ChangeAbiChoiceResult.createChoiceResult(modifiedChoice, grades));
    }

    ChangeAbiChoiceResult.sortChoiceResults(results);

    ChangeAbiChoiceResult originalResult = ChangeAbiChoiceResult.createChoiceResult(choice, grades);

    return SubpageSkeleton(
      title: const PageTitle(title: "Vertiefungskurs tauschen"),
      children: [

        Text("Aktuelle Vertiefungskurswahl", style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        if (!hasVk && !hasVkAsProfile)
          Text("Keinen Vertiefungskurs gewählt", style: theme.textTheme.bodyMedium?.copyWith(height: 1.1))
        else ...[
          SmallSubjectWidget(subject: vk!, old: false, choice: choice),
          SmallSubjectWidget(subject: choice.mintSg2, old: hasVk, choice: choice, includeAbiTag: true,),
          SmallSubjectWidget(subject: vk == Subject.deutschVk ? choice.sg1 : choice.ntg1, old: false, choice: choice, includeAbiTag: true,),
        ],

        if (results.isEmpty) ...[
          const SizedBox(height: 20),
          Text("Tauschmöglichkeiten", style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text("Kein einfacher Tausch aufgrund Fächerwahl möglich", style: theme.textTheme.bodyMedium?.copyWith(height: 1.1))
        ] else for (final result in results) ...[
          const SizedBox(height: 16),
          ChangeAbiChoiceResultWidget(
            modifiedResult: result,
            originalResult: originalResult,
            buildHeadline: (context, theme) => [
              SmallSubjectWidget(subject: (result.choice.vk ?? result.choice.profil12)!, old: false, choice: result.choice),
              SmallSubjectWidget(subject: result.choice.mintSg2, old: result.choice.vk != null, choice: result.choice, includeAbiTag: true,),
              SmallSubjectWidget(subject: (result.choice.vk ?? result.choice.profil12)! == Subject.deutschVk ? result.choice.sg1 : result.choice.ntg1, old: false, choice: choice, includeAbiTag: true,),
            ],
          ),
        ],

        const SizedBox(height: 36,),

        SettingsPage.buildButton(theme, "Fächerwahl ändern", Icons.published_with_changes_rounded, () => context.push("/setup"), small: true),

      ]
    );
  }
}

class ChangeVkChoiceResult {

}
