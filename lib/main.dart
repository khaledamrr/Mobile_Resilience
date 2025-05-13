import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:resilience/core/navigation/app_router.dart';
import 'package:resilience/core/theme/app_theme.dart';
import 'package:resilience/features/auth/presentation/pages/login_page.dart';
import 'package:resilience/screens/splash_screen.dart';
import 'dart:io';

import 'features/products/presentation/pages/home_page.dart';
import 'features/admin/presentation/pages/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle SSL certificate verification
  HttpOverrides.global = MyHttpOverrides();

  await Supabase.initialize(
    url: 'https://eblnzpmqhynrylvbqugd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVibG56cG1xaHlucnlsdmJxdWdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0NDU1MTYsImV4cCI6MjA2MjAyMTUxNn0.ICUg-1T6Ecu9Hh3bHpBPw3YjHNF4wqXA6Z3jw-gehe8',
  );
  runApp(const MyApp());
}

// Add this class to handle SSL certificate verification
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RESILIENCE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      onGenerateRoute: AppRouter.generateRoute,
      home: const SplashScreen(),
    );
  }
}
