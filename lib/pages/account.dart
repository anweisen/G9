import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../api/files.dart';
import '../api/types.dart';
import '../logic/grades.dart';
import '../provider/account.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import '../widgets/connector.dart';
import '../widgets/general.dart';
import '../widgets/subpage.dart';
import '../widgets/skeleton.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {

  late Future<AccountSessionsResponseBody?> _sessionsFuture;
  bool expandedSessions = false;

  @override
  void initState() {
    super.initState();
    final accountProvider = Provider.of<AccountDataProvider>(context, listen: false);
    _sessionsFuture = accountProvider.api.getSessions(accountProvider.refreshToken);
  }

  void _reloadSessions() {
    final accountProvider = Provider.of<AccountDataProvider>(context, listen: false);
    setState(() {
      _sessionsFuture = accountProvider.api.getSessions(accountProvider.refreshToken);
    });
  }

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
                      onTap: account.isSyncing ? null : () => account.syncStoredData(settings, grades, notifyInstantly: true),
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

                const SizedBox(height: 30,),
                GestureDetector(
                  onTap: () => setState(() => expandedSessions = !expandedSessions),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: theme.dividerColor,
                    ),
                    child: FutureBuilder(
                      future: _sessionsFuture,
                      builder: (context, snapshot) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (snapshot.hasError) ...[
                            Row(
                              spacing: 4,
                              children: [
                                Text("Geräte", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: theme.primaryColor, fontWeight: FontWeight.w600, fontSize: 15)),
                                Icon(Icons.error_outline_rounded, size: 16, color: theme.disabledColor,),
                              ],
                            ),
                          ] else if (!snapshot.hasData) ...[
                            Row(
                              spacing: 4,
                              children: [
                                Text("Geräte", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: theme.primaryColor, fontWeight: FontWeight.w600, fontSize: 15)),
                                DotLoadingIndicator(style: theme.textTheme.displayMedium!.copyWith(height: 0, fontWeight: FontWeight.w700, color: theme.primaryColor, fontSize: 15), duration: const Duration(milliseconds: 1000)),
                              ],
                            ),
                          ] else ...[
                            Row(
                              spacing: 8,
                              children: [
                                Text("Geräte", style: theme.textTheme.displayMedium?.copyWith(height: 0, color: theme.primaryColor, fontWeight: FontWeight.w600, fontSize: 15)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: theme.shadowColor.withValues(alpha: 0.1),
                                  ),
                                  child: Text("${snapshot.data!.sessions.length}", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, height: 0))
                                ),
                              ],
                            ),
                            AnimatedDrawerTransition(
                              expanded: expandedSessions,
                              duration: Duration(milliseconds: snapshot.data!.sessions.isEmpty ? 500 : clampDouble(snapshot.data!.sessions.length * 30, 300, 750).toInt()),
                              margin: const EdgeInsets.only(bottom: 4, top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: theme.shadowColor.withValues(alpha: 0.1),
                                ),
                                child: Column(
                                  spacing: 5,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var session in snapshot.data!.sessions)
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        spacing: 14,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: session.id == snapshot.data?.currentSessionId ? theme.indicatorColor
                                                  : (session.lastRefreshed != null && DateTime.now().difference(session.lastRefreshed!).inHours <= 1) ? theme.primaryColor
                                                  : theme.shadowColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(session.deviceName.truncateTo(28), style: theme.textTheme.displayMedium?.copyWith(height: 0, color: theme.primaryColor)),
                                              Text("gültig bis ${GradeHelper.formatDate(session.expiry)}", style: theme.textTheme.bodySmall?.copyWith(height: 1.5), softWrap: false, overflow: TextOverflow.ellipsis, maxLines: 1),
                                            ],
                                          ),
                                          const Spacer(),
                                          if (session.id != snapshot.data?.currentSessionId)
                                            GestureDetector(
                                              onTap: () async {
                                                setState(() {
                                                  _sessionsFuture = Future.value(null);
                                                });
                                                await account.api.postDeleteSession(session.id);
                                                _reloadSessions();
                                              },
                                              child: Icon(Icons.remove_circle_outline_outlined, size: 18, color: theme.disabledColor,)
                                            ),
                                        ],
                                      )
                                  ],
                                ),
                              )
                            ),
                          ],
                        ],
                      )
                    ),
                  ),
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
              Flexible(child: Text(text!, style: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontSize: 15, height: 0), softWrap: true, maxLines: 1, overflow: TextOverflow.ellipsis,)),
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


