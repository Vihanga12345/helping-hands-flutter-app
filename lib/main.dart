import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/navigation_service.dart';
import 'services/supabase_service.dart';
import 'services/localization_service.dart';
import 'services/firebase_messaging_service.dart';
import 'utils/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'pages/common/user_5_user_selection_page.dart';
import 'pages/helpee/helpee_1_auth_page.dart';
import 'pages/helpee/helpee_7_job_request_page.dart';
import 'pages/helper/helper_1_auth_page.dart';
import 'pages/helper/helper_7_home_page.dart';
import 'pages/helper/helper_8_view_requests_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (skip web for now until configuration is set up)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized successfully');

      // Initialize Firebase Messaging Service only on mobile
      await FirebaseMessagingService().initialize();
      print('✅ Firebase Messaging Service initialized');
    } catch (e) {
      print('⚠️ Firebase initialization skipped: $e');
    }
  } else {
    print('⚠️ Firebase initialization skipped on web platform');
  }

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Localization Service
  await LocalizationService().initialize();

  runApp(const HelpingHandsApp());
}

class HelpingHandsApp extends StatelessWidget {
  const HelpingHandsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalizationService()),
      ],
      child: Consumer<LocalizationService>(
        builder: (context, localization, child) {
          return MaterialApp.router(
            title: 'Helping Hands',
            debugShowCheckedModeBanner: false,

            // Dynamic locale support
            locale: Locale(localization.currentLanguage, ''),

            // Localization support
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('si', ''), // Sinhala
              Locale('ta', ''), // Tamil
            ],

            theme: ThemeData(
              primarySwatch: Colors.green,
              primaryColor: AppColors.primaryGreen,
              scaffoldBackgroundColor: AppColors.backgroundLight,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightGreen,
                  foregroundColor: AppColors.black,
                  elevation: 4,
                  shadowColor: AppColors.shadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryGreen),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
            routerConfig: NavigationService.router,
          );
        },
      ),
    );
  }
}
