import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/session_provider.dart';
import 'providers/presence_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/admin_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'screens/auth/login_screen.dart';
import 'core/config/api_config.dart';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await ApiConfig.init();
  
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      await NotificationService().init();
      print('🔥 Firebase & Notifications Initialized');
    } catch (e) {
      print('⚠️ Initialization Failed: $e');
    }
  } else {
    print('ℹ️ Skipping Firebase on Web (not configured)');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
      path: kIsWeb ? 'translations' : 'assets/translations',
      fallbackLocale: const Locale('en'),
      useOnlyLangCode: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SessionProvider()),
          ChangeNotifierProvider(create: (_) => PresenceProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
        ],
        child: const QronoApp(),
      ),
    ),
  );
}

class QronoApp extends StatelessWidget {
  const QronoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qrono',
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryTeal,
        cardColor: AppColors.cardColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.primaryTeal),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.grayText),
          displayLarge: TextStyle(color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryTeal),
          ),
          labelStyle: const TextStyle(color: AppColors.grayText),
          hintStyle: const TextStyle(color: AppColors.grayText),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
