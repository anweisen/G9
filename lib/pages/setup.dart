import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/skeleton.dart';
import '../widgets/general.dart';
import '../provider/settings.dart';
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

  void setProfil12(Subject? subject) {
    setState(() {
      _choiceBuilder.profil12 = subject;
    });
  }

  void setProfil13(Subject? subject) {
    setState(() {
      _choiceBuilder.profil13 = subject;
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

  List<Widget> sublistSteps(List<Widget> list) {
    return list.sublist(0, min(list.length, _step + 1));
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
        appBar: const WindowTitleBar(),
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          children: sublistSteps([
            ..._buildSteps(),
            SetupFinishPage(choiceSupplier: () => _choiceBuilder.build()),
          ]),
        ));
  }

  List<SetupStepPage> _buildSteps() {
    return [
      SetupStepPage(
        key: const ValueKey("lk"),
        title: "Leistungsfach",
        pageController: _pageController,
        allowNextStep: allowNextStep,
        subjectsPool: Subject.lks,
        callback: setLk,
        currentlySelected: _choiceBuilder.lk,
      ),
      if (getLkCategory() != SubjectCategory.kumu)
        SetupStepPage(
          key: const ValueKey("kumu"),
          title: "Musik oder Kunst",
          subjectsPool: [Subject.kunst, Subject.musik],
          pageController: _pageController,
          allowNextStep: allowNextStep,
          callback: setMusikKunst,
          currentlySelected: _choiceBuilder.musikKunst,
        ),

      // 1. Naturwissenschaft/Sprache,
      // gesetzt durch LK NTG/SG
      if (getLkCategory() != SubjectCategory.sg)
        SetupStepPage(
          key: const ValueKey("sg1"),
          title: "1. Fremdsprache",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: Subject.allOf(SubjectCategory.sg),
          callback: setSg1,
          currentlySelected: _choiceBuilder.sg1,
        ),
      if (getLkCategory() != SubjectCategory.ntg)
        SetupStepPage(
          key: const ValueKey("mint1"),
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
          key: const ValueKey("sbs"),
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: Subject.allOf(SubjectCategory.sbs),
          title: "Spät beginnende Fremdsprache",
          canSkip: true,
          callback: setSbs,
          currentlySelected: _choiceBuilder.sbs,
        ),

      // 2. Fremdsprache oder Naturwissenschaft oder Informatik,
      // gesetzt durch spät beginnende Fremdsprache oder Informatik als LK
      if (_choiceBuilder.sbs == null && _choiceBuilder.lk != Subject.info)
        SetupStepPage(
          key: const ValueKey("mintSg2"),
          title: "2. Fremdsprache / Naturwissenschaft / Informatik",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: _without(Subject.allOf(SubjectCategory.ntg, SubjectCategory.info, SubjectCategory.sg), _choiceBuilder.lk, _choiceBuilder.sg1, _choiceBuilder.mint1),
          callback: setMintSg2,
          currentlySelected: _choiceBuilder.mintSg2,
        ),
      if (_choiceBuilder.sbs == null && _choiceBuilder.lk != Subject.info)
        SetupStepPage(
          key: const ValueKey("vk"),
          title: "Vertiefungskurs, ersetzt ${_choiceBuilder.mintSg2?.name} in Q13",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: [ if (_choiceBuilder.mintSg2?.category == SubjectCategory.sg) Subject.deutschVk else Subject.matheVk ],
          canSkip: true,
          callback: setVk,
          currentlySelected: _choiceBuilder.vk,
        ),

      if (_choiceBuilder.lk != Subject.wr && _choiceBuilder.lk != Subject.geo)
        SetupStepPage(
          key: const ValueKey("geowr"),
          title: "Geo oder WR",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: [Subject.geo, Subject.wr],
          callback: setGeoWr,
          currentlySelected: getGeoWr(),
        ),

      if (_choiceBuilder.lk != Subject.wr && _choiceBuilder.lk != Subject.geo && _choiceBuilder.lk != Subject.pug)
        SetupStepPage(
          key: const ValueKey("pug13"),
          title: "Weiterführung in Q13",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: [Subject.pug, if (getGeoWr() != null) getGeoWr()!,],
          callback: setPug13,
          currentlySelected: _choiceBuilder.pug13 == null ? null : (_choiceBuilder.pug13! ? Subject.pug : getGeoWr()),
        ),

      // Profilfach in Q13 (Wahlfach, Vertiefungskurse wenn noch nicht gewählt, bisher unbelegte Kurse)
      SetupStepPage(
        key: const ValueKey("profil12"),
        title: "Profilfach Q12",
        pageController: _pageController,
        allowNextStep: allowNextStep,
        subjectsPool: Subject.allOf(SubjectCategory.profil, _choiceBuilder.vk == null ? SubjectCategory.vk : null),
        canSkip: true,
        callback: setProfil12,
        currentlySelected: _choiceBuilder.profil12,
      ),

      // Profilfach in Q13 (Wahlfach, bisher unbelegte Kurse), Vertiefungskurse nur in Q12 möglich
      SetupStepPage(
        key: const ValueKey("profil13"),
        title: "Profilfach Q13",
        pageController: _pageController,
        allowNextStep: allowNextStep,
        subjectsPool: Subject.allOf(SubjectCategory.profil),
        canSkip: true,
        callback: setProfil13,
        currentlySelected: _choiceBuilder.profil13,
      ),

      //
      // Abiturprüfungsfächer
      //

      // https://www.gesetze-bayern.de/Content/Document/BayGSO-48
      // (1) 1. Die Abiturprüfung erstreckt sich auf fünf verschiedene Fächer.
      //     2. Verpflichtende Abiturprüfungsfächer sind Deutsch, Mathematik und das Leistungsfach.
      //     3. Sie werden auf erhöhtem Anforderungsniveau geprüft.
      //     4. Unter den fünf Abiturprüfungsfächern müssen mindestens eine fortgeführte Fremdsprache oder eine Naturwissenschaft
      //        sowie mindestens ein Fach aus dem gesellschaftswissenschaftlichen Aufgabenfeld als Abiturprüfungsfächer gewählt werden.
      //     5. Deutsch kann durch die Wahl zweier fortgeführter Fremdsprachen als Abiturprüfungsfächer, eines davon als Leistungsfach,
      //        Mathematik durch die Wahl zweier Naturwissenschaften oder einer Naturwissenschaft und der Informatik als Abiturprüfungsfächer,
      //        jeweils eines davon als Leistungsfach, nach Wahl der Schülerinnen und Schüler ersetzt werden (Substitution).
      //     6. Bei Substitution von Mathematik ist die Abiturprüfung in einer Fremdsprache verpflichtend

      if (_choiceBuilder.lk?.category == SubjectCategory.sg && _choiceBuilder.mintSg2?.category == SubjectCategory.sg && _choiceBuilder.vk == null)
        SetupStepPage(
          key: const ValueKey("subD"),
          title: "Deutsch Abi substituieren",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: [_choiceBuilder.mintSg2!],
          canSkip: true,
          callback: (subject) => setSubstituteDeutsch(subject != null),
          currentlySelected: _choiceBuilder.substituteDeutsch ?? false ? _choiceBuilder.mintSg2 : null,
        ),
      if ((_choiceBuilder.lk?.category == SubjectCategory.ntg && (_choiceBuilder.mintSg2?.category == SubjectCategory.ntg || _choiceBuilder.mintSg2?.category == SubjectCategory.info)
          || _choiceBuilder.lk?.category == SubjectCategory.info && _choiceBuilder.mint1?.category == SubjectCategory.ntg)
          && _choiceBuilder.vk == null)
        SetupStepPage(
          key: const ValueKey("subM"),
          title: "Mathe Abi substituieren",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: [_choiceBuilder.lk?.category == SubjectCategory.ntg ? _choiceBuilder.mintSg2! : _choiceBuilder.mint1!],
          canSkip: true,
          callback: (subject) => setSubstituteMathe(subject != null),
          currentlySelected: _choiceBuilder.substituteMathe ?? false ? _choiceBuilder.mintSg2 : null,
        ),
      // Bei Substitution von Mathe ist eine weitere Fremdsprache verpflichtend (bei Deutsch ist keine Naturwissenschaft verpflichtend)
      if (_choiceBuilder.substituteMathe ?? false)
        SetupStepPage(
          key: const ValueKey("abi5sg"),
          title: "Weiteres Abiturfach",
          infobox: "Bei Substitution von Mathematik muss eine fortgeführte Fremdsprache als Abiturprüfungsfach gewählt werden",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: [_choiceBuilder.sg1!, if (_choiceBuilder.mintSg2 != null && (_choiceBuilder.mintSg2!.category == SubjectCategory.sg)) _choiceBuilder.mintSg2!],
          callback: (subject) => setAbi5(subject),
          currentlySelected: _choiceBuilder.abi5,
        ),

      // Abiturprüfung in einem GPR-Fach verpflichtend
      if (_choiceBuilder.lk?.category != SubjectCategory.gpr)
        SetupStepPage(
          key: const ValueKey("abi4gpr"),
          title: "Weiteres Abiturfach",
          infobox: "Es muss mindestens eine Gesellschaftswissenschaft als Abiturprüfungsfach gewählt werden",
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
      // Abiturprüfung in einer fortgeführten Fremdsprache oder Naturwissenschaft verpflichtend (Informatik zählt nicht als Naturwissenschaft)
      if (_choiceBuilder.lk?.category != SubjectCategory.ntg && _choiceBuilder.lk?.category != SubjectCategory.sg
          && !(_choiceBuilder.substituteDeutsch ?? false) && !(_choiceBuilder.substituteMathe ?? false))
        SetupStepPage(
          key: const ValueKey("abi45mintsg"),
          title: "Weiteres Abiturfach",
          infobox: "Es muss mindestens eine fortgeführte Fremdsprache oder eine Naturwissenschaft als Abiturprüfungsfach gewählt werden",
          pageController: _pageController,
          allowNextStep: allowNextStep,
          subjectsPool: _filter([
            _choiceBuilder.mint1,
            _choiceBuilder.sg1,
            if (_choiceBuilder.vk == null && _choiceBuilder.mintSg2?.category != SubjectCategory.info
                && !(_choiceBuilder.substituteDeutsch ?? false) && !(_choiceBuilder.substituteMathe ?? false))
              _choiceBuilder.mintSg2,
          ]),
          callback: _choiceBuilder.lk?.category == SubjectCategory.gpr ? setAbi4 : setAbi5,
          currentlySelected: _choiceBuilder.lk?.category == SubjectCategory.gpr ? _choiceBuilder.abi4 : _choiceBuilder.abi5,
        ),

      // Sind die verpflichtenden Abiturprüfungsfächer bereits gewählt, kann ein weiteres beliebiges Fach gewählt werden
      // (!) before the check was whether abi5 was still null but led to a glitch when confirming this choice
      if (_choiceBuilder.lk != null && (_choiceBuilder.lk?.category == SubjectCategory.gpr || _choiceBuilder.lk?.category == SubjectCategory.ntg || _choiceBuilder.lk?.category == SubjectCategory.sg)
          &&  !(_choiceBuilder.substituteMathe ?? false))
        SetupStepPage(
          key: const ValueKey("abi5any"),
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
                if (_choiceBuilder.pug13 ?? false)
                  Subject.pug
                else
                  _choiceBuilder.geoWr,
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
  final String? infobox;
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
    this.infobox,
    this.canSkip = false,
  });

  @override
  State<SetupStepPage> createState() => _SetupStepPageState();
}

class _SetupStepPageState extends State<SetupStepPage> with TickerProviderStateMixin {
  Subject? _selected;
  late List<Subject> _subjects;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _buttonAnimation;
  late ScrollController _scrollController;

  void onSearchChanged(String value) {
    setState(() {
      _selected = null;
      _controller.reverse();

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
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: const Interval(0.3, 1, curve: Curves.ease));

    if (subject == null || _selected != null) {
      setState(() {
        _selected = null;
        _controller.reverse();
      });
      return;
    }

    setState(() {
      _selected = subject;
      _controller.forward();
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
    _scrollController = ScrollController();

    if (_selected != null) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const double leftOffset = PageSkeleton.leftOffset;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: leftOffset),
              child: Text(widget.title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.left),
            ),
            if (widget.infobox != null) Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(leftOffset, 8, leftOffset, 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: const BorderRadius.all(Radius.circular(8))
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded, color: theme.textTheme.displayMedium?.color, size: 16),
                  const SizedBox(width: 12),
                  Expanded(child: CustomLineBreakText(widget.infobox!, style: theme.textTheme.bodySmall?.copyWith(height: 1.25))),
                ],
              ),
            ) else const SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.fromLTRB(leftOffset, 0, leftOffset, 22),
              child: TextField(
                style: theme.textTheme.labelMedium,
                onChanged: onSearchChanged,
                onTap: () => selectSubject(null),
                decoration: InputDecoration(
                    hintText: "Suche ein Fach...",
                    hintStyle: theme.textTheme.labelMedium,
                    filled: true,
                    fillColor: theme.primaryColor,
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.search),
                    ),
                    suffixIconColor: theme.scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            Expanded(
                child: Stack(
                  children: [
                    if (_selected != null) AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => Transform(
                        transform: Matrix4.translationValues(0,
                            ((27.0 + 7*2) * _subjects.indexOf(_selected!) + (widget.canSkip && _selected != SetupStepPage.skipSubject ? 8 : 0)) * (1 - _slideAnimation.value)
                            - (_scrollController.positions.isNotEmpty ? _scrollController.offset : 0), 0),
                        child: GestureDetector(
                          onTap: () => selectSubject(_selected),
                          child: Container(
                            width: double.infinity,
                            color: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: leftOffset + 5),
                            child: SubjectWidget(subject: _selected!, selected: true),
                          ),
                        ),
                      ),
                    ),

                    ListView.builder(
                        physics: _selected == null
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) =>
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) => Opacity(
                            opacity: _selected != null ? _subjects[index] == _selected ? 0 : _fadeAnimation.value : 1,
                            child: GestureDetector(
                              onTap: () => selectSubject(_subjects[index]),
                              child: Container(
                                width: double.infinity,
                                color: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: leftOffset + 5),
                                child: SubjectWidget(subject: _subjects[index], selected: _selected == _subjects[index]),
                              ),
                            ),
                          ),
                        )
                    ),

                    const SizedBox(height: 50, width: 50),

                    AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) => BackButton(
                            icon: Icons.chevron_left_rounded,
                            callback: () {
                              // 375 = 500 * (24 / leftOffset)
                              widget.pageController.previousPage(duration: const Duration(milliseconds: 375), curve: Curves.ease);
                            },
                            leftOffset: leftOffset,
                            animationProgress: 1 - _buttonAnimation.value)),
                    AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) => NextButton(
                            text: "Nächster Schritt",
                            icon: Icons.chevron_right_rounded,
                            callback: () {
                              if (!widget.canSkip && _selected == null) return;
                              widget.allowNextStep();
                              if (widget.canSkip) {
                                widget.callback(_selected == SetupStepPage.skipSubject ? null : _selected!);
                              } else {
                                widget.callback(_selected!);
                              }
                              // 375 = 500 * (24 / leftOffset)
                              widget.pageController.nextPage(duration: const Duration(milliseconds: 375), curve: Curves.ease);
                            },
                            leftOffset: leftOffset,
                            animationProgress: _buttonAnimation.value)
                    ),
              ],
            )),
          ],
        ),
      ),
    );
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
                else
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: subject.color),
                    width: 22,
                    height: 22,
                  ),
                const SizedBox(width: 10),
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
      left: leftOffset,
      right: leftOffset,
      bottom: (leftOffset + 24) * animationProgress,
      child: Opacity(
        opacity: animationProgress,
        child: Material(
          color: Colors.transparent,
          child: IgnorePointer(
            ignoring: animationProgress < 0.5,
            child: InkWell(
              onTap: callback,
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: theme.primaryColor),
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

class BackButton extends StatelessWidget {
  const BackButton({
    super.key,
    required this.leftOffset,
    required this.animationProgress,
    required this.callback,
    required this.icon,
  });

  final double animationProgress;
  final double leftOffset;
  final void Function() callback;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Positioned(
      left: leftOffset,
      bottom: 24 + leftOffset + (leftOffset + 24) * (1 - animationProgress),
      child: Opacity(
        opacity: animationProgress,
        child: InkWell(
          onTap: callback,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: theme.dividerColor),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(height: 28, child: Icon(icon, color: theme.primaryColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SetupFinishPage extends StatelessWidget {
  const SetupFinishPage({super.key, required this.choiceSupplier});

  final Choice Function() choiceSupplier;

  @override
  Widget build(BuildContext context) {
    const double leftOffset = PageSkeleton.leftOffset;
    final ThemeData theme = Theme.of(context);

    final Choice choice = choiceSupplier();

    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860, maxHeight: 1200),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25, horizontal: leftOffset),
                child: Text("Abgeschlossen!",
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.left),
              ),
              Expanded(
                  child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(leftOffset + 5, 0, leftOffset + 5, 120),
                    children: buildSubjects(choice, theme),
                  ),
                  const SizedBox(height: 50, width: 50),
                  NextButton(
                      text: "Bestätigen",
                      icon: Icons.check_rounded,
                      callback: () => {
                        Provider.of<SettingsDataProvider>(context, listen: false).choice = choice,
                        Navigator.popAndPushNamed(context, "/home")
                      },
                      leftOffset: leftOffset,
                      animationProgress: 1)
                ],
              )),
            ])));
  }

  static List<Widget> buildSubjects(Choice choice, ThemeData theme) {
    const double labelSpacing = 5, sectionSpacing = 20, subjectSpacing = 3;

    return [
      Text("Leistungsfach", style: theme.textTheme.bodySmall),
      const SizedBox(height: labelSpacing),
      SubjectWidget(subject: choice.lk),
      const SizedBox(height: sectionSpacing),

      // 1. Fremdsprache
      if (choice.lk != choice.sg1) ...[
        Text("1. Fremdsprache", style: theme.textTheme.bodySmall),
        const SizedBox(height: labelSpacing),
        SubjectWidget(subject: choice.sg1),
        const SizedBox(height: sectionSpacing),
      ],

      // 1. Naturwissenschaft
      if (choice.lk != choice.ntg1) ...[
        Text("1. Naturwissenschaft", style: theme.textTheme.bodySmall),
        const SizedBox(height: labelSpacing),
        SubjectWidget(subject: choice.ntg1),
        const SizedBox(height: sectionSpacing),
      ],

      // 2. Fremdsprache / Naturwissenschaft
      Text("2. Fremdsprache / Naturwissenschaft / Informatik", style: theme.textTheme.bodySmall),
      const SizedBox(height: labelSpacing),
      SubjectWidget(subject: choice.mintSg2),
      const SizedBox(height: sectionSpacing),

      // Kunst / Musik
      Text("Kunst oder Musik", style: theme.textTheme.bodySmall),
      const SizedBox(height: labelSpacing),
      SubjectWidget(subject: choice.musikKunst),
      const SizedBox(height: sectionSpacing),

      // Geo / WR
      Text("Geographie oder Wirtschaft & Recht in Q12", style: theme.textTheme.bodySmall),
      const SizedBox(height: labelSpacing),
      SubjectWidget(subject: choice.geoWr),
      const SizedBox(height: sectionSpacing),

      // Weiterführung in Q13 (PuG vs Geo / WR)
      Text("Weiterführung in Q13", style: theme.textTheme.bodySmall),
      const SizedBox(height: labelSpacing),
      SubjectWidget(subject: choice.pug13 ? Subject.pug : choice.geoWr),
      const SizedBox(height: sectionSpacing),

      // Pflichtfächer
      Text("Pflichtfächer", style: theme.textTheme.bodySmall),
      const SizedBox(height: labelSpacing),
      SubjectWidget(subject: Subject.mathe),
      const SizedBox(height: subjectSpacing),
      SubjectWidget(subject: Subject.deutsch),
      const SizedBox(height: subjectSpacing),
      if (choice.lk != Subject.sport) ...[
        SubjectWidget(subject: Subject.sport),
        const SizedBox(height: subjectSpacing),
      ],
      if (choice.lk != Subject.reli) ...[
        SubjectWidget(subject: Subject.reli),
        const SizedBox(height: subjectSpacing),
      ],
      if (choice.lk != Subject.geschi) ...[
        SubjectWidget(subject: Subject.geschi),
        const SizedBox(height: subjectSpacing),
      ],
      if (choice.lk != Subject.pug) ...[
        SubjectWidget(subject: Subject.pug),
        const SizedBox(height: subjectSpacing),
      ],
      SubjectWidget(subject: choice.seminar),
      const SizedBox(height: sectionSpacing),

      // Vertiefungskurs (optional, ersetzt mintSg2 in Q13), nicht mit spät beginnender Fremdsprache
      Text("Vertiefungskurs", style: theme.textTheme.bodySmall),
      const SizedBox(height: labelSpacing),
      SubjectWidget(subject: choice.vk ?? SetupStepPage.skipSubject),
      const SizedBox(height: sectionSpacing),

      // Profilfach (optional)
      Text("Profilfach Q12 / Q13", style: theme.textTheme.bodySmall),
      const SizedBox(height: labelSpacing),
      SubjectWidget(subject: choice.profil12 ?? SetupStepPage.skipSubject),
      SubjectWidget(subject: choice.profil13 ?? SetupStepPage.skipSubject),
      const SizedBox(height: sectionSpacing),

      // Prüfungsfächer
      Text("Abiturprüfungsfächer", style: theme.textTheme.bodySmall),
      const SizedBox(height: labelSpacing),
      ...choice.abiSubjects.map((e) => Column(
        children: [
          SubjectWidget(subject: e),
          const SizedBox(height: subjectSpacing),
        ],
      )).toList(),

    ];
  }

}
