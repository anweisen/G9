import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

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
@JsonSerializable(ignoreUnannotated: true)
class Choice extends HiveObject {
  @HiveField(0) @JsonKey(name: "lk")
  final SubjectId lkId;

  @HiveField(1) @JsonKey(name: "sg1")
  final SubjectId sg1Id;

  @HiveField(2) @JsonKey(name: "ntg1")
  final SubjectId ntg1Id;

  @HiveField(3) @JsonKey(name: "mint_sg2")
  final SubjectId mintSg2Id;

  @HiveField(4) @JsonKey(name: "pug13")
  final bool pug13;

  @HiveField(5) @JsonKey(name: "geo_wr")
  final SubjectId geoWrId;

  @HiveField(6) @JsonKey(name: "ku_mu")
  final SubjectId musikKunstId;

  @HiveField(7) @JsonKey(name: "vk")
  final SubjectId? vkId;

  @HiveField(8) @JsonKey(name: "sem")
  final SubjectId seminarId;

  @HiveField(9) @JsonKey(name: "profil12")
  final SubjectId? profil12Id;

  @HiveField(14) @JsonKey(name: "profil13")
  final SubjectId? profil13Id;

  @HiveField(10) @JsonKey(name: "sub_m")
  final bool substituteMathe;

  @HiveField(11) @JsonKey(name: "sub_d")
  final bool substituteDeutsch;

  @HiveField(12) @JsonKey(name: "abi4")
  final SubjectId abi4Id;

  @HiveField(13) @JsonKey(name: "abi5")
  final SubjectId abi5Id;

  factory Choice.dummy() => (ChoiceBuilder()
      ..lk = Subject.english
      ..musikKunst = Subject.kunst
      ..mint1 = Subject.bio
      ..mintSg2 = Subject.info
      ..geoWr = Subject.geo
      ..pug13 = true
      ..abi4 = Subject.geschi
      ..abi5 = Subject.bio
    ).build();

  Subject _byId(SubjectId id) => Subject.byId[id]!;
  Subject? _byIdOpt(SubjectId? id) => id == null ? null : Subject.byId[id];

  Subject get lk => _byId(lkId);
  Subject get sg1 => _byId(sg1Id);
  Subject get ntg1 => _byId(ntg1Id);
  Subject get mintSg2 => _byId(mintSg2Id);
  Subject get geoWr => _byId(geoWrId);
  Subject get musikKunst => _byId(musikKunstId);
  Subject? get vk => _byIdOpt(vkId);
  Subject? get profil12 => _byIdOpt(profil12Id);
  Subject? get profil13 => _byIdOpt(profil13Id);
  Subject get seminar => _byId(seminarId);
  Subject get abi4 => _byId(abi4Id);
  Subject get abi5 => _byId(abi5Id);

  List<Subject> get subjects => [
    // lk is already represented by the corresponding subject category (ntg1 / sg1 / sport / kumu)
    Subject.mathe,
    Subject.deutsch,
    sg1,
    ntg1,
    mintSg2,
    if (vkId != null) vk!,
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

    if (vkId != null) { // VK(sg/ntg): 2+2 Semester
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
    this.lkId,
    this.sg1Id,
    this.ntg1Id,
    this.mintSg2Id,
    this.pug13,
    this.geoWrId,
    this.musikKunstId,
    this.seminarId,
    this.vkId,
    this.profil12Id,
    this.profil13Id,
    this.substituteMathe,
    this.substituteDeutsch,
    this.abi4Id,
    this.abi5Id,
  ) {
    Subject.all; // initialize subject instances
  }

  factory Choice.fromJson(Map<String, dynamic> json) => _$ChoiceFromJson(json);
  Map<String, dynamic> toJson() => _$ChoiceToJson(this);

  @override
  String toString() {
    return 'Choice{lk: $lkId, sg1: $sg1Id, ntg1: $ntg1Id, mintSg2: $mintSg2Id, pug13: $pug13, geoWr: $geoWrId, musikKunst: $musikKunstId, vk: $vkId, seminar: $seminarId, profil12: $profil12Id, profil13: $profil13Id, substituteMathe: $substituteMathe, substituteDeutsch: $substituteDeutsch, abi4: $abi4Id, abi5: $abi5Id}';
  }
}

enum ChoiceRestriction {
  impossible(null),

  subD(null),
  subM("Bei Substitution von Mathe muss eine fortgeführte Fremdsprache oder eine Naturwissenschaft als Abiturprüfungsfach gewählt werden"),

  abiGpr("Es muss mindestens eine Gesellschaftswissenschaft als Abiturprüfungsfach gewählt werden"),
  abiSgNtg("Es muss mindestens eine fortgeführte Fremdsprache oder eine Naturwissenschaft als Abiturprüfungsfach gewählt werden"),
  abiSgSubM("Bei Substitution von Mathematik muss eine fortgeführte Fremdsprache als Abiturprüfungsfach gewählt werden"),
  abiAny(null),
  ;

  final String? text;

