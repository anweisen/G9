import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../logic/choice.dart';

part "settings.g.dart";

class SettingsDataProvider extends ChangeNotifier {
  static const hiveBoxName = "settings";
  static const hiveSettingsKey = "data";

  SettingsDataProvider() {
    // load(); called by the slash screen
  }

  SettingsData? _data;

  ThemeMode get theme => _data?.theme != null ? ThemeMode.values[_data!.theme] : ThemeMode.system;
  set theme(value) {
    _data?.theme = value;
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

  bool get onboarding => _data?.choice == null;

  Future<void> load() async {
    final defaultData = SettingsData(theme: ThemeMode.system.index, usesSlider: kIsWeb);

    print("Loading settings data");

    var box = await Hive.openLazyBox<SettingsData>(hiveBoxName);
    try {
      _data = await box.get(hiveSettingsKey, defaultValue: defaultData)!;
    } catch (e) {
      box.clear();
      _data = defaultData;
    }

    print("Loaded settings data: ${_data?.choice}");

    notifyListeners();
  }

  Future<void> save() async {
    if (_data == null) {
      return;
    }
    var box = await Hive.openLazyBox<SettingsData>(hiveBoxName);
    await box.put(hiveSettingsKey, _data!);
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

  SettingsData({required this.theme, this.choice, this.usesSlider});
}
