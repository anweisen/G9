import 'package:hive/hive.dart';

import 'types.dart';
import '../provider/grades.dart';

part 'choice.g.dart';

// (LK)
// Mathe
//   - VK -> subsituieren?
// Deutsch
//   - VK -> subsituieren?
// 1. Fremdsprache        -    LK
// 1. Naturwissenschaft   -    LK
// 2. Fremdsprache / Naturwissenschaft    -   spät Spanisch / LK Info
// PuG 12      |  13?
// WR / Geo    |  13?
// Religion
// Geschichte
// Sport
// Kunst / Musik
// Seminar
// (Profil/Wahl)

class ChoiceBuilder {
  Subject? lk;
  Subject? mint1;
  Subject? sg1;
  Subject? mintSg2;
  Subject? sbs;
  bool? pug13;
  Subject? geoWr;
  Subject? musikKunst;
  Subject? vk;
  Subject? seminar;
  Subject? profil12;
  Subject? profil13;

  bool? substituteMathe;
  bool? substituteDeutsch;
  Subject? abi4;
  Subject? abi5;

  ChoiceBuilder();

  ChoiceBuilder.fromChoice(Choice choice) {
    lk = choice.lk;
    mint1 = choice.ntg1;
    sg1 = choice.sg1;
    sbs = choice.mintSg2.category == SubjectCategory.sbs ? choice.mintSg2 : null;
    mintSg2 = choice.mintSg2.category != SubjectCategory.sbs ? choice.mintSg2 : null;
    pug13 = choice.pug13;
    geoWr = choice.geoWr;
    musikKunst = choice.musikKunst;
    vk = choice.vk;
    seminar = choice.seminar;
    profil12 = choice.profil12;
    profil13 = choice.profil13;

    substituteMathe = choice.substituteMathe;
    substituteDeutsch = choice.substituteDeutsch;
    abi4 = choice.abi4;
    abi5 = choice.abi5;
  }

  Choice build() {
    if (lk == Subject.wr || lk == Subject.geo) {
      geoWr = lk;
      pug13 = false;
    } else if (lk == Subject.pug) {
      pug13 = true;
    } else if (lk == Subject.info) {
      mintSg2 = lk;
    } else if (lk!.category == SubjectCategory.ntg) {
      mint1 = lk;
    } else if (lk!.category == SubjectCategory.sg) {
      sg1 = lk;
    } else if (lk!.category == SubjectCategory.kumu) {
      musikKunst = lk;
    }

    if (sbs != null) {
      mintSg2 = sbs;
    }

    seminar = Subject.seminar;

    return Choice(
        // required
        lk!.id,
        sg1!.id,
        mint1!.id,
        mintSg2!.id,
        pug13!,
        geoWr!.id,
        musikKunst!.id,

        seminar!.id,

        // optional
        vk?.id,
        profil12?.id,
        profil13?.id,

        // abi
        substituteMathe ?? false,
        substituteDeutsch ?? false,
        abi4!.id,
        abi5!.id,
    );
  }
}

@HiveType(typeId: 1)
class Choice extends HiveObject {
  @HiveField(0)
  final SubjectId _lk;

  @HiveField(1)
  final SubjectId _sg1;

  @HiveField(2)
  final SubjectId _ntg1;

  @HiveField(3)
  final SubjectId _mintSg2;

  @HiveField(4)
  final bool pug13;

  @HiveField(5)
  final SubjectId _geoWr;

  @HiveField(6)
  final SubjectId _musikKunst;

  @HiveField(7)
  final SubjectId? _vk;

  @HiveField(8)
  final SubjectId _seminar;

  @HiveField(9)
  final SubjectId? _profil12;

  @HiveField(14)
  final SubjectId? _profil13;

  @HiveField(10)
  final bool substituteMathe;

  @HiveField(11)
  final bool substituteDeutsch;

  @HiveField(12)
  final SubjectId _abi4;

  @HiveField(13)
  final SubjectId _abi5;

  Subject _byId(SubjectId id) => Subject.byId[id]!;
  Subject? _byIdOpt(SubjectId? id) => id == null ? null : Subject.byId[id];

