import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api.dart';

class AccountDataProvider extends ChangeNotifier {

  final storage = const FlutterSecureStorage();

  String? _accessToken;
  PublicUserProfile? _userProfile;

  String? get accessToken => _accessToken;
  set accessToken(String? value) {
    _accessToken = value;
    notifyListeners();
    save();
  }

  PublicUserProfile? get userProfile => _userProfile;
  set userProfile(PublicUserProfile? value) {
    _userProfile = value;
    notifyListeners();
    save();
  }

  bool get isLoggedIn => _accessToken != null && _userProfile != null;

  AccountDataProvider() {
    load();
  }

  void logout() {
    _accessToken = null;
    _userProfile = null;
    notifyListeners();
    save();
  }

  void load() async {
    accessToken = await storage.read(key: "accessToken");
  }

  void save() async {
    await storage.write(key: "accessToken", value: _accessToken);
  }
}