  const ChoiceRestriction(this.text);
}

class ChoiceOptions {
  final ChoiceRestriction restriction;
  final List<Subject> subjects;
  final bool allowNone;

  bool get isEmpty => subjects.isEmpty;
  bool get isSingle => subjects.length == 1 && !allowNone;

  ChoiceOptions(this.restriction, this.subjects, [this.allowNone = false]);

  ChoiceOptions.empty() : this(ChoiceRestriction.impossible, []);
}

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
class ChoiceHelper {

  // (!) Die einzelnen Optionen bauen aufeinander auf und müssen in der richtigen Reihenfolge geprüft werden,
  //     da sie sich (teilweise) gegenseitig beeinflussen/einschränken (in der Reihenfolge der Methoden in dieser Klasse)

  static ChoiceOptions getSubMatheOptions(ChoiceBuilder choiceBuilder) {
    if ((choiceBuilder.lk?.category == SubjectCategory.ntg && (choiceBuilder.mintSg2?.category == SubjectCategory.ntg || choiceBuilder.mintSg2?.category == SubjectCategory.info)
        || choiceBuilder.lk?.category == SubjectCategory.info && choiceBuilder.mint1?.category == SubjectCategory.ntg)
        && choiceBuilder.vk == null) {
      return ChoiceOptions(ChoiceRestriction.subM, [
        if (choiceBuilder.lk?.category == SubjectCategory.info && choiceBuilder.mint1 != null)
          choiceBuilder.mint1!,
        if (choiceBuilder.lk?.category == SubjectCategory.ntg && choiceBuilder.mintSg2 != null)
          choiceBuilder.mintSg2!,
      ], true);
    }
    return ChoiceOptions.empty();
  }

  static ChoiceOptions getSubDeutschOptions(ChoiceBuilder choiceBuilder) {
    if (choiceBuilder.lk?.category == SubjectCategory.sg && choiceBuilder.mintSg2?.category == SubjectCategory.sg && choiceBuilder.vk == null) {
      return ChoiceOptions(ChoiceRestriction.subD, [
        if (choiceBuilder.mintSg2 != null)
          choiceBuilder.mintSg2!,
      ], true);
    }
    return ChoiceOptions.empty();
  }

  // Für das 4. Abiturfach werden folgende Einschränkungen abgedeckt, in absteigender Priorität:
  // 1. GPR-Fach [danach vollständig erfüllt]
  //    (wenn kein GPR-LK)
  // 2. fortgeführte Fremdsprache / Naturwissenschaft (Informatik zählt nicht) [rutsch bei NICHT-GPR-LK auf 5. Abi-Fach]
  //    (wenn kein SG/NTG-LK)
  //    (+ keine Substitution von Mathe oder Deutsch, was aber nur bei SG/NTG/INFO-LK möglich ist, also kein GPR-LK!)
  // (eine der beiden eingeschränkten Optionen findet immer Anwendung, da man nicht gleichzeitig einen GPR-LK und einen SG/NTG/INFO-LK haben kann)
  // (Substitution von Mathe/Deutsch nur bei SG/NTG/INFO-LK möglich, also nicht bei GPR-LK!)
  //
  // Für das 5. Abiturfach werden folgende Einschränkungen abgedeckt, in absteigender Priorität:
  // 1. fortgeführte Fremdsprache [danach vollständig erfüllt]
  //    (wenn Substitution von Mathe)
  // 2. fortgeführte Fremdsprache / Naturwissenschaft (Informatik zählt nicht) [danach vollständig erfüllt]
  //    (wenn kein SG/NTG-LK )
  //    (+ keine Substitution von Mathe oder Deutsch)
  //    (+ wenn kein GPR-LK, da sonst schon bei 4. Abi-Fach eingeschränkt gewählt!)
  // 3. beliebiges Fach
  //    (ist nur bei GPR/NTG/SG-LK ohne Substitution von Mathe möglich)

  static ChoiceOptions getAbi4Options(ChoiceBuilder choiceBuilder) {
    // Abiturprüfung in einer Gesellschaftswissenschaft verpflichtend, (bei GPR-LK schon erfüllt)
    if (choiceBuilder.lk?.category != SubjectCategory.gpr) {
      return ChoiceOptions(ChoiceRestriction.abiGpr, [
        Subject.reli,
        Subject.geschi,
        if (choiceBuilder.pug13 ?? false) Subject.pug
        else if (choiceBuilder.geoWr != null) choiceBuilder.geoWr!,
      ]);
    }

    // Abiturprüfung in einer fortgeführten Fremdsprache oder Naturwissenschaft verpflichtend (Informatik zählt nicht als Naturwissenschaft),
    // (bei SG/NTG-LK schon erfüllt, bei Substitution auch da eine weitere Naturwissenschaft/Fremdsprache verpflichtend ist (statt Mathe/Deutsch), also auch schon erfüllt)
    if (choiceBuilder.lk?.category != SubjectCategory.ntg && choiceBuilder.lk?.category != SubjectCategory.sg
        && !(choiceBuilder.substituteDeutsch ?? false) && !(choiceBuilder.substituteMathe ?? false)) {
      return ChoiceOptions(ChoiceRestriction.abiSgNtg, [
        if (choiceBuilder.mint1 != null)
          choiceBuilder.mint1!,
        if (choiceBuilder.sg1 != null)
          choiceBuilder.sg1!,
        if (choiceBuilder.vk == null && choiceBuilder.mintSg2 != null && (choiceBuilder.mintSg2!.category == SubjectCategory.ntg || choiceBuilder.mintSg2!.category == SubjectCategory.sg)
            && !(choiceBuilder.substituteDeutsch ?? false) && !(choiceBuilder.substituteMathe ?? false))
          choiceBuilder.mintSg2!,
      ]);
    }

    // Fallback: sollte nie erreicht werden, da nicht beide Bedingungen gleichzeitig erfüllt sein können
    return ChoiceOptions.empty();
  }

