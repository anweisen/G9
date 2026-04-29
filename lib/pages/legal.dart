import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/skeleton.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  Future<String> _loadPrivacyPolicy() async {
    return await rootBundle.loadString("assets/content/privacy.md");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UnauthorizedPageSkeleton(
        children: [
          FutureBuilder(future: _loadPrivacyPolicy(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator(color: theme.primaryColor,)),
                );
              } else if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.splashColor,
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 16,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: theme.disabledColor, size: 24,),
                      Flexible(child: Text("Fehler beim Laden der Datenschutzinformationen", style: theme.textTheme.displayMedium?.copyWith(color: theme.disabledColor, fontSize: 16, height: 0), softWrap: true,)),
                    ],
                  )
                );
              } else {
                return MarkdownBody(
                  onTapLink: (text, href, title) {
                    final uri = Uri.parse(href!);
                    canLaunchUrl(uri).then((can) => {
                      if (can) launchUrl(uri, mode: LaunchMode.externalApplication)
                    });
                  },
                  styleSheet: MarkdownStyleSheet(
                    // custom style: only used elements...
                    h1: theme.textTheme.headlineMedium,
                    h2: theme.textTheme.bodyMedium,
                    p: theme.textTheme.displayMedium?.copyWith(color: theme.shadowColor, height: 0),
                    a: theme.textTheme.displayMedium?.copyWith(color: theme.primaryColor, height: 0),
                  ),
                  data: snapshot.data as String
                );
              }
            }
          ),
        ]
    );
  }
}
