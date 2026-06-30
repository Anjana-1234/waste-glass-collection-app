import 'package:flutter/material.dart';
import 'screens/trip_sequence_screen.dart';

void main() {
  runApp(const WasteGlassApp());
}

class WasteGlassApp extends StatelessWidget {
  const WasteGlassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waste Glass Collection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const TripSequenceScreen(),
    );
  }
}