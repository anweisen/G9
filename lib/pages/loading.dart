import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/account.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import '../widgets/connector.dart';
import '../widgets/general.dart';
import '../widgets/skeleton.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: WindowTitleBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            G9TitleBar(key: ValueKey("splash-title"),),
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1.0);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0.0),
      end: Offset.zero,
    ).animate(_animation);
    super.initState();
    print("NEW STATE");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateStage(ConnectorLoadingStage newStage) {
    if (_currentStage != newStage) {
      if (_currentStage != null) _controller.forward(from: 0);
      _currentStage = newStage; // no need to mark for rebuild via setState (is called from build)
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
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      width: 260, // arbitrary but fits
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, animation) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: _animation.value * 0.4 + 0.6,
                child: Icon(stage.icon, size: 20, color: theme.shadowColor)
              ),
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
          );
        }
      ),
    );
  }
}


