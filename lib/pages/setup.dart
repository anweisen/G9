import 'dart:math';

import 'package:abi_app/provider/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/choice.dart';
import '../logic/types.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  late PageController _pageController;
  late ChoiceBuilder _choiceBuilder;
  late int _step;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _choiceBuilder = ChoiceBuilder();
    _step = 0;
  }

  void allowNextStep() {
    print("Allowing next step $_step");
    setState(() {
      _step = (_pageController.page?.ceil() ?? 0) + 1;
    });
  }

  void setLk(Subject? subject) {
    setState(() {
      _choiceBuilder.lk = subject;
    });
  }

  void setMusikKunst(Subject? subject) {
    setState(() {
      _choiceBuilder.musikKunst = subject;
    });
  }

  void setSbs(Subject? subject) {
    setState(() {
      _choiceBuilder.sbs = subject;
    });
  }

  void setGeoWr(Subject? subject) {
    setState(() {
      _choiceBuilder.geoWr = subject;
    });
  }

  void setPug13(Subject? subject) {
    setState(() {
      _choiceBuilder.pug13 = subject == Subject.pug;
    });
  }

  void setMint1(Subject? subject) {
    setState(() {
      _choiceBuilder.mint1 = subject;
    });
  }

  void setSg1(Subject? subject) {
    setState(() {
      _choiceBuilder.sg1 = subject;
    });
  }

  void setMintSg2(Subject? subject) {
    setState(() {
      _choiceBuilder.mintSg2 = subject;
    });
  }

  void setVk(Subject? subject) {
    setState(() {
      _choiceBuilder.vk = subject;
    });
  }

  void setProfil(Subject? subject) {
    setState(() {
      _choiceBuilder.profil = subject;
    });
  }

  void setSubstituteMathe(bool value) {
    setState(() {
      _choiceBuilder.substituteMathe = value;
    });
  }

  void setSubstituteDeutsch(bool value) {
    setState(() {
      _choiceBuilder.substituteDeutsch = value;
    });
  }

  void setAbi4(Subject? subject) {
    setState(() {
      _choiceBuilder.abi4 = subject;
    });
  }

  void setAbi5(Subject? subject) {
    setState(() {
      _choiceBuilder.abi5 = subject;
    });
  }

  List<Subject> _without(List<Subject> list, Subject? s1, [Subject? s2, Subject? s3]) {
    return list.where((element) => element.id != s1?.id && element.id != s2?.id && element.id != s3?.id).toList();
  }

  List<Subject> _withoutMany(List<Subject> list, List<Subject> without) {
    return list.where((element) => !without.contains(element)).toList();
  }

  List<Subject> _filter(List<Subject?> list) {
    return list.where((element) => element != null).map((e) => e!).toList();
  }

  SubjectCategory? getLkCategory () => _choiceBuilder.lk?.category;

  Subject? getGeoWr() {
    if (_choiceBuilder.lk == Subject.geo || _choiceBuilder.lk == Subject.wr) {
      return _choiceBuilder.lk;
    }
    return _choiceBuilder.geoWr;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageView(
          controller: _pageController,
          physics: SetupConstraintsScrollPhysics(getMaxAllowedPage: () => _step, pageController: _pageController),
          children: [
            ..._buildSteps(),

            SetupFinishPage(choiceBuilder: _choiceBuilder,)
          ],
        ));
  }

  List<SetupStepPage> _buildSteps() {
    return [
      SetupStepPage(
        title: "Musik oder Kunst",
        subjectsPool: [Subject.kunst, Subject.musik],
        pageController: _pageController,
        allowNextStep: allowNextStep,
        callback: setMusikKunst,
        currentlySelected: _choiceBuilder.musikKunst,
      ),
      SetupStepPage(
        title: "Dein Leistungsfach",
        pageController: _pageController,
        allowNextStep: allowNextStep,
        subjectsPool: Subject.lks.where((it) => it != (_choiceBuilder.musikKunst == Subject.kunst ? Subject.musik : Subject.kunst)).toList(),
        callback: setLk,
        currentlySelected: _choiceBuilder.lk,
      ),

      // 1. Naturwissenschaft/Sprache,
      // gesetzt durch LK NTG/SG
      if (getLkCategory() != SubjectCategory.sg)
        SetupStepPage(
          title: "1. Fremdsprache",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: Subject.allOf(SubjectCategory.sg),
          callback: setSg1,
          currentlySelected: _choiceBuilder.sg1,
        ),
      if (getLkCategory() != SubjectCategory.ntg)
        SetupStepPage(
          title: "1. Naturwissenschaft",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: Subject.allOf(SubjectCategory.ntg),
          callback: setMint1,
          currentlySelected: _choiceBuilder.mint1,
        ),

      // spät beginnende Fremdsprache als 2. Fremdsprache
      if (_choiceBuilder.lk != Subject.info)
        SetupStepPage(
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: Subject.allOf(SubjectCategory.sbs),
          title: "Spät beginnende Fremdsprache",
          canSkip: true,
          callback: setSbs,
          currentlySelected: _choiceBuilder.sbs,
        ),

      // 2. Fremdsprache oder Naturwissenschaft,
      // gesetzt durch spät beginnende Fremdsprache oder Informatik als LK
      if (_choiceBuilder.sbs == null && _choiceBuilder.lk != Subject.info)
        SetupStepPage(
          title: "2. Fremdsprache / Naturwissenschaft",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: _without(Subject.allOf(SubjectCategory.ntg, SubjectCategory.info, SubjectCategory.sg), _choiceBuilder.lk, _choiceBuilder.sg1, _choiceBuilder.mint1),
          callback: setMintSg2,
          currentlySelected: _choiceBuilder.mintSg2,
        ),
      if (_choiceBuilder.sbs == null && _choiceBuilder.lk != Subject.info)
        SetupStepPage(
          title: "Dein Vertiefungskurs, ersetzt ${_choiceBuilder.mintSg2?.name ?? ""}",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: [ if (_choiceBuilder.mintSg2?.category == SubjectCategory.sg) Subject.deutschVk else Subject.matheVk ],
          canSkip: true,
          callback: setVk,
          currentlySelected: _choiceBuilder.vk,
        ),

      if (_choiceBuilder.lk != Subject.wr && _choiceBuilder.lk != Subject.geo)
        SetupStepPage(
          title: "Geo oder WR",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: [Subject.geo, Subject.wr],
          callback: setGeoWr,
          currentlySelected: getGeoWr(),
        ),

      if (_choiceBuilder.lk != Subject.wr && _choiceBuilder.lk != Subject.geo && _choiceBuilder.lk != Subject.pug)
        SetupStepPage(
          title: "Weiterführung in Q13",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: [Subject.pug, if (getGeoWr() != null) getGeoWr()!,],
          callback: setPug13,
          currentlySelected: _choiceBuilder.pug13 == null ? null : (_choiceBuilder.pug13! ? Subject.pug : getGeoWr()),
        ),

      // Profilfach (Wahlfach, Vertiefungskurse wenn noch nicht gewählt, bisher unbelegte Kurse)
      SetupStepPage(
        title: "Profilfach",
        pageController: _pageController,
        allowNextStep: allowNextStep,
        subjectsPool: Subject.allOf(SubjectCategory.profil, _choiceBuilder.vk == null ? SubjectCategory.vk : null),
        canSkip: true,
        callback: setProfil,
        currentlySelected: _choiceBuilder.profil,
      ),

      //
      // Abiturprüfungsfächer
      //

      if (_choiceBuilder.lk?.category == SubjectCategory.sg && _choiceBuilder.mintSg2?.category == SubjectCategory.sg && _choiceBuilder.vk == null)
        SetupStepPage(
          title: "Deutsch Abi substituieren",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: [_choiceBuilder.mintSg2!],
          canSkip: true,
          callback: (subject) => setSubstituteDeutsch(subject != null),
          currentlySelected: _choiceBuilder.substituteDeutsch ?? false ? _choiceBuilder.mintSg2 : null,
        ),
      if ((_choiceBuilder.lk?.category == SubjectCategory.ntg || _choiceBuilder.lk?.category == SubjectCategory.info)
          && (_choiceBuilder.mintSg2?.category == SubjectCategory.ntg || _choiceBuilder.mintSg2?.category == SubjectCategory.info)
          && _choiceBuilder.vk == null)
        SetupStepPage(
          title: "Mathe Abi substituieren",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: [_choiceBuilder.mintSg2!],
          canSkip: true,
          callback: (subject) => setSubstituteMathe(subject != null),
          currentlySelected: _choiceBuilder.substituteMathe ?? false ? _choiceBuilder.mintSg2 : null,
        ),

      // Abiturprüfung in einem GPR-Fach verpflichtend
      if (_choiceBuilder.lk?.category != SubjectCategory.gpr)
        SetupStepPage(
          title: "Weiteres Abiturfach (GPR)",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: _filter([
            Subject.reli,
            Subject.geschi,
            if (_choiceBuilder.pug13 ?? true) Subject.pug else _choiceBuilder.geoWr,
          ]),
          callback: setAbi4,
          currentlySelected: _choiceBuilder.abi4,
        ),
      // Abiturprüfung in einer Fremdsprache oder Naturwissenschaft verpflichtend
      if (_choiceBuilder.lk?.category != SubjectCategory.ntg && _choiceBuilder.lk?.category != SubjectCategory.info && _choiceBuilder.lk?.category != SubjectCategory.sg)
        SetupStepPage(
          title: "Weiteres Abiturfach (NTG/SG)",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: _filter([
            _choiceBuilder.mint1,
            _choiceBuilder.sg1,
            if (_choiceBuilder.sbs != null)
              _choiceBuilder.sbs
            else if (_choiceBuilder.vk == null && !(_choiceBuilder.substituteDeutsch ?? false) && !(_choiceBuilder.substituteMathe ?? false))
              _choiceBuilder.mintSg2,
          ]),
          callback: _choiceBuilder.lk?.category == SubjectCategory.gpr ? setAbi5 : setAbi4,
          currentlySelected: _choiceBuilder.lk?.category == SubjectCategory.gpr ? _choiceBuilder.abi5 : _choiceBuilder.abi4,
        ),

      // Sind die verpflichtenden Abiturprüfungsfächer bereits gewählt, kann ein weiteres beliebiges Fach gewählt werden
      if (_choiceBuilder.lk != null && _choiceBuilder.abi5 == null)
        SetupStepPage(
          title: "Weiteres Abiturfach",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: _without(_filter([
                Subject.reli,
                Subject.geschi,
                _choiceBuilder.mint1,
                _choiceBuilder.sg1,
                if (_choiceBuilder.vk == null && !(_choiceBuilder.substituteDeutsch ?? false) && !(_choiceBuilder.substituteMathe ?? false))
                  _choiceBuilder.mintSg2,
                _choiceBuilder.musikKunst,
              ]), _choiceBuilder.abi4, _choiceBuilder.lk),
          callback: setAbi5,
          currentlySelected: _choiceBuilder.abi5,
        ),
    ];
  }
}

