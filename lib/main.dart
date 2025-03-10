import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

import 'logic/choice.dart';
import 'logic/grades.dart';
import 'logic/types.dart';
import 'pages/home.dart';
import 'pages/results.dart';
import 'pages/setup.dart';
import 'pages/subjects.dart';
import 'provider/grades.dart';
import 'provider/settings.dart';
import 'widgets/splash.dart';

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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var settings = Provider.of<SettingsDataProvider>(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Set the status bar background to white
      statusBarIconBrightness: settings.theme == ThemeMode.dark ? Brightness.light : Brightness.dark, // Set the icons to dark (for better contrast on white background)
      statusBarBrightness: settings.theme == ThemeMode.dark ? Brightness.dark : Brightness.light, // Set the icons to dark (for better contrast on white background)
    ));

    const FontWeight bold = FontWeight.w600;
    const FontWeight normal = FontWeight.w500;

    return MaterialApp(
      title: 'Flutter Demo',
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
          textTheme: const TextTheme(
            headlineMedium: TextStyle(fontWeight: bold, color: Colors.white, fontSize: 24),
            bodyMedium: TextStyle(fontWeight: bold, color: Colors.white, fontSize: 18),
            bodySmall: TextStyle(fontWeight: normal, color: Color.fromRGBO(117, 116, 131, 1.0), fontSize: 12, height: 1),
            labelMedium: TextStyle(fontWeight: bold, color: Colors.black, fontSize: 18),
          )),
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        hintColor: Colors.white,
        dividerColor: const Color.fromRGBO(223, 228, 236, 1.0),
        primaryColor: Colors.black,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: bold, color: Colors.black, fontSize: 24),
          bodyMedium: TextStyle(fontWeight: bold, color: Colors.black, fontSize: 18),
          bodySmall: TextStyle(fontWeight: normal, color: Color.fromRGBO(117, 116, 131, 1.0), fontSize: 12, height: 1),
          labelMedium: TextStyle(fontWeight: bold, color: Colors.white, fontSize: 18),
        ),
      ),

      // initialRoute: settings.onboarding
      //     ? "/setup"
      //     : "/subjects",
      // initialRoute: "/home",
      home: const SplashScreenPage(),
      routes: {
        "/home": (context) => const HomePage(),
        "/subjects": (context) => const SubjectsPage(),
        "/results": (context) => const ResultsPage(),
        "/setup": (context) => const SetupPage(),
      },
    );
  }
}
