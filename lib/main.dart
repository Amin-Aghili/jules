import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_google/screens/splash_screen.dart';

const String supabaseUrl =
    'https://zrrypgzzfovkbebsyzih.supabase.co'; // از Dashboard
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpycnlwZ3p6Zm92a2JlYnN5emloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ4Mjc3MDMsImV4cCI6MjA3MDQwMzcwM30.9eR3O4uBrBn5CPThrjYQIbpZ2LqvaXbVnskxH1lx8Yg';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Google Sign In with Supabase Demo',
      home: SplashScreen(),
    );
  }
}
