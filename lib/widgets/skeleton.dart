import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'dart:ui';

import 'general.dart';
import 'nav.dart';
import 'subpage.dart';

class WindowTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const WindowTitleBar({super.key, this.child, this.padding = false});

  final Widget? child;
  final bool padding;

  static bool get isWindows => !kIsWeb && TargetPlatform.windows == defaultTargetPlatform;
  static double get height => isWindows ? appWindow.titleBarHeight : 0;

  static void focusWindow() {
    if (isWindows) {
      if (!appWindow.isMaximized) {
        appWindow.restore();
      }
      appWindow.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isWindows) {
      return child ?? Container();
    }

    final theme = Theme.of(context);
    final colors = WindowButtonColors(iconNormal: Colors.grey, mouseOver: theme.dividerColor, mouseDown: Colors.grey.shade900,);
    final closeColors = WindowButtonColors(iconNormal: Colors.grey, mouseOver: Colors.red.shade400, mouseDown: Colors.red.shade700);

    return Stack(
      children: [
        if (padding) Padding(
          padding: EdgeInsets.only(top: height),
          child: child,
        )
        else if (child != null) child!,
        Container(
          height: height,
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(child: MoveWindow()),
              Row(
                children: [
                  MinimizeWindowButton(colors: colors),
                  MaximizeWindowButton(colors: colors),
                  CloseWindowButton(colors: closeColors),
                ],
              )
            ],
          )
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size(double.infinity, height);
}

class PageSkeleton extends StatelessWidget {
  static const double leftOffset = 32;

  const PageSkeleton({super.key, required this.title, required this.children});

  final Widget title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return SubpageController(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: MediaQuery.of(context).platformBrightness == Brightness.dark
            ? SystemUiOverlayStyle.light // Light icons for dark mode
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          bottomNavigationBar: const Nav(),
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860, maxHeight: 1200),
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    stretch: true,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    pinned: true,
                    centerTitle: true,
                    automaticallyImplyLeading: false,
                    titleSpacing: 0,
                    leadingWidth: 0,
                    toolbarHeight: 64 + WindowTitleBar.height,
                    primary: true,
                    floating: true,
                    flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            constraints: constraints,
                            child: ClipRRect(
                                child: Container(
                                  padding: EdgeInsets.only(top: WindowTitleBar.height),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        theme.scaffoldBackgroundColor,
                                        theme.scaffoldBackgroundColor.withOpacity(0.6),
                                        theme.scaffoldBackgroundColor.withOpacity(0.4),
                                      ],
                                      stops: const [0.0, 0.4, 1.0],
                                    ),
                                  ),
                                  child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                      child: Padding(padding: const EdgeInsets.fromLTRB(leftOffset, 16, leftOffset, 10), child: title)),
                                )
                            ),
                          );
                        }),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: leftOffset),
                    sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          childCount: children.length,
                          (context, index) => children[index],
                        )
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  final String title;
  final Widget? info;

  const PageTitle({super.key, required this.title, this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        if (info != null) info!,
      ],
    );
  }
}

class SubpageSkeleton extends StatelessWidget {
  const SubpageSkeleton({super.key, this.title, required this.children, this.actions});

  final Widget? title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.cardColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              if (title != null) ...[
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  pinned: true,
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  leadingWidth: 0,
                  toolbarHeight: 64,
                  primary: true,
                  floating: true,
                  flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          constraints: constraints,
                          padding: const EdgeInsets.symmetric(horizontal: PageSkeleton.leftOffset / 2), // 2x half padding for better blur blending at the edges
                          child: ClipRRect(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      theme.cardColor,
                                      theme.cardColor,
                                      theme.cardColor.withOpacity(0.6),
                                      theme.cardColor.withOpacity(0.2),
                                    ],
                                    stops: const [0.0, 0.1, 0.4, 1.0],
                                  ),
                                ),
                                child: SafeBackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                    child: Padding(padding: const EdgeInsets.fromLTRB(PageSkeleton.leftOffset / 2, 16, PageSkeleton.leftOffset / 2, 10), child: title!)),
                              )
                          ),
                        );
                      }
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8,))
              ],

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: PageSkeleton.leftOffset),
                sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: children.length, (context, index) => children[index],
                    )
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40,))
            ],
          ),

          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

