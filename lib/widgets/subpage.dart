import 'package:flutter/material.dart';

class SubpageController extends StatefulWidget {
  final Widget child;

  const SubpageController({super.key, required this.child});

  static SubpageControllerState of(BuildContext context) {
    return context.findAncestorStateOfType<SubpageControllerState>()!;
  }

  @override
  State<SubpageController> createState() => SubpageControllerState();
}

class SubpageControllerState extends State<SubpageController> with SingleTickerProviderStateMixin {
  final List<_SubpageEntry> _stack = [];

  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isOpened = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.ease,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void openSubpage(Widget content, {Function(dynamic result)? callback}) {
    setState(() {
      _stack.add(_SubpageEntry(content, callback));
      _isOpened = true;
    });
    _controller.forward(from: 0);
  }

  void closeSubpage([dynamic result]) {
    _controller.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _isOpened = _stack.length > 1;
        var removed = _stack.removeLast();
        removed.callback?.call(result);
        if (_isOpened) _controller.value = 1;
      });
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final dy = details.primaryDelta ?? 0;
    final screenHeight = MediaQuery.sizeOf(context).height;

    var target = _controller.value - dy / screenHeight;
    _controller.value = target.clamp(0.0, 1.0); // Keep it within bounds
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_controller.value > 0.85 && details.velocity.pixelsPerSecond.dy < 400) {
      _controller.forward(); // keep open
    } else {
      closeSubpage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // the pages underneath the current one
          AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 - (_animation.value * 0.05),
                  child: Stack(children: [

                    // the root page
                    if (_stack.length > 1)
                      Transform.scale(
                          scale: 1 + (_animation.value * 0.05) - 0.05,
                          child: widget.child)
                    else widget.child,

                    if (_stack.length > 1)
                      Transform.scale(
                        scale: 1 + (_animation.value * 0.05),
                        child: Container(
                          color: Colors.black.withOpacity((1 - _animation.value) * 0.8),
                          height: MediaQuery.sizeOf(context).height,
                          width: MediaQuery.sizeOf(context).width,
                        ),
                      ),

                    ..._stack
                        .sublist(0, (_stack.length - 1).clamp(0, 100))
                        .map((element) => _buildSubpage(context, element.content))
                  ]),
                );
              }),

          // opaque background
          GestureDetector(
            onTap: closeSubpage,
            behavior: HitTestBehavior.deferToChild,
            child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => IgnorePointer(
                  ignoring: !_isOpened || _animation.value < 0.5,
                  child: Container(
                    color: Colors.black.withOpacity(_animation.value * 0.8),
                    height: MediaQuery.sizeOf(context).height,
                    width: MediaQuery.sizeOf(context).width,
                  ),
                )
            ),
          ),


          // current subpage
          if (_isOpened)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, MediaQuery.sizeOf(context).height * (1 - _animation.value)),
                child: _buildSubpage(context, _stack.lastOrNull!.content),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildSubpage(BuildContext context, Widget content) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Stack(
          children: [
            Positioned(
                top: 50 - 4 - 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    height: 4,
                    width: MediaQuery.sizeOf(context).width * 0.1,
                    decoration: BoxDecoration(
                      color: Theme.of(context).hintColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )),
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: GestureDetector(
                onVerticalDragUpdate: _handleDragUpdate,
                onVerticalDragEnd: _handleDragEnd,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.only(top: 36),
                  child: content,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SubpageEntry {
  final Widget content;
  final Function(dynamic result)? callback;

  _SubpageEntry(this.content, this.callback);
}
