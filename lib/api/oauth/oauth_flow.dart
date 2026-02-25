export 'flows/fallbackflow.dart'
  if (dart.library.html) 'flows/webflow.dart'
  if (dart.library.io) 'flows/flowselector.dart';

abstract class AuthFlow {
  static const googleClientId = "333617144961-1mg7rhkt85sdanj0jtpf2j9gomfot05p.apps.googleusercontent.com";
  static const List<String> googleScopes = ["email", "profile"];

  Future<String?> googleAuthFlow();

  String redirectUrl();
}