  static ChoiceOptions getAbi5Options(ChoiceBuilder choiceBuilder) {
    // Bei Substitution von Mathe ist eine fortgeführte Fremdsprache verpflichtend (bei Deutsch ist keine Naturwissenschaft verpflichtend)
    if (choiceBuilder.substituteMathe ?? false) {
      return ChoiceOptions(ChoiceRestriction.abiSgSubM, [
        if (choiceBuilder.sg1 != null)
          choiceBuilder.sg1!,
        // wird immer false sein, da um überhaupt Mathe subsituieren zu können, müssen 2 Naturwissenschaften gewählt werden (ntg1=lk, mintSg2=substitut)
        if (choiceBuilder.mintSg2 != null && choiceBuilder.mintSg2!.category == SubjectCategory.sg)
          choiceBuilder.mintSg2!,
      ]);
    }

    // Abiturprüfung in einer fortgeführten Fremdsprache oder Naturwissenschaft verpflichtend (Informatik zählt nicht als Naturwissenschaft),
    // (bei SG/NTG-LK schon erfüllt, bei GPR-LK schon bei abi4 erfüllt)
    if (choiceBuilder.lk?.category != SubjectCategory.ntg && choiceBuilder.lk?.category != SubjectCategory.sg && choiceBuilder.lk?.category != SubjectCategory.gpr
        && !(choiceBuilder.substituteDeutsch ?? false) && !(choiceBuilder.substituteMathe ?? false)) {
      return ChoiceOptions(ChoiceRestriction.abiSgNtg, [
        if (choiceBuilder.mint1 != null)
          choiceBuilder.mint1!,
        if (choiceBuilder.sg1 != null)
          choiceBuilder.sg1!,
        if (choiceBuilder.vk == null && choiceBuilder.mintSg2 != null && (choiceBuilder.mintSg2!.category == SubjectCategory.ntg || choiceBuilder.mintSg2!.category == SubjectCategory.sg)
            && !(choiceBuilder.substituteDeutsch ?? false) && !(choiceBuilder.substituteMathe ?? false))
          choiceBuilder.mintSg2!,
      ]);
    }

    // Sind die verpflichtenden Abiturprüfungsfächer bereits gewählt, kann ein weiteres beliebiges Fach gewählt werden
    // jedoch keine bereits als Abiturprüfungsfach gewählten Fächer (inkl. Substitutionen) mehr, da es insgesamt 5 verschiedene Fächer sein müssen
    return ChoiceOptions(ChoiceRestriction.abiAny, [
      if (choiceBuilder.lk != Subject.reli && choiceBuilder.abi4 != Subject.reli)
        Subject.reli,
      if (choiceBuilder.lk != Subject.geschi && choiceBuilder.abi4 != Subject.geschi)
        Subject.geschi,
      if (choiceBuilder.lk != choiceBuilder.mint1 && choiceBuilder.abi4 != choiceBuilder.mint1 && choiceBuilder.mint1 != null)
        choiceBuilder.mint1!,
      if (choiceBuilder.lk != choiceBuilder.sg1 && choiceBuilder.abi4 != choiceBuilder.sg1 && choiceBuilder.sg1 != null)
        choiceBuilder.sg1!,

      if (choiceBuilder.abi4 != choiceBuilder.mintSg2 && choiceBuilder.lk != choiceBuilder.mintSg2 && choiceBuilder.vk == null
          && !(choiceBuilder.substituteDeutsch ?? false) && !(choiceBuilder.substituteMathe ?? false) && choiceBuilder.mintSg2 != null)
        choiceBuilder.mintSg2!,
      if (choiceBuilder.lk != Subject.pug && choiceBuilder.abi4 != Subject.pug && (choiceBuilder.pug13 ?? false))
        Subject.pug,
      if (choiceBuilder.lk != choiceBuilder.geoWr && choiceBuilder.abi4 != choiceBuilder.geoWr && !(choiceBuilder.pug13 ?? false) && choiceBuilder.geoWr != null)
        choiceBuilder.geoWr!,
      if (choiceBuilder.lk != choiceBuilder.musikKunst && choiceBuilder.musikKunst != null)
        choiceBuilder.musikKunst!,
    ]);
  }
}
