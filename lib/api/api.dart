import 'dart:convert';

import 'package:abi_app/provider/account.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

import 'oauth/oauth_flow.dart';

class Api {
  static const String apiBaseUrl = (kDebugMode && false) ? "http://localhost:5000" : "https://g9-beta.anweisen.net/api";

  static void handleGoogleAuth(AccountDataProvider provider) async {
    final flow = getAuthFlow();

    final result = await flow.googleAuthFlow();

    if (result != null) {
      print("Received Auth Code: $result");
      await exchangeWithBackend(result, flow, provider);
    } else {
      print("No auth code received from Google.");
    }
  }

  static Future<void> exchangeWithBackend(String code, AuthFlow flow, AccountDataProvider provider) async {
    print("Sending Auth Code to Backend: $code");

    http.post(
      Uri.parse("$apiBaseUrl/auth/exchange"),
      body: json.encode({"provider": "google", "redirect_uri": flow.redirectUrl(), "code": code}),
      headers: {"Content-Type": "application/json"},
    ).then((response) {
      if (response.statusCode == 200) {
        print("Backend Auth Success: ${response.body}");

        Map<String, dynamic> data = jsonDecode(response.body);
        String token = data['access_token'];
        Map<String, dynamic> userData = data['user_profile'];
        PublicUserProfile profile = PublicUserProfile.fromJson(userData);
        print("User Profile: ${profile.name} (${profile.id})");

        provider.accessToken = token;
        provider.userProfile = profile;

      } else {
        print("Backend Auth Failed: ${response.statusCode} - ${response.body} (${response.request?.url.toString()})");
      }
    }).catchError((error) {
      print("Error sending auth code to backend: $error");
    });
  }

}

@JsonSerializable()
class PublicUserProfile {
  final String id;
  final String name;
  final String picture;

  PublicUserProfile({required this.id, required this.name, required this.picture});

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) => PublicUserProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    picture: json['picture'] as String,
  );
}
