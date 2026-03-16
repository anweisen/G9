import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../api/files.dart';
import '../logic/grades.dart';
import '../provider/account.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import '../widgets/connector.dart';
import '../widgets/general.dart';
import '../widgets/subpage.dart';
import '../widgets/skeleton.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = Provider.of<AccountDataProvider>(context);
    final grades =  Provider.of<GradesDataProvider>(context);
    final settings = Provider.of<SettingsDataProvider>(context);

    final stage = ConnectorLoadingStage.fromProviders(account, grades, settings);

    return SubpageSkeleton(
        title: Text("Account", style: theme.textTheme.headlineMedium),
        children: [
          if (account.isLoggedIn)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(account.userProfile!.picture, width: 48, height: 48, errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle_rounded, size: 48))
                    ),
                    const SizedBox(width: 16,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.userProfile!.name, style: theme.textTheme.bodyMedium),
                        Text(account.privateProfile!.email, style: theme.textTheme.bodySmall?.copyWith(height: 1.3)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16,),

                Text("Erstellt: ${GradeHelper.formatDate(account.privateProfile!.createdAt)}", style: theme.textTheme.displayMedium),
                const SizedBox(height: 2,),
                Text("Provider: ${account.provider}", style: theme.textTheme.displayMedium),
                const SizedBox(height: 2,),
                Text("Id: ${account.userProfile!.id}", style: theme.textTheme.displayMedium),
                const SizedBox(height: 20,),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AccountActionButton(
                      text: stage.text,
                      icon: stage.icon,
                      textColor: stage.color(theme),
                      backgroundColor: null,
                      borderColor: theme.dividerColor,
                      onTap: null,
                      suffix: stage.isLoading ? DotLoadingIndicator(style: theme.textTheme.bodyMedium!.copyWith(fontSize: 16), duration: const Duration(milliseconds: 1500)) : null,
                    ),
                    AccountActionButton(
                      text: null,
                      icon: Icons.sync_rounded,
                      textColor: account.isSyncing ? theme.shadowColor : theme.primaryColor,
                      backgroundColor: null,
                      borderColor: theme.dividerColor,
                      onTap: account.isSyncing ? null : () => account.syncStoredData(settings, grades),
                    )
                  ],
                ),

                const SizedBox(height: 20,),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AccountActionButton(
                        text: "Abmelden",
                        icon: Icons.logout_rounded,
                        textColor: theme.disabledColor,
                        backgroundColor: null,
                        borderColor: theme.dividerColor,
                        onTap: account.logout
                    ),
                    AccountActionButton(
                      text: "Account löschen",
                      icon: Icons.delete_rounded,
                      textColor: theme.disabledColor,
                      backgroundColor: theme.splashColor,
                      borderColor: theme.splashColor,
                      onTap: null,
                      createSubpage: () => const ConfirmDeleteAccountDialoge(),
                    )
                  ],
                ),

                const SizedBox(height: 20,),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AccountActionButton(
                        text: "Daten exportieren",
                        icon: Icons.download_rounded,
                        textColor: theme.primaryColor,
                        backgroundColor: null,
                        borderColor: theme.dividerColor,
                        onTap: () async {
                          final data = await account.api.getExportData();
                          await FileExportService.exportJson("user_data", data);
                        }
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Du bist nicht angemeldet. Melde dich an, um alle Features nutzen zu können, wie die Synchronisation deiner Daten. Derzeit wird nur die Anmeldung über einen Googleaccount unterstützt, um die Sicherheit deiner Daten zu gewährleisten.", style: theme.textTheme.displayMedium,),
                GestureDetector(
                  onTap: () => Api.doGoogleLoginAndSync(context),
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.shadowColor, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_circle_rounded, color: theme.shadowColor, size: 32,),
                        const SizedBox(width: 16,),
                        Column(
                          children: [
                            const SizedBox(height: 4,),
                            Text("mit Google", style: theme.textTheme.bodySmall,),
                            Text("anmelden", style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
            )
        ]);
  }
}

class AccountActionButton extends StatelessWidget {
  const AccountActionButton({super.key, required this.text, required this.icon, required this.textColor, required this.backgroundColor, required this.borderColor, required this.onTap, this.createSubpage, this.suffix});

  final Widget? suffix;
  final String? text;
  final IconData icon;
  final Color textColor;
  final Color? backgroundColor;
  final Color borderColor;
  final void Function()? onTap;
  final Widget Function()? createSubpage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: createSubpage != null ? () => SubpageController.of(context).openSubpage(createSubpage!()) : onTap,
      child: Container(
        padding: text != null ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6) : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
          color: backgroundColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: textColor,),
            if (text != null) ...[
              const SizedBox(width: 8,),
              Text(text!, style: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontSize: 15, height: 1.5), softWrap: true, maxLines: 2, overflow: TextOverflow.ellipsis,),
            ],
            if (suffix != null) ...[
              const SizedBox(width: 5,),
              suffix!,
            ]
          ],
        ),
      ),
    );
  }
}

class ConfirmDeleteAccountDialoge extends StatelessWidget {
  const ConfirmDeleteAccountDialoge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountProvider = Provider.of<AccountDataProvider>(context);
    return SubpageSkeleton(
      title: Text("Account löschen", style: theme.textTheme.headlineMedium),
      children: [
        Text("Bist du sicher, dass du deinen Account löschen möchtest? Diese Aktion ist unwiderruflich. Deine Daten sind weiterhin lokal in der App verfügbar.", style: Theme.of(context).textTheme.displayMedium,),
        const SizedBox(height: 24,),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            AccountActionButton(
              text: "Abbrechen",
              icon: Icons.close_rounded,
              textColor: Theme.of(context).primaryColor,
              backgroundColor: null,
              borderColor: Theme.of(context).dividerColor,
              onTap: () => SubpageController.of(context).closeSubpage(),
            ),
            AccountActionButton(
              text: "Account löschen",
              icon: Icons.delete_rounded,
              textColor: theme.disabledColor,
              backgroundColor: theme.splashColor,
              borderColor: theme.splashColor,
              onTap: () {
                accountProvider.deleteAccount();
                SubpageController.of(context).closeSubpage();
              },
            )
          ],
        )
      ]
    );
  }
}


