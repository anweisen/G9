
import 'package:abi_app/widgets/nav.dart';
import 'package:flutter/material.dart';

import 'subpage.dart';

class PageSkeleton extends StatefulWidget {
  static const double leftOffset = 36;

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
    return SubpageController(
      child: Scaffold(
        bottomNavigationBar: const Nav(),
        extendBody: true,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860, maxHeight: 1200),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: PageSkeleton.leftOffset),
                  child: widget.title,
                ),
                ListView(
                    padding: const EdgeInsets.fromLTRB(0, 60, 0, 60),
                    children: widget.children)
              ],
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
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        if (info != null) info!,
      ],
    );
  }
}
