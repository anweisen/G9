import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../adapter/json_converters.dart';
import '../api/api.dart';
import '../api/types.dart';
import '../logic/choice.dart';
import '../logic/grades.dart';
import '../logic/types.dart';
import '../pages/grade.dart';
import 'grades.dart';
import 'settings.dart';

part 'account.g.dart';

class AccountDataProvider extends ChangeNotifier {
  static const hiveBoxName = "account";
  static const hiveProfileKey = "profile";
  static const hivePrivateProfileKey = "private_profile";
  static const hiveStashedChangesKey = "stashed_changes";
  static const hiveProviderKey = "provider";

  final storage = const FlutterSecureStorage();

  bool _loaded = false;
  bool get hasLoaded => _loaded;

  bool _syncingFailed = false;
  bool _synced = false;
  bool _syncing = false;
  bool get isSyncing => _syncing;
  bool get hasSynced => _synced;
  bool get hasSyncingFailed => _syncingFailed;

  bool _authenticating = false;
  bool get isAuthenticating => _authenticating;
  set authenticating(bool value) {
    _authenticating = value;
  }

  late AuthenticatedApi _api;
  Timer? _refreshTimer;

  String? _accessToken;
  String? _refreshToken;
  String? _provider;
  PublicUserProfile? _userProfile;
  PrivateUserProfile? _privateProfile;
  StashedChanges? _stashedChanges;

  bool get hasRefreshScheduled => _refreshTimer != null && _refreshTimer!.isActive;

  String? get accessToken => _accessToken;
  set accessToken(String? value) {
    _accessToken = value;
    _api = AuthenticatedApi(_accessToken ?? "");
    scheduleTokenRefresh();
    notifyListeners();
    save();
  }

  String? get refreshToken => _refreshToken;
  set refreshToken(String? value) {
    _refreshToken = value;
    notifyListeners();
    save();
  }

  AuthenticatedApi get api => _api;

  PublicUserProfile? get userProfile => _userProfile;
  set userProfile(PublicUserProfile? value) {
    _userProfile = value;
    notifyListeners();
    save();
  }

  PrivateUserProfile? get privateProfile => _privateProfile;
  set privateProfile(PrivateUserProfile? value) {
    _privateProfile = value;
    notifyListeners();
    save();
  }

  String? get provider => _provider;
  set provider(String? value) {
    _provider = value;
    notifyListeners();
    save();
  }

  bool get isLoggedIn => _accessToken != null && _userProfile != null && _privateProfile != null;

