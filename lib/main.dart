import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/navigation_service.dart';
import 'services/supabase_service.dart';
import 'services/localization_service.dart';
import 'services/firebase_messaging_service.dart'
    if (dart.library.html) 'services/firebase_messaging_service_web.dart';
import 'services/realtime_notification_service.dart' as MainNotificationService;
// import 'services/real_time_notification_service.dart'
//     as LegacyNotificationService;
import 'services/live_data_refresh_service.dart';
import 'services/popup_manager_service.dart';
import 'services/simple_time_tracking_service.dart';
import 'services/payment_flow_service.dart';
import 'services/webrtc_service.dart';
import 'widgets/common/realtime_app_wrapper.dart';
import 'utils/app_colors.dart';
import 'package:go_router/go_router.dart';

// Global navigator key for the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (completely skip on web)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('⚠️ Firebase initialization failed: $e');
    }
  } else {
    print('⚠️ Firebase completely skipped on web platform');
  }

  // Initialize Firebase Messaging Service (has platform-specific implementation)
  try {
    await FirebaseMessagingService().initialize();
    print('✅ Firebase Messaging Service initialized');
  } catch (e) {
    print('⚠️ Firebase Messaging Service initialization failed: $e');
  }

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Localization Service
  await LocalizationService().initialize();

  // Initialize services
  // Note: SimpleTimeTrackingService doesn't need initialization
  print('✅ Time tracking service ready');

  runApp(const HelpingHandsApp());
}

class HelpingHandsApp extends StatelessWidget {
  const HelpingHandsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set the navigator key for notifications, popups, and payment flow
    MainNotificationService.RealTimeNotificationService.setNavigatorKey(
        NavigationService.navigatorKey);
    // LegacyNotificationService.RealTimeNotificationService.setNavigatorKey(
    //     NavigationService.navigatorKey);
    PaymentFlowService.setNavigatorKey(NavigationService.navigatorKey);
    PopupManagerService.setNavigatorKey(NavigationService.navigatorKey);
    WebRTCService.setNavigatorKey(NavigationService.navigatorKey);
    NavigationService.initializeServices();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalizationService()),
      ],
      child: Consumer<LocalizationService>(
        builder: (context, localization, child) {
          return RealTimeAppWrapper(
            child: MaterialApp.router(
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
            ),
          );
        },
      ),
    );
  }
}