class SetupStepPage extends StatefulWidget {
  static final Subject skipSubject = Subject(id: -1, name: "Nicht gewählt", color: Colors.transparent, category: SubjectCategory.none);

  final PageController pageController;
  final void Function(Subject?) callback;
  final void Function() allowNextStep;
  final List<Subject> subjectsPool;
  final String title;
  final bool canSkip;
  final Subject? currentlySelected;

  const SetupStepPage({
    super.key,
    required this.pageController,
    required this.callback,
    required this.subjectsPool,
    required this.title,
    required this.currentlySelected,
    required this.allowNextStep,
    this.canSkip = false,
  });

  @override
  State<SetupStepPage> createState() => _SetupStepPageState();
}

class _SetupStepPageState extends State<SetupStepPage> with TickerProviderStateMixin {
  late List<Subject> _subjects;
  Subject? _selected;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _buttonAnimation;

  void onSearchChanged(String value) {
    setState(() {
      _selected = null;

      if (value.isEmpty) {
        _resetSubjectPool();
        return;
      }

      _subjects = widget.subjectsPool
          .where((element) => element.name.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  void selectSubject(Subject? subject) {
    if (_selected != null) {
      setState(() {
        _selected = null;
        _controller.reset();
      });
      return;
    }

    setState(() {
      _selected = subject;
      _controller.forward(from: 0.0);
    });
  }

  void _resetSubjectPool() {
    _subjects = (widget.canSkip) ? [SetupStepPage.skipSubject, ...widget.subjectsPool] : widget.subjectsPool;
  }

  @override
  void initState() {
    super.initState();
    _resetSubjectPool();
    _selected = widget.currentlySelected;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0, 0.45, curve: Curves.easeIn)));
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1, curve: Curves.ease)));
    _buttonAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const double leftOffset = 36;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: leftOffset),
              child: Text(widget.title,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.left),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(leftOffset, 0, leftOffset, 20),
              child: TextField(
                style: theme.textTheme.labelMedium,
                onChanged: onSearchChanged,
                onTap: () => selectSubject(null),
                decoration: InputDecoration(
                    hintText: "Suche ein Fach...",
                    hintStyle: theme.textTheme.labelMedium,
                    suffixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.primaryColor,
                    suffixIconColor: theme.scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ),
            Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 60),
                        itemCount: _subjects.length,
                        itemBuilder: (context, index) =>
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) => Transform(
                                transform: _selected == _subjects[index]
                                    ? Matrix4.translationValues(0, -(27.0 + 7*2) * index * _slideAnimation.value, 0) : Matrix4.identity(),
                                child: Opacity(
                                  opacity: _selected != null && _selected != _subjects[index]
                                      ? _fadeAnimation.value : 1,
                                  child: GestureDetector(
                                    onTap: () => selectSubject(_subjects[index]),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: leftOffset + 5),
                                      child: SubjectWidget(subject: _subjects[index], selected: _selected == _subjects[index]),
                                    ),
                                  ),
                                ),
                              ),
                            )),

                const SizedBox(height: 50, width: 50),

                if (_selected != null)
                  AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => NextButton(
                          text: "Nächster Schritt",
                          icon: Icons.chevron_right_rounded,
                          callback: () => {
                            widget.allowNextStep(),
                            if (widget.canSkip) {
                              widget.callback(_selected == SetupStepPage.skipSubject ? null : _selected!)
                            } else {
                              widget.callback(_selected!)
                            },
                            widget.pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease)
                          },
                          leftOffset: leftOffset,
                          animationProgress: _buttonAnimation.value))
              ],
            )),
          ],
        ),
      ),
    );
  }
}

