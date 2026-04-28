import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/account.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import '../widgets/general.dart';
import '../widgets/connector.dart';
import 'welcome.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedG9TitleBar(key: ValueKey("splash-title"), duration: Duration(milliseconds: 500),),
            SizedBox(height: 24),
            LoadingPageConnectorStage(key: ValueKey("splash-stage"),),
          ],
        ),
      ),
    );
  }
}

class LoadingPageConnectorStage extends StatefulWidget {
  const LoadingPageConnectorStage({super.key});

  @override
  State<LoadingPageConnectorStage> createState() => _LoadingPageConnectorStageState();
}

class _LoadingPageConnectorStageState extends State<LoadingPageConnectorStage> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _offsetAnimation;

  ConnectorLoadingStage? _currentStage;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0.0),
      end: Offset.zero,
    ).animate(_animation);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateStage(ConnectorLoadingStage newStage) {
    if (_currentStage != newStage) {
      setState(() {
        _currentStage = newStage;
        _controller.forward(from: 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountDataProvider>();
    final gradesProvider = context.watch<GradesDataProvider>();
    final settingsProvider = context.watch<SettingsDataProvider>();

    final theme = Theme.of(context);

    ConnectorLoadingStage stage = ConnectorLoadingStage.fromProviders(accountProvider, gradesProvider, settingsProvider);
    _updateStage(stage);
    stage = _currentStage ?? stage;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, animation) {
          return Opacity(
            opacity: _animation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(stage.icon, size: 20, color: theme.shadowColor),
                const SizedBox(width: 10,),
                Flexible(
                  child: SlideTransition(
                      position: _offsetAnimation,
                      child: Text(stage.text, style: theme.textTheme.displayMedium?.copyWith(color: theme.shadowColor, fontWeight: FontWeight.w600, height: 0), softWrap: true,)
                  ),
                ),
                const SizedBox(width: 6,),
                DotLoadingIndicator(style: theme.textTheme.displayMedium!.copyWith(color: theme.shadowColor, fontWeight: FontWeight.w600, height: 0), duration: const Duration(milliseconds: 1000))
              ],
            ),
          );
        }
      ),
    );
  }
}


