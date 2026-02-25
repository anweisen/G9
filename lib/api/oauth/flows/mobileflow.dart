
import 'package:google_sign_in/google_sign_in.dart';

import '../oauth_flow.dart';

// included in flowselector.dart !

class MobileAuthFlow extends AuthFlow {

  @override
  String redirectUrl() {
    throw UnimplementedError();
  }

  @override
  Future<String?> googleAuthFlow() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: AuthFlow.googleClientId,
      scopes: AuthFlow.googleScopes,
    );

    // 1. Silent sign-in first
    var user = await googleSignIn.signInSilently();
    // 2. Interactive sign-in if needed
    user ??= await googleSignIn.signIn();

    // if (user != null) {
    //   // 3. Request the actual server auth code
    //   return await web.requestServerAuthCode(
    //     clientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
    //   );
    // }
    return user?.serverAuthCode;
  }

}