  AccountDataProvider() {
    load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void logout() {
    Api.postLogout(this);
    _accessToken = null;
    _refreshToken = null;
    _userProfile = null;
    _privateProfile = null;
    _refreshTimer?.cancel();
    notifyListeners();
    save();
  }

  void load() async {
    _accessToken = await storage.read(key: "accessToken");
    _refreshToken = await storage.read(key: "refreshToken");
    _api = AuthenticatedApi(_accessToken ?? "");

    var box = await Hive.openBox(hiveBoxName);
    _userProfile = box.get(hiveProfileKey);
    _privateProfile = box.get(hivePrivateProfileKey);

    _stashedChanges = box.get(hiveStashedChangesKey);

    _provider = box.get(hiveProviderKey);

    _loaded = true;
    notifyListeners();
  }

  void save() async {
    await storage.write(key: "accessToken", value: _accessToken);
    await storage.write(key: "refreshToken", value: _refreshToken);

    var box = await Hive.openBox(hiveBoxName);
    await box.put(hiveProfileKey, _userProfile);
    await box.put(hivePrivateProfileKey, _privateProfile);

    await box.put(hiveProviderKey, _provider);

    await box.put(hiveStashedChangesKey, _stashedChanges);
  }

  void saveStash() async {
    print("Saving stashed changes: $_stashedChanges");
    var box = await Hive.openBox(hiveBoxName);
    box.put(hiveStashedChangesKey, _stashedChanges);
  }

  void deleteAccount() async {
    if (!isLoggedIn) {
      return;
    }

    final success = await api.postDeleteAccount();
    if (success) {
      logout();
    }
  }

  void refreshTokens() async {
    if (!isLoggedIn || isAuthenticating) {
      return;
    }

    await Api.refreshAccessTokenWithBackend(this);
    notifyListeners();
  }

  void scheduleTokenRefresh() {
    if (!isLoggedIn) {
      return;
    }

    try {
      final expirationDate = JwtDecoder.getExpirationDate(_accessToken!);
      final timeUntilExpiration = expirationDate.difference(DateTime.now());
      if (timeUntilExpiration.isNegative) {
        print("Access token is already expired. Refreshing now.");
        refreshTokens();
        return;
      }
      final refreshTime = timeUntilExpiration - const Duration(minutes: 1);

      _refreshTimer?.cancel();
      _refreshTimer = Timer(refreshTime, () {
        refreshTokens();
      });
    } catch (e) {
      print("Error scheduling token refresh: $e");
    }
  }

  void syncStoredData(SettingsDataProvider settingsProvider, GradesDataProvider gradesProvider, {notifyInstantly = false}) async {
    _syncing = true;
    if (notifyInstantly) notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final dataPayload = SyncDataPayload(
      choice: settingsProvider.choice,
      currentSemester: gradesProvider.currentSemester,
      usesSlider: settingsProvider.usesSlider,
      // theme: settingsProvider.theme.index,
      abiPredictions: gradesProvider.abiPredictions,
      grades: gradesProvider.data,
      subjectSettings: settingsProvider.subjectSettings,
    );

    print("Syncing data with backend. Payload: ${dataPayload.toJson()}");
    print("Stashed changes being sent to backend: ${_stashedChanges?.toJson()}");
    final responsePayload = await api.postSyncData(dataPayload, _stashedChanges);

    if (responsePayload == null) {
      _syncing = false;
      _syncingFailed = true;
      notifyListeners();
      return;
    }

    if (responsePayload.choice != null) {
      settingsProvider.choice = responsePayload.choice!;
    }
    if (responsePayload.currentSemester != null) {
      gradesProvider.currentSemester = responsePayload.currentSemester!;
    }
    if (responsePayload.usesSlider != null) {
      settingsProvider.usesSlider = responsePayload.usesSlider!;
    }
    // if (responsePayload.theme != null) {
    //   print("Updating theme from sync data: ${responsePayload.theme}");
    //   settingsProvider.theme = ThemeMode.values[responsePayload.theme!];
    // }
    if (responsePayload.abiPredictions != null) {
      gradesProvider.abiPredictions = responsePayload.abiPredictions!;
    }
    if (responsePayload.grades != null) {
      gradesProvider.data = responsePayload.grades!;
    }
    if (responsePayload.subjectSettings != null) {
      settingsProvider.subjectSettings = responsePayload.subjectSettings!;
    }

    gradesProvider.save();
    gradesProvider.notifyListeners();
    settingsProvider.save();
    settingsProvider.notifyListeners();

    _stashedChanges = null;
    saveStash();

    _syncing = false;
    _synced = true;
    notifyListeners();
  }

  void updateSubjectGradesFromResult(GradeEditResult result, GradesDataProvider gradesProvider) {
    updateSubjectGrades(result.subject.id, result.semester, gradesProvider);
  }

  void updateSubjectGrades(SubjectId subjectId, Semester semester, GradesDataProvider gradesProvider) async {
    final grades = gradesProvider.getGrades(subjectId, semester: semester);

    if (!isLoggedIn) {
      stashSubjectGrades(subjectId, semester, grades);
      return;
    }

    final success = await api.postSubjectGrades(subjectId, semester, grades);
    if (!success) {
      stashSubjectGrades(subjectId, semester, grades);
    }
  }

  void updateChoice(Choice choice) async {
    if (!isLoggedIn) {
      stashChoice(choice);
      return;
    }

    final success = await api.postChoice(choice);
    if (!success) {
      stashChoice(choice);
    }
  }

  void updateAbiPrediction(SubjectId subjectId, int? points) async {
    if (!isLoggedIn) {
      stashAbiPrediction(subjectId, points);
      return;
    }

    final success = await api.postAbiPrediction(subjectId, points);
    if (!success) {
      stashAbiPrediction(subjectId, points);
    }
  }

  void updateSemester(Semester semester) async {
    if (!isLoggedIn) {
      stashSemester(semester);
      return;
    }

    final success = await api.postSemester(semester);
    if (!success) {
      stashSemester(semester);
    }
  }

  void updateSubjectSettings(SubjectId subjectId, SubjectSettings settings) async {
    final nullableSettings = settings.isEmpty ? null : settings;
    print("Updating subject settings for subject $subjectId. Settings: ${settings.toJson()}");
    if (!isLoggedIn) {
      print("not logged in, stashing subject settings");
      stashSubjectSettings(subjectId, nullableSettings);
      return;
    }

    final success = await api.postSubjectSettings(subjectId, nullableSettings);
    print("Subject settings update successful: $success");
    if (!success) {
      stashSubjectSettings(subjectId, nullableSettings);
    }
  }

  void stashSemester(Semester semester) {
    _stashedChanges ??= StashedChanges.empty();
    _stashedChanges!.stashedSemester = StashedSemesterChange.now(semester);
    saveStash();
  }

  void stashSubjectGrades(SubjectId subjectId, Semester semester, GradesList grades) {
    _stashedChanges ??= StashedChanges.empty();
    _stashedChanges!.stashedGrades ??= {};
    _stashedChanges!.stashedGrades![semester] ??= {};
    _stashedChanges!.stashedGrades![semester]![subjectId] = StashedGradesChange.now(grades);
    saveStash();
  }

  void stashChoice(Choice choice) {
    _stashedChanges ??= StashedChanges.empty();
    _stashedChanges!.stashedChoice = StashedChoiceChange.now(choice);
    saveStash();
  }

  void stashAbiPrediction(SubjectId subjectId, int? points) {
    _stashedChanges ??= StashedChanges.empty();
    _stashedChanges!.stashedAbiPredictions ??= {};
    _stashedChanges!.stashedAbiPredictions![subjectId] = StashedAbiPredictionsChange.now(points);
    saveStash();
  }

  void stashSubjectSettings(SubjectId subjectId, SubjectSettings? settings) {
    _stashedChanges ??= StashedChanges.empty();
    _stashedChanges!.stashedSubjectSettings ??= {};
    _stashedChanges!.stashedSubjectSettings![subjectId] = StashedSubjectSettingsChange.now(settings);
    saveStash();
  }

}

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: 40)
class StashedChanges {

