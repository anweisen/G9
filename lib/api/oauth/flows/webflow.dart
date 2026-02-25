import 'dart:async';
import 'dart:html' as html;

import '../oauth_flow.dart';

AuthFlow getAuthFlow() => WebAuthFlow();

// see: https://github.com/TesteurManiak/flutter_web_twitch_auth
class WebAuthFlow extends AuthFlow {

  static html.WindowBase? _window;

  @override
  String redirectUrl() {
    final currentUri = Uri.base;
    return Uri(
        scheme: currentUri.scheme,
        host: currentUri.host,
        port: currentUri.port,
        path: "/callback.html"
    ).toString();
  }

  @override
  Future<String?> googleAuthFlow() {
    if (_window != null) {
      _window?.close();
      _window = null;
    }

    Completer<String?> completer = Completer<String?>();

    // Listen to message send with `postMessage`.
    html.window.onMessage.listen((event) {
      // The event contains the token which means the user is connected.
      print("Received message: ${event.data}");

      if (event.data is String) {
        final url = event.data as String;
        final uri = Uri.parse(url);
        final code = uri.queryParameters['code'];
        completer.complete(code);
        _window?.close();
        _window = null;
      }
    });

    final authUri = Uri.https("accounts.google.com", "/o/oauth2/v2/auth", {
      "client_id": AuthFlow.googleClientId,
      "response_type": 'code',
      "scope": AuthFlow.googleScopes.join(' '),
      "redirect_uri": redirectUrl().toString(),
    });

    // Calculate the center of the screen
    const double width = 500;
    const double height = 600;
    final double left = (html.window.screen!.width! - width) / 2;
    final double top = (html.window.screen!.height! - height) / 2;
    final String features =
        'width=$width,height=$height,top=$top,left=$left,'
        'status=no,menubar=no,toolbar=no,location=no,resizable=yes,scrollbars=yes';

    print("redirect Uri: ${redirectUrl()}");

    _window = html.window.open(authUri.toString(), "Google OAuth Login", features);

    return completer.future;
  }

}
