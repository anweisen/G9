import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../adapter/json_converters.dart';
import '../logic/choice.dart';
import '../logic/grades.dart';
import '../logic/types.dart';
import '../provider/grades.dart';

part 'types.g.dart';

@JsonSerializable()
@HiveType(typeId: 30)
class PublicUserProfile {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String picture;

  PublicUserProfile({required this.id, required this.name, required this.picture});

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) => _$PublicUserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$PublicUserProfileToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 31)
class PrivateUserProfile {
  @HiveField(0)
  String email;

  @HiveField(1) @JsonKey(name: "created_at") @GoDateTimeConverter()
  DateTime createdAt;

  PrivateUserProfile({required this.email, required this.createdAt});

  factory PrivateUserProfile.fromJson(Map<String, dynamic> json) => _$PrivateUserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$PrivateUserProfileToJson(this);
}

@JsonSerializable()
class AuthResponseBody {
  @JsonKey(name: "access_token")
  String accessToken;

  @JsonKey(name: "refresh_token")
  String refreshToken;

  @JsonKey(name: "user_profile")
  PublicUserProfile userProfile;

  @JsonKey(name: "private_profile")
  PrivateUserProfile privateProfile;

  AuthResponseBody({required this.accessToken, required this.refreshToken, required this.userProfile, required this.privateProfile});

  factory AuthResponseBody.fromJson(Map<String, dynamic> json) => _$AuthResponseBodyFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseBodyToJson(this);
}

@JsonSerializable()
class RefreshResponseBody {
  @JsonKey(name: "access_token")
  String accessToken;

  @JsonKey(name: "refresh_token")
  String refreshToken;

  RefreshResponseBody({required this.accessToken, required this.refreshToken});

  factory RefreshResponseBody.fromJson(Map<String, dynamic> json) => _$RefreshResponseBodyFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshResponseBodyToJson(this);
}

@JsonSerializable()
class AccountSession {
}

@JsonSerializable()
class SyncDataPayload {
  @JsonKey(name: "choice")
  Choice? choice;

  @JsonKey(name: "semester")
  Semester? currentSemester;

  @JsonKey(name: "uses_slider")
  bool? usesSlider;

  // @JsonKey(name: "theme")
  // int? theme;

  @JsonKey(name: "abi_predictions")
  Map<SubjectId, int>? abiPredictions;

  @JsonKey(name: "grades")
  Map<Semester, SubjectGradesMap>? grades;

  SyncDataPayload({this.choice, this.currentSemester, this.usesSlider, this.abiPredictions, this.grades});

  factory SyncDataPayload.fromJson(Map<String, dynamic> json) => _$SyncDataPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$SyncDataPayloadToJson(this);
}
