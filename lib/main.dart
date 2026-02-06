import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'pages/welcome.dart';
import 'logic/choice.dart';
import 'logic/grades.dart';
import 'logic/types.dart';
import 'pages/home.dart';
import 'pages/settings.dart';
import 'pages/results.dart';
import 'pages/setup.dart';
import 'pages/subjects.dart';
import 'provider/grades.dart';
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

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<SettingsDataProvider>(create: (context) => SettingsDataProvider()),
    ChangeNotifierProvider<GradesDataProvider>(create: (context) => GradesDataProvider()),
  ], child: const MyApp()));

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
          brightness: Brightness.dark,
          fontFamily: 'Poppins',
          scaffoldBackgroundColor: Colors.black,
          cardColor: const Color.fromRGBO(18, 18, 20, 1.0),
          hintColor: const Color.fromRGBO(143, 143, 147, 1.0),
          dividerColor: const Color.fromRGBO(28, 28, 32, 1.0),
          primaryColor: Colors.white,
          shadowColor: const Color.fromRGBO(117, 116, 131, 1.0),
          splashColor: const Color.fromRGBO(252, 130, 130, 0.25),
          indicatorColor: const Color.fromRGBO(252, 130, 130, 1.0),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(fontWeight: bold, color: Colors.white, fontSize: 22),
            bodyMedium: TextStyle(fontWeight: bold, color: Colors.white, fontSize: 18),
            bodySmall: TextStyle(fontWeight: normal, color: Color.fromRGBO(117, 116, 131, 1.0), fontSize: 12, height: 1),
            displayMedium: TextStyle(fontWeight: normal, color: Color.fromRGBO(117, 116, 131, 1.0), fontSize: 14, height: 1),
            labelMedium: TextStyle(fontWeight: bold, color: Colors.black, fontSize: 18),
            labelSmall: TextStyle(fontWeight: normal, color: Color.fromRGBO(117, 116, 131, 1.0), fontSize: 18, letterSpacing: 0),
          )),
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        hintColor: Colors.white,
        dividerColor: const Color.fromRGBO(228, 233, 240, 1.0),
        primaryColor: Colors.black,
        shadowColor: const Color.fromRGBO(117, 116, 131, 1.0),
        splashColor: const Color.fromRGBO(252, 130, 130, 0.4),
        indicatorColor: const Color.fromRGBO(252, 130, 130, 1.0),
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
