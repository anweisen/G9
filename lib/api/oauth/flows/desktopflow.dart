import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../oauth_flow.dart';

// included in flowselector.dart !

class DesktopAuthFlow extends AuthFlow {

  @override
  String redirectUrl() {
    return "http://localhost:8283";
  }

  @override
  Future<String?> googleAuthFlow() async {
    // starts a local server to catch the redirect code
    final redirectUri = redirectUrl(); // must match valid redirect_uri in Google Console
    final url = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': AuthFlow.googleClientId,
      'response_type': 'code',
      'scope': AuthFlow.googleScopes.join(' '),
      'redirect_uri': redirectUri,
    });

    try {
      // opens the actual system browser (Chrome/Edge/Safari)
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: (kIsWeb || Platform.isAndroid || Platform.isIOS) ? "http" : redirectUri, // Catch the localhost redirect
      );

      print("Received Callback URL: $result");

      // the result is the full redirect url: http://localhost:8080?code=4/0Af...
      return Uri.parse(result).queryParameters['code'];
    } catch (e) {
      print("User cancelled or error: $e");
      rethrow;
    }
  }
}
