
import '../oauth_flow.dart';

AuthFlow getAuthFlow() => FallbackFlow();

class FallbackFlow extends AuthFlow {

  @override
  String redirectUrl() {
    throw UnimplementedError("No suitable auth flow for this platform");
  }

  @override
  Future<String?> googleAuthFlow() async {
    throw UnimplementedError("No suitable auth flow for this platform");
  }
}
