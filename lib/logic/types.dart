import 'package:hive/hive.dart';

import 'dart:ui';


part 'types.g.dart';

@HiveType(typeId: 10)
class Subject {
  @HiveField(0)
  final SubjectId id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final Color color;

  @HiveField(3)
  final SubjectCategory category;

  Subject({required this.id, required this.name, required this.color, required this.category}) {
    byId[id] = this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Subject && id == other.id;

  @override
  int get hashCode => id;

  @override
  String toString() => "$name($id, ${category.name})";

  static Subject
    mathe = Subject(id: 1, name: 'Mathe', color: const Color.fromRGBO(11, 107, 234, 1), category: SubjectCategory.abi),
    deutsch = Subject(id: 2, name: 'Deutsch', color: const Color.fromRGBO(248, 248, 31, 1.0), category: SubjectCategory.abi),

    matheVk = Subject(id: 11, name: 'Mathe Vertiefung', color: const Color.fromRGBO(11, 107, 234, 1), category: SubjectCategory.vk),
    deutschVk = Subject(id: 12, name: 'Deutsch Vertiefung', color: const Color.fromRGBO(248, 248, 31, 1.0), category: SubjectCategory.vk),

    english = Subject(id: 21, name: 'Englisch', color: const Color.fromRGBO(228, 27, 27, 1.0), category: SubjectCategory.sg),
    franz = Subject(id: 22, name: 'Französisch', color: const Color.fromRGBO(224, 146, 46, 1.0), category: SubjectCategory.sg),
    spanisch = Subject(id: 23, name: 'Spanisch', color: const Color.fromRGBO(224, 146, 46, 1.0), category: SubjectCategory.sg),
    latein = Subject(id: 24, name: 'Latein', color: const Color.fromRGBO(224, 146, 46, 1.0), category: SubjectCategory.sg),

    spanischSb = Subject(id: 31, name: 'Spanisch spätb.', color: const Color.fromRGBO(224, 146, 46, 1.0), category: SubjectCategory.sbs),

    physik = Subject(id: 41, name: 'Physik', color: const Color.fromRGBO(112, 111, 104, 1.0), category: SubjectCategory.ntg),
    chemie = Subject(id: 42, name: 'Chemie', color: const Color.fromRGBO(153, 32, 192, 1.0), category: SubjectCategory.ntg),
    bio = Subject(id: 43, name: 'Biologie', color: const Color.fromRGBO(15, 143, 18, 1.0), category: SubjectCategory.ntg),
    info = Subject(id: 44, name: 'Informatik', color: const Color.fromRGBO(126, 180, 19, 1.0), category: SubjectCategory.info),

    reli = Subject(id: 51, name: 'Religion', color: const Color.fromRGBO(102, 14, 147, 1.0), category: SubjectCategory.gpr),
    geschi = Subject(id: 52, name: 'Geschichte', color: const Color.fromRGBO(43, 42, 44, 1.0), category: SubjectCategory.gpr),
    geo = Subject(id: 53, name: 'Geographie', color: const Color.fromRGBO(21, 169, 134, 1.0), category: SubjectCategory.gpr),
    wr = Subject(id: 54, name: 'Wirtschaft & Recht', color: const Color.fromRGBO(186, 128, 250, 1.0), category: SubjectCategory.gpr),
    pug = Subject(id: 55, name: 'Politik & Gesellschaft', color: const Color.fromRGBO(128, 181, 250, 1.0), category: SubjectCategory.gpr),

    kunst = Subject(id: 61, name: 'Kunst', color: const Color.fromRGBO(185, 149, 117, 1.0), category: SubjectCategory.kumu),
    musik = Subject(id: 62, name: 'Musik', color: const Color.fromRGBO(243, 167, 105, 1.0), category: SubjectCategory.kumu),

    sport = Subject(id: 81, name: "Sport", color: const Color.fromRGBO(128, 255, 100, 1.0), category: SubjectCategory.sport),

    seminar = Subject(id: 91, name: "W-Seminar", color: const Color.fromRGBO(231, 236, 239, 1.0), category: SubjectCategory.seminar),

    wahl = Subject(id: 100, name: "Wahlfach", color: const Color.fromRGBO(0, 233, 255, 1.0), category: SubjectCategory.profil)
  ;

  static final Map<SubjectId, Subject> byId = {};
  static final List<Subject> all = [ // ensure initialization
    mathe, deutsch, matheVk, deutschVk, english, franz, spanisch, latein, spanischSb, physik, chemie, bio, info, reli, geschi, geo, wr, pug, kunst, musik, sport, seminar, wahl
  ];
  static List<Subject> lks = [english, bio, physik, chemie, info, reli, geschi, geo, wr, pug, kunst, musik, sport, franz, spanisch, latein]; // custom order

  static List<Subject> allOf(SubjectCategory c1, [SubjectCategory? c2, SubjectCategory? c3, SubjectCategory? c4, SubjectCategory? c5]) {
    return all.where((element) => element.category == c1 || element.category == c2 || element.category == c3 || element.category == c4 || element.category == c5).toList();
  }

}

typedef SubjectId = int;

@HiveType(typeId: 11)
enum SubjectCategory {

  /// Verpflichtende Abiturfächer
  @HiveField(0)
  abi,

  /// Naturwissenschaften
  @HiveField(1)
  ntg,

  /// Informatik
  @HiveField(2)
  info,

  /// Fremdsprachen
  @HiveField(3)
  sg,

  /// spät beginnende Fremdsprachen als 2. Fremdsprache (direkt gesetzt)
  @HiveField(4)
  sbs,

  /// Gesellschaftswissenschaften, Religion, Philosophie
  @HiveField(5)
  gpr,

  /// Vertiefungskurse
  @HiveField(6)
  vk,

  /// Kunst und Musik als Pflichtwahl
  @HiveField(7)
  kumu,

  /// Sport als Pflichtfach
  @HiveField(8)
  sport,

  /// Wissenschaftspropädeutisches Seminar
  @HiveField(9)
  seminar,

  /// Profilfächer (Wahlfächer)
  @HiveField(10)
  profil,

  /// Sonstiges
  @HiveField(11)
  none
}
