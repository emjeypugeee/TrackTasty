import 'dart:io';
import 'package:fitness/pages/login/startup_logo_page.dart';
import 'package:fitness/provider/registration_data_provider.dart';
import 'package:fitness/pages/main_pages/camera_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness/provider/user_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fitness/firebase_options.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

// WIDGETS & ANIMATIONS
import 'package:fitness/widgets/main_screen_widgets/main_screen.dart';
import 'package:fitness/animations/fade_out_page_transition.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// SIDEBAR PAGES
import 'package:fitness/pages/sidebar_pages/recalculate_macros_page.dart';
import 'package:fitness/pages/sidebar_pages/notification_settings.dart';
import 'package:fitness/pages/sidebar_pages/edit_food_preference.dart';
import 'package:fitness/pages/sidebar_pages/send_feedback_page.dart';

// LOGIN PAGES
import 'package:fitness/pages/login/forgetpassword_page.dart';
import 'package:fitness/pages/login/register_page.dart';
import 'package:fitness/pages/login/startup_page.dart';
import 'package:fitness/pages/login/login_page.dart';

// MAIN PAGES
import 'package:fitness/pages/main_pages/analytics_page.dart';
import 'package:fitness/pages/main_pages/profile_page.dart';
import 'package:fitness/pages/main_pages/admin_page.dart';
import 'package:fitness/pages/main_pages/home_page.dart';
import 'package:fitness/pages/main_pages/food_page.dart';
import 'package:fitness/pages/main_pages/chat_bot.dart';

// FOOD PREFERENCE PAGES
import 'package:fitness/pages/preference/userpreference_2.dart';
import 'package:fitness/pages/preference/userpreference_1.dart';
import 'package:fitness/pages/preference/userpreference_3.dart';
import 'package:fitness/pages/preference/userpreference_4.dart';
import 'package:fitness/pages/preference/userpreference_5.dart';
import 'package:fitness/pages/preference/userpreference_6.dart';
import 'package:fitness/pages/preference/userpreference_7.dart';

// Global instance of notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Top-level function for background notification handling
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle background notification tap
  debugPrint('Background notification tapped: ${notificationResponse.payload}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables FIRST
  await dotenv.load(fileName: ".env");

  // Then initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );

  // Initialize SharedPreferences
  _initializeSharedPreferences();

  // Initialize time zones for notifications
  tz.initializeTimeZones();

  // Initialize notifications
  await _initializeNotifications();

  // Request notification permissions
  await _requestNotificationPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistrationDataProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..fetchUserData()),
        ChangeNotifierProvider(create: (_) => MealsState()),
      ],
      child: const MyApp(),
    ),
  );
}

// Initialize SharedPreferences
Future<void> _initializeSharedPreferences() async {
  try {
    await SharedPreferences.getInstance();
    debugPrint("SharedPreferences initialized successfully");
  } catch (e) {
    debugPrint("SharedPreferences initialization failed: $e");
    // The app will use fallback storage instead
  }
}

// Initialize Notifications
Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // For iOS/macOS initialization
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      // Handle foreground notification tap
      debugPrint('Notification tapped: ${notificationResponse.payload}');
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
}

// Initialize Notification Settings
Future<void> _requestNotificationPermissions() async {
  if (Platform.isIOS || Platform.isMacOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>() // Changed from DarwinFlutterLocalNotificationsPlugin
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  } else if (Platform.isAndroid) {
    // For Android 13+ (API level 33), we need to request the POST_NOTIFICATIONS permission
    if (await _isAndroid13OrHigher()) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        debugPrint('Notification permission granted');
      } else {
        debugPrint('Notification permission denied');
      }
    }
    // For Android 12 and below, notifications work without explicit permission
  }
}

Future<bool> _isAndroid13OrHigher() async {
  if (Platform.isAndroid) {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33; // Android 13 = SDK version 33
    } catch (e) {
      debugPrint("Failed to get Android version: $e");
      return false;
    }
  }
  return false;
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',

  // routes of the pages

  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const StartupLogoPage(),
    ),
    GoRoute(
      path: '/startup',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: StartupPage(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: LoginPage(),
        key: state.pageKey,
      ),
    ),

    GoRoute(
      path: '/forgetpassword',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: ForgetpasswordPage(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference1',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: ChangeNotifierProvider(
          create: (context) => RegistrationDataProvider(),
          child: Userpreference1(),
        ),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference2',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: ChangeNotifierProvider(
          create: (context) => RegistrationDataProvider(),
          child: Userpreference2(),
        ),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference3',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: ChangeNotifierProvider(
          create: (context) => RegistrationDataProvider(),
          child: Userpreference3(),
        ),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference4',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: ChangeNotifierProvider(
          create: (context) => RegistrationDataProvider(),
          child: Userpreference4(),
        ),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference5',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: ChangeNotifierProvider(
          create: (context) => RegistrationDataProvider(),
          child: Userpreference5(),
        ),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference6',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: ChangeNotifierProvider(
          create: (context) => RegistrationDataProvider(),
          child: Userpreference6(),
        ),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference7',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: ChangeNotifierProvider(
          create: (context) => RegistrationDataProvider(),
          child: Userpreference7(),
        ),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: RegisterPage(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/feedback',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: SendFeedbackPage(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/food_page',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: FoodPage(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/adminonly',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: AdminPage(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/editfoodpreference',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: EditFoodPreferencePage(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/notificationsettings',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: NotificationSettings(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/recalcmacros',
      pageBuilder: (context, state) {
        final extraData = state.extra as Map<String, dynamic>?;
        final Map<String, dynamic> userData = extraData?['userData'] ?? {};
        final String selectedGoal =
            extraData?['selectedGoal'] ?? 'Maintain Weight';

        return FadeOutPageTransition(
          child: RecalculateMacrosPage(
            userData: userData,
            selectedGoal: selectedGoal,
          ),
          key: state.pageKey,
        );
      },
    ),
    GoRoute(
      path: '/camera',
      name: 'camera',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: CameraScreen(),
        key: state.pageKey,
      ),
    ),
    //shell route for main screen
    ShellRoute(builder: (context, state, child) => MainScreen(child: child), routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/chatbot',
        builder: (context, state) => const ChatBot(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => AnalyticsPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfilePage(),
      ),
      GoRoute(
        path: '/adminonly',
        builder: (context, state) => AdminPage(),
      ),
    ])

    //shell route for sidebar pages
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212)),
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
