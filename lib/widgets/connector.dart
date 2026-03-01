import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/account.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import 'general.dart';
import 'skeleton.dart';

class SyncApiConnectorLoadingWidget extends StatefulWidget {
  const SyncApiConnectorLoadingWidget({super.key});

  @override
  State<SyncApiConnectorLoadingWidget> createState() => _SyncApiConnectorLoadingWidgetState();
}

class _SyncApiConnectorLoadingWidgetState extends State<SyncApiConnectorLoadingWidget> with TickerProviderStateMixin {
  static bool done = false;

  late final AnimationController _controller;
  late final Animation<double> _containerAnimation;

  late final AnimationController _stageController;
  late final Animation<double> _stageAnimation;
  late final Animation<Offset> _stageOffsetAnimation;

  bool _visible = false;
  int _stageIndex = 0;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _containerAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    _stageController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _stageAnimation = CurvedAnimation(parent: _stageController, curve: Curves.easeOutExpo);
    _stageOffsetAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0.0),
      end: Offset.zero,
    ).animate(_stageAnimation);

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!done) {
        show();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _stageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void show() {
    if (_visible) return;

    setState(() {
      _visible = true;
    });
    _controller.forward();
  }

  void hide() {
    done = true;
    if (!_visible) return;

    _controller.reverse().then((value) {
      if (mounted) {
        setState(() {
          _visible = false;
        });
      }
    });
  }

  void setStage(int index) {
    if (index == _stageIndex) return;

    if (!_visible && ConnectorLoadingStage.stages[index].isLoading) {
      done = false;
      show();
    }

    _stageController.forward(from: 0);

    if (!ConnectorLoadingStage.stages[index].isLoading) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) hide();
      });
    }

    setState(() {
      _stageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountDataProvider>();
    final gradesProvider = context.watch<GradesDataProvider>();
    final settingsProvider = context.watch<SettingsDataProvider>();

    setStage(ConnectorLoadingStage.determineStage(accountProvider, gradesProvider, settingsProvider));

    if (!_visible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final stage = ConnectorLoadingStage.stages[_stageIndex];

    return AnimatedBuilder(
      animation: _containerAnimation,
      builder: (context, child) => Positioned(
          top: (WindowTitleBar.height + 80) * _containerAnimation.value - (80),
          left: PageSkeleton.leftOffset / 2,
          right: PageSkeleton.leftOffset / 2,
          child: Transform.scale(
            scale: 0.8 + 0.2 * _containerAnimation.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.all(1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(width: 1, color: theme.primaryColor.withOpacity(.1)),
                  color: theme.dividerColor.withOpacity(.86),
                  // border: Border.all(width: 1, color: theme.primaryColor.withOpacity(.66)),
                  // color: theme.primaryColor.withOpacity(.2),
                ),
                height: 60,
                child: SafeBackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    repaintDelay: const Duration(milliseconds: 10),
                    child: AnimatedBuilder(
                      animation: _stageAnimation,
                      builder: (context, child) => Opacity(
                        opacity: min(_stageAnimation.value, _containerAnimation.value),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(stage.icon, color: stage.color(theme), size: 24),
                                const SizedBox(width: 12,),
                                SlideTransition(
                                  position: _stageOffsetAnimation,
                                  child: Text(stage.text, style: theme.textTheme.bodyMedium?.copyWith(color: stage.color(theme), fontSize: 16), softWrap: true, maxLines: 2, overflow: TextOverflow.ellipsis,)
                                ),
                                const SizedBox(width: 6,),
                                if (stage.isLoading) DotLoadingIndicator(style: theme.textTheme.bodyMedium!, duration: const Duration(milliseconds: 1500))
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
              ),
            ),
          )),
    );
  }
}

class ConnectorLoadingStage {
  static final List<ConnectorLoadingStage> stages = [
    ConnectorLoadingStage("Lokale Daten laden", Icons.find_in_page_outlined, (theme) => theme.primaryColor),
    ConnectorLoadingStage("Anmeldung läuft", Icons.login_rounded, (theme) => theme.primaryColor),
    ConnectorLoadingStage("Daten synchronisieren", Icons.cloud_download_outlined, (theme) => theme.primaryColor),
    ConnectorLoadingStage("Nicht angemeldet", Icons.person_off_rounded, (theme) => theme.primaryColor, false),
    ConnectorLoadingStage("Synchronisation erfolgreich", Icons.check_circle_outline_rounded, (theme) => theme.indicatorColor, false),
    ConnectorLoadingStage("Synchronisation fehlgeschlagen", Icons.cloud_off_outlined, (theme) => theme.disabledColor, false),
    ConnectorLoadingStage("Willkommen zurück", Icons.waving_hand_outlined, (theme) => theme.primaryColor, false),
  ];
  static const int loading = 0, authenticating = 1, syncing = 2, signin = 3, success = 4, error = 5, fallback = 6;

  static int determineStage(AccountDataProvider accountProvider, GradesDataProvider gradesProvider, SettingsDataProvider settingsProvider) {
    return determine(accountProvider.hasLoaded && gradesProvider.hasLoaded && settingsProvider.hasLoaded, accountProvider.isAuthenticating, accountProvider.isSyncing, accountProvider.hasSynced, accountProvider.hasSyncingFailed, accountProvider.isLoggedIn);
  }

  static ConnectorLoadingStage fromProviders(AccountDataProvider accountProvider, GradesDataProvider gradesProvider, SettingsDataProvider settingsProvider) {
    return stages[determineStage(accountProvider, gradesProvider, settingsProvider)];
  }

  static int determine(bool hasLoaded, bool isAuthenticating, bool isSyncing, bool hasSynced, bool hasSyncingFailed, bool isLoggedIn) {
    if (!hasLoaded) return loading;
    if (isAuthenticating) return authenticating;
    if (isSyncing) return syncing;
    if (hasSynced) return success;
    if (hasSyncingFailed) return error;
    if (!isLoggedIn) return signin;
    return fallback;
  }

  final String text;
  final IconData icon;
  final Color Function(ThemeData) color;
  final bool isLoading;

  ConnectorLoadingStage(this.text, this.icon, this.color, [this.isLoading = true]);
}
