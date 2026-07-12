import 'package:flutter/material.dart';
import 'screens/auth/splash_screen.dart';
import 'utils/colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/firestore_seeder.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ONE-TIME SETUP: 
  // Set this to 'true' and run the app once to upload your CSV data to Firestore.
  // After you see "Database Seeding Completed" in the console, set this back to 'false'.
  bool shouldSeedDatabase = false;

  if (shouldSeedDatabase) {
    await FirestoreSeeder.uploadMedicinesFromCsv();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: AppColors.primary,
            useMaterial3: true,
          ),
          themeMode: currentMode,
          home: SplashScreen(),
        );
      },
    );
  }
}
