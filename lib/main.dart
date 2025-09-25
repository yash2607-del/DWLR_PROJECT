import 'package:flutter/material.dart';

// Import the screens
import 'screens/home_screen.dart';
import 'screens/station_screen.dart';
import 'screens/chart_screen.dart';
import 'screens/about_screen.dart';
import 'screens/map_screen.dart';
import 'screens/analytics_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
          bodyMedium: TextStyle(fontSize: 16, height: 1.4),
        ),
      ),
      // ✅ set initial page
      home: const HomeScreen(),

      // ✅ routes for navigation
      routes: {
        '/map': (context) => const MapScreen(),
        '/stations': (context) => const StationsScreen(),
        '/charts': (context) => const ChartsScreen(),
        '/about': (context) => const AboutScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
      },
    );
  }
}
