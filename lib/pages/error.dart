import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
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
  }
}