class SetupConstraintsScrollPhysics extends BouncingScrollPhysics {
  final PageController pageController;
  final int Function() getMaxAllowedPage;

  const SetupConstraintsScrollPhysics({
    required this.getMaxAllowedPage,
    required this.pageController, ScrollPhysics? parent
  }) : super(parent: parent);

  @override
  SetupConstraintsScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SetupConstraintsScrollPhysics(
      getMaxAllowedPage: getMaxAllowedPage,
      pageController: pageController,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double offset) {
    final currentPage = (pageController.page?.floor() ?? 0);

    print("currentPage $currentPage, maxPage ${getMaxAllowedPage()}, pixels ${position.pixels}, offset $offset");

    // final currentPage = pageController.page?.round() ?? 0;

    // Allow bounce-like behavior if scrolling forward beyond maxAllowedPage
    if (offset > 0 && currentPage >= getMaxAllowedPage()) {
      final excess = offset - (getMaxAllowedPage() - currentPage) * position.viewportDimension;
      return excess > 0 ? excess : 0.0;
    }

    // Allow scrolling normally backward
    if (offset < 0) {
      return super.applyBoundaryConditions(position, offset);
    }

    return super.applyBoundaryConditions(position, offset);
  }
}

class SubjectWidget extends StatelessWidget {
  const SubjectWidget({super.key, required this.subject, this.selected = false});

