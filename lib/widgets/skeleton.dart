import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ui';

import 'nav.dart';
import 'subpage.dart';

class PageSkeleton extends StatefulWidget {
  static const double leftOffset = 32;

  const PageSkeleton({super.key, required this.title, required this.children});

  final Widget title;
  final List<Widget> children;

  @override
  State<PageSkeleton> createState() => _PageSkeletonState();
}

class _PageSkeletonState extends State<PageSkeleton> {

  @override
  void dispose() {
    super.dispose();
  }

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

          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860, maxHeight: 1200),
              child: CustomScrollView(
                slivers: [

                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    pinned: true,
                    centerTitle: true,
                    automaticallyImplyLeading: false,
                    titleSpacing: 0,
                    leadingWidth: 0,
                    toolbarHeight: 64,
                    primary: true,
                    shadowColor: Colors.transparent,
                    // expandedHeight: 156,
                    floating: true,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          constraints: constraints,
                          child: ClipRRect(
                              child: Container(
                                color: theme.scaffoldBackgroundColor.withOpacity(.6),
                                child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                                    child: Padding(padding: const EdgeInsets.fromLTRB(PageSkeleton.leftOffset, 16, PageSkeleton.leftOffset, 10), child: widget.title)),
                              )),
                        );
                      }
                    ),
                  ),

                  SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: PageSkeleton.leftOffset),
                      sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            childCount: widget.children.length,
                                (context, index) => widget.children[index],
                          )
                      ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 60))

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
