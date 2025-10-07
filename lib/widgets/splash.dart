import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../provider/settings.dart";

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {

  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = decideRouteFuture(context);
  }

  Future<String> decideRouteFuture(context) async {
    var notifier = Provider.of<SettingsDataProvider>(context, listen: false);
    await notifier.load(); // wait until data is loaded
    if (notifier.onboarding) {
      return "/welcome";
    } else {
      return "/home";
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building splash screen");
    return FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, snapshot.data as String);
            });
          }
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        });
  }
}