  final Subject subject;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: subject == SetupStepPage.skipSubject ? const EdgeInsets.fromLTRB(0, 0, 0, 8) : const EdgeInsets.all(0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 27, maxHeight: 27),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (subject == SetupStepPage.skipSubject)
                    Icon(Icons.close_rounded, size: 22, color: Theme.of(context).textTheme.bodyMedium?.color, weight: 800,)
                  else Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8), color: subject.color),
                  width: 22,
                  height: 22,
                ),
                const SizedBox(width: 16),
                Text(subject.name, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            if (selected) const Icon(Icons.check)
          ],
        ),
      ),
    );
  }
}

class NextButton extends StatelessWidget {
  const NextButton({
    super.key,
    required this.leftOffset,
    required this.animationProgress,
    required this.callback,
    required this.text,
    required this.icon,
  });

  final double animationProgress;
  final double leftOffset;
  final void Function() callback;

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Positioned(
      right: leftOffset,
      left: leftOffset,
      bottom: (leftOffset / 2 + 28) * animationProgress - 28,
      child: Opacity(
        opacity: animationProgress,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: callback,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), color: theme.primaryColor),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(text, style: theme.textTheme.labelMedium),
                    Icon(icon, color: theme.textTheme.labelMedium?.color),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SetupFinishPage extends StatelessWidget {
  const SetupFinishPage({super.key, required this.choiceBuilder});

  final ChoiceBuilder choiceBuilder;

  @override
  Widget build(BuildContext context) {
    const double leftOffset = 36;
    final ThemeData theme = Theme.of(context);

    final built = choiceBuilder.build();

    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860, maxHeight: 1200),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 25, horizontal: leftOffset),
                child: Text("Abgeschlossen!",
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.left),
              ),
              Expanded(
                  child: Stack(
                children: [
                  ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 60),
                      itemCount: built.subjects.length,
                      itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 7, horizontal: leftOffset + 5),
                            child: SubjectWidget(
                                subject: built.subjects[index],
                                selected: false),
                          )),
                  const SizedBox(height: 50, width: 50),
                  NextButton(
                      text: "Abschließen",
                      icon: Icons.check_rounded,
                      callback: () => {
                        Provider.of<SettingsDataProvider>(context, listen: false).choice = built,
                        Navigator.popAndPushNamed(context, "/home")
                      },
                      leftOffset: leftOffset,
                      animationProgress: 1)
                ],
              )),
            ])));
  }
}
