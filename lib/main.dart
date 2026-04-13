import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'api/types.dart';
import 'pages/welcome.dart';
import 'logic/choice.dart';
import 'logic/grades.dart';
import 'logic/types.dart';
import 'pages/home.dart';
import 'pages/settings.dart';
import 'pages/results.dart';
import 'pages/setup.dart';
import 'pages/subjects.dart';
import 'provider/account.dart';
import 'provider/grades.dart';
import 'provider/kmapi.dart';
import 'provider/settings.dart';
import 'widgets/splash.dart';
import 'widgets/skeleton.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(SettingsDataAdapter());
  Hive.registerAdapter(ChoiceAdapter());
  Hive.registerAdapter(SubjectAdapter());
  Hive.registerAdapter(SubjectCategoryAdapter());
  Hive.registerAdapter(GradeEntryAdapter());
  Hive.registerAdapter(GradeTypeAdapter());
  Hive.registerAdapter(PublicUserProfileAdapter());
  Hive.registerAdapter(PrivateUserProfileAdapter());
  Hive.registerAdapter(StashedChangesAdapter());
  Hive.registerAdapter(StashedGradesChangeAdapter());
  Hive.registerAdapter(StashedChoiceChangeAdapter());
  Hive.registerAdapter(StashedSemesterChangeAdapter());
  Hive.registerAdapter(StashedSubjectSettingsChangeAdapter());
  Hive.registerAdapter(SemesterAdapter());
  Hive.registerAdapter(SubjectSettingsAdapter());

  // safe to call on desktop/mobile
  usePathUrlStrategy();

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<SettingsDataProvider>(create: (context) => SettingsDataProvider()),
    ChangeNotifierProvider<GradesDataProvider>(create: (context) => GradesDataProvider()),
    ChangeNotifierProvider<AccountDataProvider>(create: (context) => AccountDataProvider()),
    ChangeNotifierProvider<KmApiProvider>(create: (context) => KmApiProvider()),

    ProxyProvider3<SettingsDataProvider, GradesDataProvider, AccountDataProvider, Null>( // background sync on startup
      lazy: false,
      update: (context, settings, grades, account, previous) {
        print("! proxy update !");
        if (account.hasLoaded && account.accessToken != null && !account.hasRefreshScheduled) {
          account.scheduleTokenRefresh();
        } else if (!account.hasSynced && !account.isSyncing && !account.hasSyncingFailed && !account.isAuthenticating && account.hasLoaded && grades.hasLoaded && settings.hasLoaded && account.isLoggedIn && account.hasRefreshScheduled) {
          account.syncStoredData(settings, grades);
        }
      }
    ),
  ], child: const MyApp()));
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const Text("Es kam zu einem unerwarteten Fehler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const Text("Unterstütze uns gerne bei der Verbesserung der App mit einem Bugreport", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 20,),
              const Text("Weitere Informationen für Entwickler:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.blueGrey,), textAlign: TextAlign.center,),
              const SizedBox(height: 2,),
              Text(details.exceptionAsString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blueGrey,), textAlign: TextAlign.center,),
            ],
          ),
        ),
      ),
    );
  };

  if (WindowTitleBar.isWindows) {
    doWhenWindowReady(() {
      appWindow.title = "G9 Notenapp";
      appWindow.show();
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var settings = Provider.of<SettingsDataProvider>(context);

    const FontWeight bold = FontWeight.w600;
    const FontWeight normal = FontWeight.w500;

    return MaterialApp(
      title: 'G9 Notenapp',
      debugShowCheckedModeBanner: false,
      themeMode: settings.theme,
      // themeMode: ThemeMode.light,
      color: Colors.white, // TODO?!
      darkTheme: ThemeData(
          useMaterial3: false,
          brightness: Brightness.dark,
          fontFamily: 'Poppins',
          scaffoldBackgroundColor: Colors.black,
          cardColor: const Color.fromRGBO(18, 18, 20, 1.0),
          hintColor: const Color.fromRGBO(143, 143, 147, 1.0),
          dividerColor: const Color.fromRGBO(28, 28, 32, 1.0),
          primaryColor: Colors.white,
          shadowColor: const Color.fromRGBO(117, 116, 131, 1.0),
          splashColor: const Color.fromRGBO(252, 130, 130, 0.25),
          disabledColor: const Color.fromRGBO(252, 130, 130, 1.0),
          indicatorColor: const Color.fromRGBO(107, 211, 99, 1.0),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(fontWeight: bold, color: Colors.white, fontSize: 22),
            bodyMedium: TextStyle(fontWeight: bold, color: Colors.white, fontSize: 18),
            bodySmall: TextStyle(fontWeight: normal, color: Color.fromRGBO(117, 116, 131, 1.0), fontSize: 12, height: 1),
            displayMedium: TextStyle(fontWeight: normal, color: Color.fromRGBO(117, 116, 131, 1.0), fontSize: 14, height: 1),
            labelMedium: TextStyle(fontWeight: bold, color: Colors.black, fontSize: 18),
            labelSmall: TextStyle(fontWeight: normal, color: Color.fromRGBO(117, 116, 131, 1.0), fontSize: 18, letterSpacing: 0),
          )),
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        hintColor: Colors.white,
        dividerColor: const Color.fromRGBO(228, 233, 240, 1.0),
        primaryColor: Colors.black,
        shadowColor: const Color.fromRGBO(117, 116, 131, 1.0),
        splashColor: const Color.fromRGBO(252, 130, 130, 0.4),
        disabledColor: const Color.fromRGBO(252, 130, 130, 1.0),
        indicatorColor: const Color.fromRGBO(107, 211, 99, 1.0),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: bold, color: Colors.black, fontSize: 24),
          bodyMedium: TextStyle(fontWeight: bold, color: Colors.black, fontSize: 18),
          bodySmall: TextStyle(fontWeight: normal, color: Color.fromRGBO(117, 116, 131, 1.0), fontSize: 12, height: 1),
          displayMedium: TextStyle(fontWeight: normal, color: Color.fromRGBO(117, 116, 131, 1.0), fontSize: 14, height: 1),
          labelMedium: TextStyle(fontWeight: bold, color: Colors.white, fontSize: 18),
          labelSmall: TextStyle(fontWeight: normal, color: Color.fromRGBO(117, 116, 131, 1.0), fontSize: 18, letterSpacing: 0),
        ),
      ),

      home: const SplashScreenPage(),
      routes: {
        "/welcome": (context) => const WelcomePage(key: Key("welcome")),
        "/home": (context) => const HomePage(key: Key("home")),
        "/subjects": (context) => const SubjectsPage(key: Key("subjects")),
        "/results": (context) => const ResultsPage(key: Key("results")),
        "/setup": (context) => const SetupPage(key: Key("setup")),
        "/setup/abi": (context) => const SetupPage(key: Key("setup/abi"), onlyAbi: true),
        "/settings": (context) => const SettingsPage(key: Key("settings")),
      },
    );
  }
}
