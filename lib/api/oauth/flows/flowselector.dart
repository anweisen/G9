import 'dart:io';

import '../oauth_flow.dart';
import 'desktopflow.dart';
import 'mobileflow.dart';
import 'fallbackflow.dart' show FallbackFlow;

// does not include Web (`dart:html`), which is not supported by this package,
// but includes Mobile (`dart:io` on Android/iOS) and Desktop (`dart:io` on Windows/Mac/Linux)

AuthFlow getAuthFlow() {
  if (Platform.isAndroid || Platform.isIOS) {
    return MobileAuthFlow();
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return DesktopAuthFlow();
  } else {
    return FallbackFlow();
  }
}
