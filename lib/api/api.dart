import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../logic/choice.dart';
import '../logic/grades.dart';
import '../logic/types.dart';
import '../provider/account.dart';
import '../provider/grades.dart';
import '../provider/settings.dart';
import 'oauth/oauth_flow.dart';
import 'types.dart';

class ApiRoutes {
  static const String authExchange = "/auth/exchange";
  static const String accountSync = "/account/sync";
  static const String accountChoice = "/account/choice";
  static const String deleteAccount = "/account";
  static String accountSubjectSemesterGrades(SubjectId subjectId, Semester semester) => "/account/grades/$subjectId/${semester.name}";
  static String accountSubjectAbiPrediction(SubjectId subjectId) => "/account/abi-prediction/$subjectId";
}

class Api {
  static const String apiBaseUrl = (kDebugMode && false) ? "http://localhost:5000" : "https://g9.anweisen.net/api";

  static Future<void> doGoogleLoginAndSync(BuildContext context) async {
    final accountProvider = Provider.of<AccountDataProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsDataProvider>(context, listen: false);
    final gradesProvider = Provider.of<GradesDataProvider>(context, listen: false);

    await handleGoogleAuth(accountProvider);

    accountProvider.syncStoredData(settingsProvider, gradesProvider);
  }

  static Future<void> handleGoogleAuth(AccountDataProvider provider) async {
    final flow = getAuthFlow();

    final result = await flow.googleAuthFlow();

    if (result != null) {
      print("Received Auth Code: $result");
      await exchangeWithBackend(result, flow, "google", provider);
    } else {
      print("No auth code received from Google.");
    }
  }

  static Future<void> exchangeWithBackend(String code, AuthFlow flow, String providerName, AccountDataProvider dataProvider) async {
    print("Sending Auth Code to Backend: $code");
    dataProvider.authenticating = true;

    final response = await http.post(
      Uri.parse("$apiBaseUrl${ApiRoutes.authExchange}"),
      body: json.encode({"provider": providerName, "redirect_uri": flow.redirectUrl(), "code": code}),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      print("Backend Auth Success: ${response.body}");

      Map<String, dynamic> data = jsonDecode(response.body);
      final body = AuthResponseBody.fromJson(data);

      dataProvider.accessToken = body.accessToken;
      dataProvider.userProfile = body.userProfile;
      dataProvider.privateProfile = body.privateProfile;
      dataProvider.provider = providerName;

    } else {
      print("Backend Auth Failed: ${response.statusCode} - ${response.body} (${response.request?.url.toString()})");
    }

    dataProvider.authenticating = false;
  }

}

class AuthenticatedApi {
  final String accessToken;

  AuthenticatedApi(this.accessToken);

  bool get isAuthenticated => accessToken.isNotEmpty;

  // Future<http.Response> get(String endpoint) {
  //   return http.get(Uri.parse("${Api.apiBaseUrl}$endpoint"), headers: {"Authorization": "Bearer $accessToken"});
  // }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      return await http.post(
          Uri.parse("${Api.apiBaseUrl}$endpoint"),
          headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
          body: json.encode(body)
      );
    } catch (e) {
      print("Error encoding request body: $e");
      return Future.value(http.Response(jsonEncode({"error": e.toString()}), 500));
    }
  }

  Future<http.Response> delete(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      return await http.delete(
          Uri.parse("${Api.apiBaseUrl}$endpoint"),
          headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"},
          body: json.encode(body)
      );
    } catch (e) {
      print("Error encoding request body: $e");
      return Future.value(http.Response(jsonEncode({"error": e.toString()}), 500));
    }
  }

  Future<http.Response> get(String endpoint) async {
    try {
      return await http.get(
          Uri.parse("${Api.apiBaseUrl}$endpoint"),
          headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"}
      );
    } catch (e) {
      print("Error encoding request body: $e");
      return Future.value(http.Response(jsonEncode({"error": e.toString()}), 500));
    }
  }

  Future<SyncDataPayload?> postSyncData(SyncDataPayload payload, StashedChanges? stashedChanges) async {
    print("Syncing data with backend: ${payload.toJson()}");

    final response = await post(ApiRoutes.accountSync, body: {
      "data": payload,
      "changes": stashedChanges
    });

    if (response.statusCode == 200) {
      print("Data sync successful: ${response.body}");
      Map<String, dynamic> data = jsonDecode(response.body);
      print("successfully decoded sync response: $data");
      try {
        return SyncDataPayload.fromJson(data);
      } catch (e) {
        print("Error parsing sync response: $e");
      }
    }
    return null;
  }

  Future<bool> postSubjectGrades(SubjectId subjectId, Semester semester, List<GradeEntry> grades) async {
    final response = await post(ApiRoutes.accountSubjectSemesterGrades(subjectId, semester), body: {
      "grades": grades,
    });

    return response.statusCode == 200;
  }

  Future<bool> postChoice(Choice choice) async {
    final response = await post(ApiRoutes.accountChoice, body: {
      "choice": choice,
    });

    return response.statusCode == 200;
  }

  Future<bool> postAbiPrediction(SubjectId subjectId, int? prediction) async {
    final response = await post(ApiRoutes.accountSubjectAbiPrediction(subjectId), body: {
      "prediction": prediction,
    });

    return response.statusCode == 200;
  }

  Future<bool> deleteAccount() async {
    final response = await delete(ApiRoutes.deleteAccount);

    return response.statusCode == 200;
  }

}