  Subject get lk => _byId(_lk);
  Subject get sg1 => _byId(_sg1);
  Subject get ntg1 => _byId(_ntg1);
  Subject get mintSg2 => _byId(_mintSg2);
  Subject get geoWr => _byId(_geoWr);
  Subject get musikKunst => _byId(_musikKunst);
  Subject? get vk => _byIdOpt(_vk);
  Subject? get profil12 => _byIdOpt(_profil12);
  Subject? get profil13 => _byIdOpt(_profil13);
  Subject get seminar => _byId(_seminar);
  Subject get abi4 => _byId(_abi4);
  Subject get abi5 => _byId(_abi5);

  List<Subject> get subjects => [
    // lk is already represented by the corresponding subject category (ntg1 / sg1 / sport / kumu)
    Subject.mathe,
    Subject.deutsch,
    sg1,
    ntg1,
    mintSg2,
    if (_vk != null) vk!,
    musikKunst,
    geoWr,
    Subject.pug,
    Subject.reli,
    Subject.geschi,
    Subject.sport,
    if (profil12 != null) profil12!,
    if (profil13 != null && profil13 != profil12) profil13!,
    seminar,
  ];

  List<Subject> get abiSubjects => [
    if (!substituteMathe) Subject.mathe else if (lk.category == SubjectCategory.ntg) mintSg2 else ntg1,
    if (!substituteDeutsch) Subject.deutsch else mintSg2,
    lk,
    abi4,
    abi5,
  ];

  List<Subject> subjectsToDisplayForSemester(Semester semester) {
    return subjects.where((subject) => hasSubjectInSemester(subject, Semester.mapSemesterToDisplaySemester(semester, subject.category))).toList();
  }

  bool hasSubjectInSemester(Subject subject, Semester semester) {
    if (semester == Semester.abi) return abiSubjects.contains(subject);
    if (subject == seminar || subject.category == SubjectCategory.seminar) return Semester.seminarPhase.contains(semester);
    if (subject == profil13) return (semester.order - 2) < numberOfSemestersFor(subject);
    return semester.order < numberOfSemestersFor(subject);
  }

  List<Semester> getSemestersForSubject(Subject subject) {
    int numSemesters = numberOfSemestersFor(subject);
    List<Semester> semesters = [];
    for (int i = 0; i < numSemesters; i++) {
      semesters.add(Semester.values[i]);
    }
    if (subject == seminar || subject.category == SubjectCategory.seminar) {
      semesters.add(Semester.seminar13);
    }
    if (abiSubjects.contains(subject)) {
      semesters.add(Semester.abi);
    }
    return semesters;
  }

  int numberOfSemestersFor(Subject subject) {
    // See also: results.dart

    // W-Seminar als Kurs mit HJ-Leistungen in Q12/1 und Q12/2,
    // in Q13 auch "zwei HJ-Leistungen" in Form der Seminararbeit (bis zu 30 Punkte)

    if (_vk != null) { // VK(sg/ntg): 2+2 Semester
      if (subject == vk || subject == mintSg2) {
        return 2;
      }
    } else if (subject.category == SubjectCategory.vk) { // VK als Profilfach
      return 2;
    }

    if (subject == seminar || subject.category == SubjectCategory.seminar) { // Seminararbeit
      return 2; // 2 Semester in Q12 normal, Seminararbeit in Q13 als extra Sonderregel!
    }

    if ((subject == profil12 || subject == profil13) && profil12 != profil13) {
      return 2;
    }

    if (!pug13 && subject == Subject.pug) {
      return 2;
    } else if (pug13 && subject == geoWr) {
      return 2;
    }

    if (!subjects.contains(subject)) {
      return 0;
    }

    return 4;
  }

  Choice(
    this._lk,
    this._sg1,
    this._ntg1,
    this._mintSg2,
    this.pug13,
    this._geoWr,
    this._musikKunst,
    this._seminar,
    this._vk,
    this._profil12,
    this._profil13,
    this.substituteMathe,
    this.substituteDeutsch,
    this._abi4,
    this._abi5,
  ) {
    Subject.all; // initialize subject instances
  }

  @override
  String toString() {
    return 'Choice{_lk: $_lk, _sg1: $_sg1, _ntg1: $_ntg1, _mintSg2: $_mintSg2, pug13: $pug13, _geoWr: $_geoWr, _musikKunst: $_musikKunst, _vk: $_vk, _seminar: $_seminar, _profil12: $_profil12, _profil13: $_profil13, substituteMathe: $substituteMathe, substituteDeutsch: $substituteDeutsch, _abi4: $_abi4, _abi5: $_abi5}';
  }
}
