import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/general.dart';
import '../widgets/skeleton.dart';

class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const WindowTitleBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const G9TitleBar(),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.go("/welcome"),
              child: Row(
                spacing: 16,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(),
                  Container(
                    height: 46,
                    width: 48,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.chevron_left_rounded, color: theme.shadowColor, size: 28,),
                  ),

                  ShimmerContainer(
                    shimmerColor: theme.primaryColor.withValues(alpha: 0.1),
                    duration: const Duration(milliseconds: 1500),
                    child: Container(
                      height: 46,
                      width: 190,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 12,
                        children: [
                          Text("404", style: theme.textTheme.displayMedium?.copyWith(color: theme.shadowColor, fontWeight: FontWeight.w600, fontSize: 16, height: 0)),
                          Text("Zur Startseite", style: theme.textTheme.displayMedium?.copyWith(color: theme.shadowColor, fontSize: 16, height: 0)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