  @HiveField(0) @JsonKey(name: "grades")
  Map<Semester, Map<SubjectId, StashedGradesChange>>? stashedGrades;

  @HiveField(1) @JsonKey(name: "choice")
  StashedChoiceChange? stashedChoice;

  @HiveField(2) @JsonKey(name: "abi_predictions")
  Map<SubjectId, StashedAbiPredictionsChange>? stashedAbiPredictions;

  @HiveField(3) @JsonKey(name: "semester")
  StashedSemesterChange? stashedSemester;

  @HiveField(4) @JsonKey(name: "subject_settings")
  Map<SubjectId, StashedSubjectSettingsChange>? stashedSubjectSettings;

  StashedChanges(this.stashedGrades, this.stashedChoice, this.stashedAbiPredictions);

  StashedChanges.empty();

  factory StashedChanges.fromJson(Map<String, dynamic> json) => _$StashedChangesFromJson(json);
  Map<String, dynamic> toJson() => _$StashedChangesToJson(this);
}

class StashedValueChange<T> {

  @HiveField(0) @JsonKey(name: "at") @GoDateTimeConverter()
  final DateTime at;

  @HiveField(1) @JsonKey(name: "to")
  final T to;

  StashedValueChange(this.at, this.to);

  StashedValueChange.now(this.to) : at = DateTime.now();
}

@HiveType(typeId: 41)
@JsonSerializable(explicitToJson: true)
class StashedGradesChange extends StashedValueChange<GradesList> {
  StashedGradesChange(super.at, super.to);
  StashedGradesChange.now(super.to) : super.now();

  factory StashedGradesChange.fromJson(Map<String, dynamic> json) => _$StashedGradesChangeFromJson(json);
  Map<String, dynamic> toJson() => _$StashedGradesChangeToJson(this);
}

@HiveType(typeId: 42)
@JsonSerializable(explicitToJson: true)
class StashedChoiceChange extends StashedValueChange<Choice> {
  StashedChoiceChange(super.at, super.to);
  StashedChoiceChange.now(super.to) : super.now();

  factory StashedChoiceChange.fromJson(Map<String, dynamic> json) => _$StashedChoiceChangeFromJson(json);
  Map<String, dynamic> toJson() => _$StashedChoiceChangeToJson(this);
}

@HiveType(typeId: 43)
@JsonSerializable()
class StashedAbiPredictionsChange extends StashedValueChange<int?> {
  StashedAbiPredictionsChange(super.at, super.to);
  StashedAbiPredictionsChange.now(super.to) : super.now();

  factory StashedAbiPredictionsChange.fromJson(Map<String, dynamic> json) => _$StashedAbiPredictionsChangeFromJson(json);
  Map<String, dynamic> toJson() => _$StashedAbiPredictionsChangeToJson(this);
}

@HiveType(typeId: 44)
@JsonSerializable()
class StashedSemesterChange extends StashedValueChange<Semester> {
  StashedSemesterChange(super.at, super.to);
  StashedSemesterChange.now(super.to) : super.now();

  factory StashedSemesterChange.fromJson(Map<String, dynamic> json) => _$StashedSemesterChangeFromJson(json);
  Map<String, dynamic> toJson() => _$StashedSemesterChangeToJson(this);
}

@HiveType(typeId: 45)
@JsonSerializable()
class StashedSubjectSettingsChange extends StashedValueChange<SubjectSettings?> {
  StashedSubjectSettingsChange(super.at, super.to);
  StashedSubjectSettingsChange.now(super.to) : super.now();

  factory StashedSubjectSettingsChange.fromJson(Map<String, dynamic> json) => _$StashedSubjectSettingsChangeFromJson(json);
  Map<String, dynamic> toJson() => _$StashedSubjectSettingsChangeToJson(this);
}
