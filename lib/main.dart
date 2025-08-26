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
import 'package:fitness/pages/sidebar_pages/send_feedback_page.dart';
import 'package:fitness/pages/sidebar_pages/recalculate_macros_page.dart';
import 'package:fitness/pages/sidebar_pages/edit_food_preference.dart';

// LOGIN PAGES
import 'package:fitness/pages/login/forgetpassword_page.dart';
import 'package:fitness/pages/login/startup_page.dart';
import 'package:fitness/pages/login/login_page.dart';
import 'package:fitness/pages/login/register_page.dart';

// MAIN PAGES
import 'package:fitness/pages/main_pages/analytics_page.dart';
import 'package:fitness/pages/main_pages/chat_bot.dart';
import 'package:fitness/pages/main_pages/admin_page.dart';
import 'package:fitness/pages/main_pages/home_page.dart';
import 'package:fitness/pages/main_pages/profile_page.dart';
import 'package:fitness/pages/main_pages/food_page.dart';

// FOOD PREFERENCE PAGES
import 'package:fitness/pages/preference/userpreference_2.dart';
import 'package:fitness/pages/preference/userpreference_1.dart';
import 'package:fitness/pages/preference/userpreference_3.dart';
import 'package:fitness/pages/preference/userpreference_4.dart';
import 'package:fitness/pages/preference/userpreference_5.dart';
import 'package:fitness/pages/preference/userpreference_6.dart';
import 'package:fitness/pages/preference/userpreference_7.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables FIRST
  await dotenv.load(fileName: ".env");

  // Then initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => MealsState(),
      child: const MyApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/startup',

  // routes of the pages
  routes: [
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
      path: '/register',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: RegisterPage(),
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
        child: Userpreference1(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference2',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: Userpreference2(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference3',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: Userpreference3(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference4',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: Userpreference4(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference5',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: Userpreference5(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference6',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: Userpreference6(),
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/preference7',
      pageBuilder: (context, state) => FadeOutPageTransition(
        child: Userpreference7(),
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
      path: '/recalcmacros',
      pageBuilder: (context, state) {
        // Safely cast state.extra to Map<String, dynamic>?
        final extraData = state.extra as Map<String, dynamic>?;

        // Extract parameters with null safety
        final Map<String, dynamic> userData = extraData?['userData'] ?? {};
        final String selectedGoal = extraData?['selectedGoal'] ?? 'Maintain Weight';

        return FadeOutPageTransition(
          child: RecalculateMacrosPage(
            userData: userData,
            selectedGoal: selectedGoal,
          ),
          key: state.pageKey,
        );
      },
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

const _authPaths = ['/startup', '/login', '/register'];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider()..fetchUserData(),
      child: MaterialApp.router(
        theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF121212))),
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}
