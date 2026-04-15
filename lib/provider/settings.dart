import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../adapter/json_converters.dart';
import '../logic/choice.dart';
import '../logic/types.dart';

part "settings.g.dart";

class SettingsDataProvider extends ChangeNotifier {
  static const hiveBoxName = "settings";
  static const hiveSettingsKey = "data";

  SettingsDataProvider() {
    // load(); called by the slash screen
  }

  bool _loaded = false;

  get hasLoaded => _loaded;

  SettingsData? _data;

  ThemeMode get theme => _data?.theme != null ? ThemeMode.values[_data!.theme] : ThemeMode.system;
  set theme(ThemeMode value) {
    _data?.theme = value.index;
    notifyListeners();
    save();
  }

  bool? get usesSlider => _data?.usesSlider;
  set usesSlider(bool? value) {
    _data?.usesSlider = value;
    notifyListeners();
    save();
  }

  Choice? get choice => _data?.choice;
  set choice(Choice? value) {
    _data?.choice = value;
    notifyListeners();
    save();
  }

  Map<SubjectId, SubjectSettings>? get subjectSettings => _data?.subjectSettings;
  set subjectSettings(Map<SubjectId, SubjectSettings>? value) {
    _data?.subjectSettings = value;
    applySubjectSettings(value);
    notifyListeners();
    save();
  }

  bool get onboarding => _data?.choice == null;

  Future<void> load() async {
    final defaultUsesSlider = kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;
    final defaultData = SettingsData(theme: ThemeMode.system.index, usesSlider: defaultUsesSlider);

    print("Loading settings data");

    var box = await Hive.openLazyBox<SettingsData>(hiveBoxName);
    try {
      _data = await box.get(hiveSettingsKey, defaultValue: defaultData);
    } catch (e) {
      _data = defaultData;
    }

    print("Loaded settings data: ${_data?.choice}");

    if (kDebugMode && _data?.choice == null) {
      _data?.choice = Choice.dummy();
    }

    applySubjectSettings(_data?.subjectSettings);

    _loaded = true;

    notifyListeners();
  }

  Future<void> save() async {
    if (_data == null) {
      return;
    }
    var box = await Hive.openLazyBox<SettingsData>(hiveBoxName);
    await box.put(hiveSettingsKey, _data!);
  }

  void applySubjectSettings(Map<SubjectId, SubjectSettings>? settings) {
    if (settings == null) return;

    for (MapEntry<SubjectId, SubjectSettings> entry in settings.entries) {
      Subject? subject = Subject.byId[entry.key];
      if (subject != null) {
        applySubjectSetting(subject, entry.value);
      }
    }
  }

  void applySubjectSetting(Subject subject, SubjectSettings? settings) {
    if (settings == null || settings.colorValue == null) {
      if (Subject.originalColors.containsKey(subject.id) && Subject.originalColors[subject.id] != null) {
        subject.color = Subject.originalColors[subject.id]!;
      }
    } else {
      subject.color = Color(settings.colorValue!);
    }
  }

  void setSubjectSettings(SubjectId subjectId, SubjectSettings? settings) {
    applySubjectSetting(Subject.byId[subjectId]!, settings);
    _data?.subjectSettings ??= {};
    if (settings == null || settings.isEmpty) {
      _data?.subjectSettings!.remove(subjectId);
    } else {
      _data?.subjectSettings![subjectId] = settings;
    }
    notifyListeners();
    save();
  }

}

@HiveType(typeId: 0)
class SettingsData {
  @HiveField(0)
  int theme;

  @HiveField(1)
  Choice? choice;

  @HiveField(2)
  bool? usesSlider;

  @HiveField(3)
  Map<SubjectId, SubjectSettings>? subjectSettings;

  SettingsData({required this.theme, this.choice, this.usesSlider, this.subjectSettings});
}

@JsonSerializable()
@HiveType(typeId: 7)
class SubjectSettings {

  @HiveField(0) @JsonKey(name: "color")
  final int? colorValue;

  @HiveField(10) @JsonKey(name: "oral_exam") @DateOnlyConverter()
  final DateTime? oralExamDate;

  SubjectSettings({this.colorValue, this.oralExamDate});

  bool get isEmpty => colorValue == null && oralExamDate == null;

  SubjectSettings copyWithColorValue(int? colorValue) {
    return SubjectSettings(
      colorValue: colorValue,
      oralExamDate: oralExamDate,
    );
  }

  SubjectSettings copyWithOralExamDate(DateTime? oralExamDate) {
    return SubjectSettings(
      colorValue: colorValue,
      oralExamDate: oralExamDate,
    );
  }

  factory SubjectSettings.fromJson(Map<String, dynamic> json) => _$SubjectSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SubjectSettingsToJson(this);
}
